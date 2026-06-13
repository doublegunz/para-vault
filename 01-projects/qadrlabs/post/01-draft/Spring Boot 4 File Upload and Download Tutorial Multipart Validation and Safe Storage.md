# Spring Boot 4 File Upload and Download Tutorial: Multipart, Validation, and Safe Storage

In the previous tutorials, we built a [CRUD blog with Spring Boot 4](https://qadrlabs.com/post/spring-boot-4-crud-tutorial-build-a-simple-blog-step-by-step), wrote a [full test suite for it](https://qadrlabs.com/post/spring-boot-4-testing-tutorial-test-the-crud-blog-with-junit-5-mockito-and-mockmvc), and then [locked it down with Spring Security 7](https://qadrlabs.com/post/spring-boot-4-authentication-tutorial-add-login-and-registration-with-spring-security-7-and-jpa). The blog is now a real application: users log in, write posts, and nobody can vandalize it anonymously. There is just one capability missing that almost every blog needs eventually. Authors can only write text. They cannot attach a screenshot, a PDF, or a downloadable sample file.

Adding file upload sounds trivial. You grab a `MultipartFile`, call `transferTo(new File(file.getOriginalFilename()))`, and you are done. That one line is also one of the most dangerous things you can write in a web application. The filename comes straight from the user, so a crafted name like `../../etc/cron.d/evil` can write outside your folder. Two users uploading `photo.png` will silently overwrite each other. A 4GB upload will happily try to buffer itself into memory. And nothing stops someone from uploading an executable and tricking another user into running it.

This tutorial fixes all of that. We will add a proper Attachments feature to the secured blog: a page where logged-in users upload files, a list of everything stored, and a download endpoint that streams each file back under its original name. Along the way we will configure size limits, validate file types against a whitelist, sanitize filenames to block path traversal, organize files into dated folders with collision-proof names, and verify the whole thing with JUnit and MockMvc.

## Overview {#overview}

The feature is built from a small set of pieces that each have one job. A `StorageProperties` class holds the configured upload directory. A `FileStorageService` does every dangerous operation in one audited place: validation, sanitizing, and writing to disk. An `Attachment` JPA entity remembers the metadata so a download can serve the file under the name the user recognizes. An `AttachmentController` exposes the upload form and the download endpoint. Because the blog is already secured, every one of these URLs sits behind the login wall automatically, so we do not have to add a single line of security configuration.

### What You'll Build

- An upload page at `/files` with a multipart form, protected by the existing login wall.
- A table listing every stored file with its name, type, size, and a download button.
- A download endpoint at `/files/{id}/download` that streams the file with the correct `Content-Disposition` and `Content-Type` headers.
- Server-side validation that rejects empty files, oversized files, disallowed types, and path-traversal filenames with friendly messages.
- A storage layout on disk that uses dated subfolders and random filenames so uploads never collide or overwrite each other.

### What You'll Learn

- How to configure multipart limits with `spring.servlet.multipart.*` and why the container enforces them before your code runs.
- How to receive a `MultipartFile` and stream it to disk without buffering the whole thing in memory.
- How to validate file type with an allow-list and sanitize the filename to block path traversal.
- How to persist file metadata in JPA so the original name survives the trip to disk and back.
- How to serve a download with `ResponseEntity<Resource>`, `Content-Disposition: attachment`, and `X-Content-Type-Options: nosniff`.
- How to test multipart uploads and downloads with `MockMultipartFile` and MockMvc.

### What You'll Need

- The secured blog from the previous tutorials, fully running with a working login.
- Java 17 or higher (Java 21 recommended).
- Maven, a running MariaDB or MySQL database, and an IDE.
- Basic familiarity with controllers, services, and JPA entities from the earlier tutorials.

## Step 1: Configure Multipart Limits and the Storage Location {#step-1-configure-multipart-and-storage}

Before writing any Java, we tell Spring Boot two things: how big an upload may be, and where files should land on disk. Spring Boot embraces the servlet container's built-in multipart support, so there is nothing to install. By default it allows a generous limit, but leaving that at the default is a denial-of-service waiting to happen, because a single huge upload can exhaust disk or memory. We set an explicit cap instead.

Open `src/main/resources/application.properties` and add the following block under the existing JPA settings:

```properties
# Hard cap enforced by the servlet container. Anything bigger is rejected during
# request parsing with an HTTP 413 before our code ever runs. This is the outer
# safety net; the friendlier 5MB rule is enforced in the service layer.
spring.servlet.multipart.max-file-size=10MB
spring.servlet.multipart.max-request-size=10MB

# Where uploaded files are stored on disk, relative to the project root.
storage.location=uploads
```

Two of these properties are standard Spring Boot keys. The `max-file-size` limits a single uploaded file, and `max-request-size` limits the whole request, which matters when a form sends several files at once. Notice that we set the container cap to `10MB`, not the `5MB` we actually want to allow. That is deliberate. The container enforces its limit during request parsing, before any controller method runs, and when it trips it returns a blunt HTTP 413 that is awkward to turn into a nice message. By setting the container cap higher than our real limit, files between 5MB and 10MB still reach our code, where we can reject them with a clear, friendly error. The container cap remains as an outer safety net for anything truly enormous.

The third property, `storage.location`, is our own custom key. To read it in a type-safe way, create a small properties class at `src/main/java/com/qadrlabs/blog/config/StorageProperties.java`:

```java
package com.qadrlabs.blog.config;

import org.springframework.boot.context.properties.ConfigurationProperties;

@ConfigurationProperties(prefix = "storage")
public class StorageProperties {

    // The directory on disk where uploaded files are saved.
    // It is read from the "storage.location" property and defaults to "uploads".
    private String location = "uploads";

    public String getLocation() {
        return location;
    }

    public void setLocation(String location) {
        this.location = location;
    }
}
```

The `@ConfigurationProperties(prefix = "storage")` annotation binds every property that starts with `storage.` onto the matching field, so `storage.location` flows into `location`. Giving the field a default value of `"uploads"` means the application still works even if someone forgets to set the property. A typed properties class is nicer than scattering `@Value("${storage.location}")` annotations around the codebase, because the directory is defined in exactly one place and is easy to inject wherever it is needed.

For Spring to actually create and populate this bean, we have to enable it. Open the main application class at `src/main/java/com/qadrlabs/blog/BlogApplication.java` and add the `@EnableConfigurationProperties` annotation:

```java
package com.qadrlabs.blog;

import com.qadrlabs.blog.config.StorageProperties;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.context.properties.EnableConfigurationProperties;

@SpringBootApplication
@EnableConfigurationProperties(StorageProperties.class)
public class BlogApplication {

	public static void main(String[] args) {
		SpringApplication.run(BlogApplication.class, args);
	}

}
```

The `@EnableConfigurationProperties(StorageProperties.class)` line registers `StorageProperties` as a Spring bean and triggers the binding from `application.properties`. From now on, any constructor that asks for a `StorageProperties` will receive a fully populated instance.

## Step 2: Create the Attachment Entity and Repository {#step-2-create-attachment-entity-repository}

When a file goes to disk, we throw away its original name and give it a random one (more on why in the next step). That random name is useless to a human, so we need somewhere to remember the mapping between the friendly name the user uploaded and the actual file on disk. A database row is the natural home for that metadata, and it slots neatly into the same JPA pattern we already used for posts and users.

Create `src/main/java/com/qadrlabs/blog/model/Attachment.java`:

```java
package com.qadrlabs.blog.model;

import jakarta.persistence.*;
import org.hibernate.annotations.CreationTimestamp;

import java.time.LocalDateTime;

@Entity
@Table(name = "attachments")
public class Attachment {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    // The original filename the user uploaded, sanitized. We keep it so the
    // download endpoint can hand the file back under a name the user recognizes.
    @Column(nullable = false)
    private String originalName;

    // The relative path on disk where the file actually lives, for example
    // "2026/06/9f1c2e7a-...png". This is what we generate to avoid collisions
    // and to keep the original name from ever touching the filesystem path.
    @Column(nullable = false)
    private String storedName;

    // The MIME type reported by the browser, used to set Content-Type on download.
    @Column
    private String contentType;

    // The size in bytes, handy for display and for setting Content-Length.
    @Column(nullable = false)
    private long size;

    @CreationTimestamp
    @Column(updatable = false)
    private LocalDateTime createdAt;

    public Attachment() {
    }

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public String getOriginalName() { return originalName; }
    public void setOriginalName(String originalName) { this.originalName = originalName; }

    public String getStoredName() { return storedName; }
    public void setStoredName(String storedName) { this.storedName = storedName; }

    public String getContentType() { return contentType; }
    public void setContentType(String contentType) { this.contentType = contentType; }

    public long getSize() { return size; }
    public void setSize(long size) { this.size = size; }

    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }
}
```

The two fields that matter most are `originalName` and `storedName`, and the distinction between them is the heart of safe file storage. The `originalName` is what the user sees and downloads, like `invoice.pdf`. The `storedName` is the path we control, like `2026/06/87e6cb09-95fd-4e5b-8ba3-1192770b5231.pdf`. The user's name never becomes part of a real filesystem path, which is what makes path traversal impossible. We also keep `contentType` so the download can announce the right MIME type, and `size` for display and for setting `Content-Length`.

Now create the repository at `src/main/java/com/qadrlabs/blog/repository/AttachmentRepository.java`:

```java
package com.qadrlabs.blog.repository;

import com.qadrlabs.blog.model.Attachment;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface AttachmentRepository extends JpaRepository<Attachment, Long> {

    // Newest uploads first, derived automatically by Spring Data JPA from the method name.
    List<Attachment> findAllByOrderByCreatedAtDesc();
}
```

The single derived query method `findAllByOrderByCreatedAtDesc` gives us the file list sorted with the newest upload on top, and Spring Data JPA writes the SQL for us based on the method name. Everything else we need, like `save` and `findById`, comes for free from `JpaRepository`.

## Step 3: Build the File Storage Service {#step-3-build-the-file-storage-service}

This is the most important class in the tutorial. Every risky operation lives here and nowhere else, which means the security review of "can a user write outside our folder?" only has to look at this one file. We will build it in two parts: a small exception type, then the service itself.

First, create a single exception for storage failures at `src/main/java/com/qadrlabs/blog/service/StorageException.java`:

```java
package com.qadrlabs.blog.service;

// A single unchecked exception type for every storage failure: empty file,
// disallowed type, illegal path, or an I/O error while writing to disk.
// The controller catches this and turns the message into a flash error.
public class StorageException extends RuntimeException {

    public StorageException(String message) {
        super(message);
    }

    public StorageException(String message, Throwable cause) {
        super(message, cause);
    }
}
```

Using one unchecked exception type for all storage problems keeps the controller simple. It catches `StorageException` once and shows the message, instead of juggling a dozen different checked exceptions. The message is always something safe to show a user, never a raw stack trace.

Now the service itself. Create `src/main/java/com/qadrlabs/blog/service/FileStorageService.java`:

```java
package com.qadrlabs.blog.service;

import com.qadrlabs.blog.config.StorageProperties;
import com.qadrlabs.blog.model.Attachment;
import com.qadrlabs.blog.repository.AttachmentRepository;
import jakarta.annotation.PostConstruct;
import org.springframework.core.io.Resource;
import org.springframework.core.io.UrlResource;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.io.InputStream;
import java.net.MalformedURLException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.time.LocalDate;
import java.util.List;
import java.util.Set;
import java.util.UUID;

@Service
public class FileStorageService {

    // The whitelist of extensions we accept. Validating by a fixed allow-list is
    // safer than trying to block known-bad types, because the block-list is never
    // complete. Anything not on this list is rejected outright.
    private static final Set<String> ALLOWED_EXTENSIONS =
            Set.of("png", "jpg", "jpeg", "gif", "pdf", "txt");

    // Application-level size limit (5MB). The container cap in application.properties
    // is set higher (10MB) on purpose, so files between the two limits still reach
    // this method and get a friendly error instead of a raw 413 from the container.
    private static final long MAX_FILE_SIZE = 5L * 1024 * 1024;

    private final AttachmentRepository attachmentRepository;
    private final Path rootLocation;

    public FileStorageService(StorageProperties properties,
                              AttachmentRepository attachmentRepository) {
        this.attachmentRepository = attachmentRepository;
        // Resolve the configured directory to an absolute, normalized path once.
        // Every later path we build is checked against this root to block traversal.
        this.rootLocation = Paths.get(properties.getLocation())
                .toAbsolutePath()
                .normalize();
    }

    @PostConstruct
    public void init() {
        // Create the upload directory on startup so the first upload never fails
        // just because the folder does not exist yet.
        try {
            Files.createDirectories(rootLocation);
        } catch (IOException e) {
            throw new StorageException("Could not initialize storage directory", e);
        }
    }

    public Attachment store(MultipartFile file) {
        // 1. Reject empty submissions early. An empty part usually means the user
        //    clicked upload without choosing a file.
        if (file.isEmpty()) {
            throw new StorageException("Cannot store an empty file.");
        }

        // 1b. Enforce our own size limit with a clear message. The container would
        //     also reject anything above its hard cap, but that produces a blunt 413.
        if (file.getSize() > MAX_FILE_SIZE) {
            throw new StorageException("File is too large. The maximum allowed size is 5MB.");
        }

        // 2. Clean the original filename. StringUtils.cleanPath collapses things
        //    like "a/../b" and strips redundant separators, giving us a normalized
        //    string to inspect before we trust it.
        String originalName = StringUtils.cleanPath(
                file.getOriginalFilename() == null ? "" : file.getOriginalFilename());
        if (originalName.isBlank()) {
            throw new StorageException("The uploaded file has no name.");
        }

        // 3. Refuse any name that still contains a parent reference. Without this
        //    check, a crafted name like "../../etc/passwd" could escape the folder.
        if (originalName.contains("..")) {
            throw new StorageException(
                    "Filename contains an illegal path sequence: " + originalName);
        }

        // 4. Validate the extension against the whitelist.
        String extension = getExtension(originalName);
        if (!ALLOWED_EXTENSIONS.contains(extension)) {
            throw new StorageException(
                    "File type \"." + extension + "\" is not allowed.");
        }

        // 5. Build a dated subfolder (year/month) so a single directory never fills
        //    up with thousands of files, and generate a random stored name so two
        //    uploads with the same original name never overwrite each other.
        LocalDate today = LocalDate.now();
        String subFolder = String.format("%d/%02d", today.getYear(), today.getMonthValue());
        String storedName = UUID.randomUUID() + "." + extension;
        String relativePath = subFolder + "/" + storedName;

        // 6. Resolve the final destination and verify it still lives under the root.
        //    This is the last line of defense against path traversal.
        Path destination = rootLocation.resolve(relativePath).normalize();
        if (!destination.startsWith(rootLocation)) {
            throw new StorageException("Cannot store file outside the upload directory.");
        }

        // 7. Stream the bytes to disk. Using getInputStream() with Files.copy keeps
        //    memory usage flat instead of loading the whole file into a byte array.
        try {
            Files.createDirectories(destination.getParent());
            try (InputStream in = file.getInputStream()) {
                Files.copy(in, destination, StandardCopyOption.REPLACE_EXISTING);
            }
        } catch (IOException e) {
            throw new StorageException("Failed to store file " + originalName, e);
        }

        // 8. Persist the metadata so the download endpoint can find the file later
        //    and serve it under its original name.
        Attachment attachment = new Attachment();
        attachment.setOriginalName(originalName);
        attachment.setStoredName(relativePath);
        attachment.setContentType(file.getContentType());
        attachment.setSize(file.getSize());
        return attachmentRepository.save(attachment);
    }

    public Resource loadAsResource(Attachment attachment) {
        try {
            // Rebuild the absolute path from the stored relative path and verify,
            // once more, that it cannot point outside the upload root.
            Path file = rootLocation.resolve(attachment.getStoredName()).normalize();
            if (!file.startsWith(rootLocation)) {
                throw new StorageException("Cannot read file outside the upload directory.");
            }
            Resource resource = new UrlResource(file.toUri());
            if (resource.exists() && resource.isReadable()) {
                return resource;
            }
            throw new StorageException(
                    "Could not read file: " + attachment.getOriginalName());
        } catch (MalformedURLException e) {
            throw new StorageException(
                    "Could not read file: " + attachment.getOriginalName(), e);
        }
    }

    public List<Attachment> listAttachments() {
        return attachmentRepository.findAllByOrderByCreatedAtDesc();
    }

    public Attachment getAttachment(Long id) {
        return attachmentRepository.findById(id)
                .orElseThrow(() -> new StorageException("Attachment not found with id: " + id));
    }

    private String getExtension(String filename) {
        int dot = filename.lastIndexOf('.');
        if (dot < 0 || dot == filename.length() - 1) {
            return "";
        }
        return filename.substring(dot + 1).toLowerCase();
    }
}
```

There is a lot happening here, so let's walk through the `store` method in the order the checks run, because the order is part of the design.

The constructor resolves the configured directory once with `toAbsolutePath().normalize()` and keeps it in `rootLocation`. Every path we build later is checked against this root, so computing it correctly one time is what makes the traversal guards reliable. The `@PostConstruct init()` method then creates that directory on startup, so the very first upload never fails just because the folder did not exist.

Inside `store`, the cheap checks come first. We reject an empty file, then reject anything over our 5MB limit using `file.getSize()`. Doing the size check here, in addition to the container cap, is what gives users a readable "file is too large" message instead of a raw 413. Next we clean the filename with `StringUtils.cleanPath`, which normalizes the string, and then we reject any name that still contains `..`. The extension check uses the allow-list, so an upload named `malware.exe` is refused before a single byte touches the disk.

Only after every check passes do we build the destination. The dated subfolder, formatted as `year/month`, keeps any one directory from accumulating thousands of files, and the `UUID.randomUUID()` stored name guarantees two uploads of `photo.png` never collide. The final guard, `destination.startsWith(rootLocation)`, is belt-and-suspenders: even if a check above missed something, the resolved path must still live under the root or we refuse to write. We then stream the bytes with `Files.copy` over an `InputStream` so memory usage stays flat regardless of file size, and finally save the metadata row.

The `loadAsResource` method is the mirror image for downloads. It rebuilds the absolute path from the stored relative path, applies the same `startsWith` traversal guard, and wraps the file in a `UrlResource`. Returning a `Resource` rather than a `byte[]` lets Spring stream the file straight to the client without loading it all into memory.

## Step 4: Create the Attachment Controller {#step-4-create-the-attachment-controller}

With the service doing the heavy lifting, the controller is thin. It has three jobs: show the list page, accept an upload, and serve a download. Because the service throws a `StorageException` with a user-safe message on any problem, the controller's error handling is a single `catch` block that turns that message into a flash notification.

Create `src/main/java/com/qadrlabs/blog/controller/AttachmentController.java`:

```java
package com.qadrlabs.blog.controller;

import com.qadrlabs.blog.model.Attachment;
import com.qadrlabs.blog.service.FileStorageService;
import com.qadrlabs.blog.service.StorageException;
import org.springframework.core.io.Resource;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

@Controller
@RequestMapping("/files")
public class AttachmentController {

    private final FileStorageService storageService;

    public AttachmentController(FileStorageService storageService) {
        this.storageService = storageService;
    }

    @GetMapping
    public String index(Model model) {
        model.addAttribute("attachments", storageService.listAttachments());
        return "files/index";
    }

    @PostMapping
    public String upload(@RequestParam("file") MultipartFile file,
                         RedirectAttributes redirectAttributes) {
        // The service does all the validation and throws StorageException on any
        // problem. We translate that into a user-facing flash message instead of
        // letting a raw stack trace reach the browser.
        try {
            Attachment saved = storageService.store(file);
            redirectAttributes.addFlashAttribute("success",
                    "Uploaded \"" + saved.getOriginalName() + "\" successfully.");
        } catch (StorageException e) {
            redirectAttributes.addFlashAttribute("error", e.getMessage());
        }
        return "redirect:/files";
    }

    @GetMapping("/{id}/download")
    public ResponseEntity<Resource> download(@PathVariable Long id) {
        Attachment attachment = storageService.getAttachment(id);
        Resource resource = storageService.loadAsResource(attachment);

        // Fall back to a generic binary type if the browser never told us one.
        String contentType = attachment.getContentType() != null
                ? attachment.getContentType()
                : MediaType.APPLICATION_OCTET_STREAM_VALUE;

        // Content-Disposition: attachment forces a download dialog and supplies the
        // original filename. X-Content-Type-Options: nosniff stops the browser from
        // second-guessing our Content-Type, which blocks a class of XSS tricks.
        return ResponseEntity.ok()
                .contentType(MediaType.parseMediaType(contentType))
                .header(HttpHeaders.CONTENT_DISPOSITION,
                        "attachment; filename=\"" + attachment.getOriginalName() + "\"")
                .header("X-Content-Type-Options", "nosniff")
                .body(resource);
    }
}
```

The `upload` method receives the file as a `@RequestParam("file") MultipartFile`, where `"file"` matches the `name` attribute of the file input in our form. Spring populates this parameter from the multipart request automatically. We hand it to the service, and the only branching we do is success versus a `StorageException`. The method always ends with `redirect:/files`, following the Post/Redirect/Get pattern so a browser refresh does not re-submit the upload.

The `download` method is where the response headers earn their keep. We look up the metadata, get a streamable `Resource` from the service, and build a `ResponseEntity`. The `Content-Disposition: attachment; filename="..."` header is what makes the browser show a save dialog and remember the original filename rather than the UUID on disk. The `X-Content-Type-Options: nosniff` header tells the browser to trust our declared `Content-Type` and not try to guess, which closes off a class of attacks where a file is served as one type but interpreted as another. Returning `ResponseEntity<Resource>` lets Spring stream the file directly to the socket.

One thing we deliberately did not add here is an exception handler for oversized files. The reason is subtle and worth understanding, so we cover it in the security section after the steps. The short version: when an upload exceeds the container limit, the failure happens during request parsing, before this controller is ever selected, so a handler here would never see it. Our 5MB service check handles the friendly case, and the container's 10MB cap is the hard backstop.

## Step 5: Build the Upload and Download Page {#step-5-build-the-upload-and-download-page}

Now we give the feature a face. The page is a standalone Thymeleaf template with Tailwind from the CDN, matching the style of the posts pages from the earlier tutorials. It has an upload form at the top and a table of stored files below, each with a download button.

Create `src/main/resources/templates/files/index.html`:

```html
<!DOCTYPE html>
<html lang="en" xmlns:th="http://www.thymeleaf.org"
      xmlns:sec="https://www.thymeleaf.org/thymeleaf-extras-springsecurity6">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>File Attachments</title>
    <script src="https://cdn.tailwindcss.com"></script>
</head>
<body class="bg-gray-100 text-gray-800 font-sans p-6">
    <div class="max-w-5xl mx-auto bg-white p-6 md:p-8 rounded-lg shadow-md">
        <div class="flex justify-between items-center mb-6">
            <h1 class="text-3xl font-bold text-gray-900">File Attachments</h1>
            <div class="flex items-center space-x-4">
                <span class="text-sm text-gray-600">
                    Signed in as
                    <span class="font-semibold text-gray-900" sec:authentication="name">user</span>
                </span>
                <a th:href="@{/posts}" class="bg-gray-200 hover:bg-gray-300 text-gray-800 font-medium py-2 px-4 rounded-md transition duration-200">
                    Back to Posts
                </a>
                <form th:action="@{/logout}" method="post" class="inline">
                    <button type="submit" class="bg-gray-200 hover:bg-gray-300 text-gray-800 font-medium py-2 px-4 rounded-md transition duration-200">
                        Sign Out
                    </button>
                </form>
            </div>
        </div>

        <!-- Flash message shown after a successful upload -->
        <div th:if="${success}" class="bg-green-100 border border-green-400 text-green-700 px-4 py-3 rounded mb-6">
            <span th:text="${success}"></span>
        </div>

        <!-- Flash message shown when validation or size limits reject the upload -->
        <div th:if="${error}" class="bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded mb-6">
            <span th:text="${error}"></span>
        </div>

        <!-- The enctype is mandatory for file uploads; without it the browser sends
             only the filename, not the bytes. th:action injects the CSRF token. -->
        <form th:action="@{/files}" method="post" enctype="multipart/form-data"
              class="mb-8 flex items-center gap-3 bg-gray-50 border border-gray-200 rounded-lg p-4">
            <input type="file" name="file" required
                   class="block w-full text-sm text-gray-700 file:mr-4 file:py-2 file:px-4 file:rounded-md file:border-0 file:bg-blue-600 file:text-white hover:file:bg-blue-700 file:cursor-pointer">
            <button type="submit" class="bg-blue-600 hover:bg-blue-700 text-white font-semibold py-2 px-5 rounded-md transition duration-200 shadow-sm whitespace-nowrap">
                Upload
            </button>
        </form>

        <div class="overflow-x-auto">
            <table class="min-w-full bg-white border border-gray-200 shadow-sm rounded-lg overflow-hidden">
                <thead class="bg-gray-50 border-b border-gray-200">
                    <tr>
                        <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider w-16">No</th>
                        <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">File Name</th>
                        <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Type</th>
                        <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Size</th>
                        <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Actions</th>
                    </tr>
                </thead>
                <tbody class="divide-y divide-gray-200">
                    <tr th:each="file, iterStat : ${attachments}" class="hover:bg-gray-50 transition duration-150">
                        <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500 text-center" th:text="${iterStat.count}"></td>
                        <td class="px-6 py-4 text-sm font-medium text-gray-900" th:text="${file.originalName}"></td>
                        <td class="px-6 py-4 text-sm text-gray-500" th:text="${file.contentType}"></td>
                        <!-- Bytes to KB with one decimal place for a readable size -->
                        <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500"
                            th:text="${#numbers.formatDecimal(file.size / 1024.0, 1, 1) + ' KB'}"></td>
                        <td class="px-6 py-4 whitespace-nowrap text-sm font-medium">
                            <a th:href="@{/files/{id}/download(id=${file.id})}" class="inline-flex items-center px-3 py-1.5 bg-blue-600 rounded-md text-xs text-white uppercase hover:bg-blue-700 transition shadow-sm">Download</a>
                        </td>
                    </tr>
                    <tr th:if="${#lists.isEmpty(attachments)}">
                        <td colspan="5" class="px-6 py-4 text-center text-sm text-gray-500">No files uploaded yet.</td>
                    </tr>
                </tbody>
            </table>
        </div>
    </div>
    <div class="mt-8 mb-6 text-center text-sm text-gray-500">
        <a href="https://qadrlabs.com" class="text-blue-600 hover:text-blue-800 hover:underline transition" target="_blank">Tutorial Spring Boot File Upload at qadrlabs.com</a>
    </div>
</body>
</html>
```

The single most important attribute on this page is `enctype="multipart/form-data"` on the form. Without it, the browser sends only the filename as a plain text field, not the file's bytes, and `MultipartFile` arrives empty. The `name="file"` on the input must match the `@RequestParam("file")` in the controller. Because we used `th:action="@{/files}"` instead of a plain `action`, Thymeleaf's Spring Security integration injects the hidden CSRF token automatically, so the upload passes CSRF validation that the previous tutorial enabled.

The rest is presentation. The two `th:if` blocks render the success and error flash messages from the controller. The table loops over `attachments`, formats the size from bytes into kilobytes with `#numbers.formatDecimal`, and builds each download link with `@{/files/{id}/download(id=${file.id})}`. The `sec:authentication="name"` span shows the logged-in username, reusing the Security Extras dialect we set up for the posts page.

## Step 6: Try It Out {#step-6-try-it-out}

Everything is wired. Let's run the application and exercise it. Start the app:

```bash
./mvnw spring-boot:run
```

Open `http://localhost:8080/files` in your browser. Because the blog is secured, you will be bounced to the login page first. Sign in with the account you registered in the authentication tutorial, and you will land on the File Attachments page with an empty table that reads "No files uploaded yet."

### Upload a Valid File

Choose a small image or PDF and click "Upload". The page reloads with a green banner reading `Uploaded "your-file.png" successfully.`, and the file appears in the table with its type and size. Upload a couple more so the list has something in it. Behind the scenes, the files have landed on disk under a dated folder with random names. You can confirm this from the project root:

```bash
find uploads -type f
```

```
uploads/2026/06/87e6cb09-95fd-4e5b-8ba3-1192770b5231.pdf
uploads/2026/06/f489ee57-93c8-43b0-b637-c2086f6a6e0a.png
uploads/2026/06/f5d80efc-080e-45a8-9cd3-4f1f5669fc51.txt
```

Notice that none of the filenames on disk look anything like what the user uploaded. They are UUIDs grouped into a `2026/06` folder. The mapping back to the friendly names lives in the database. Open your MySQL client and look at the `attachments` table:

```sql
SELECT id, original_name, stored_name, content_type, size FROM attachments ORDER BY id;
```

```
id	original_name	stored_name	content_type	size
1	report.txt	2026/06/f5d80efc-080e-45a8-9cd3-4f1f5669fc51.txt	text/plain	42
2	avatar.png	2026/06/f489ee57-93c8-43b0-b637-c2086f6a6e0a.png	image/png	32
3	invoice.pdf	2026/06/87e6cb09-95fd-4e5b-8ba3-1192770b5231.pdf	application/pdf	35
```

This is exactly the separation we designed in Step 2. The `original_name` column holds what the user sees, and `stored_name` holds the path we control. The user's name never appears in a filesystem path.

### Download a File

Click the "Download" button next to any file. The browser saves it under its original name, not the UUID. If you want to see the actual response, you can inspect the headers with `curl` against the download URL while logged in:

```
HTTP/1.1 200 
Content-Disposition: attachment; filename="report.txt"
X-Content-Type-Options: nosniff
Content-Type: text/plain
Content-Length: 42
```

The `Content-Disposition` header carries the original filename back to the browser, `Content-Type` matches what we stored, and `X-Content-Type-Options: nosniff` is present exactly as we configured it.

### Try to Break It

Now confirm the validation actually works. First, try uploading a file larger than 5MB, such as a 6MB image. The page reloads with a red banner:

```
File is too large. The maximum allowed size is 5MB.
```

This is our service-level check talking, which produced a clean redirect rather than the blunt 413 the container would have returned for anything over 10MB. Next, rename a file to something with a disallowed extension like `notes.exe` and upload it. You get another red banner:

```
File type ".exe" is not allowed.
```

In both cases the file never touched the disk, because the validation runs before any write. That is the whole point of doing the checks in the service before `Files.copy`.

## Step 7: Test It with MockMvc and JUnit {#step-7-test-it-with-mockmvc-and-junit}

Manual testing is reassuring, but it does not protect us from a future change quietly breaking the validation. We need automated tests. We will write two test classes: a unit test for the storage service that exercises the validation rules and real disk writes, and a MockMvc test for the controller that checks the upload and download endpoints.

Start with the service test. It uses JUnit's `@TempDir` to write real files into a throwaway folder, so the tests never touch the project's actual `uploads` directory. Create `src/test/java/com/qadrlabs/blog/service/FileStorageServiceTest.java`:

```java
package com.qadrlabs.blog.service;

import com.qadrlabs.blog.config.StorageProperties;
import com.qadrlabs.blog.model.Attachment;
import com.qadrlabs.blog.repository.AttachmentRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.junit.jupiter.api.io.TempDir;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.core.io.Resource;
import org.springframework.mock.web.MockMultipartFile;

import java.nio.file.Files;
import java.nio.file.Path;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class FileStorageServiceTest {

    @Mock
    private AttachmentRepository attachmentRepository;

    private FileStorageService storageService;

    @BeforeEach
    void setUp(@TempDir Path tempDir) {
        // Point the service at a throwaway temp folder so the tests write real
        // files without touching the project's actual upload directory.
        StorageProperties properties = new StorageProperties();
        properties.setLocation(tempDir.toString());
        storageService = new FileStorageService(properties, attachmentRepository);
        storageService.init();
    }

    @Test
    void storeShouldSaveFileToDiskAndReturnMetadata() {
        // The repository just echoes back whatever it is asked to save.
        when(attachmentRepository.save(any(Attachment.class)))
                .thenAnswer(inv -> inv.getArgument(0));

        MockMultipartFile file = new MockMultipartFile(
                "file", "report.pdf", "application/pdf", "PDF-CONTENT".getBytes());

        Attachment saved = storageService.store(file);

        // Metadata is captured from the upload, but the stored name is generated.
        assertThat(saved.getOriginalName()).isEqualTo("report.pdf");
        assertThat(saved.getContentType()).isEqualTo("application/pdf");
        assertThat(saved.getSize()).isEqualTo("PDF-CONTENT".length());
        assertThat(saved.getStoredName()).endsWith(".pdf");
        assertThat(saved.getStoredName()).doesNotContain("report");
    }

    @Test
    void storeShouldRejectEmptyFile() {
        MockMultipartFile empty = new MockMultipartFile(
                "file", "empty.txt", "text/plain", new byte[0]);

        assertThatThrownBy(() -> storageService.store(empty))
                .isInstanceOf(StorageException.class)
                .hasMessageContaining("empty");
    }

    @Test
    void storeShouldRejectDisallowedExtension() {
        MockMultipartFile script = new MockMultipartFile(
                "file", "malware.exe", "application/octet-stream", "MZ".getBytes());

        assertThatThrownBy(() -> storageService.store(script))
                .isInstanceOf(StorageException.class)
                .hasMessageContaining("not allowed");
    }

    @Test
    void storeShouldRejectFileLargerThanLimit() {
        // 6MB of data, one megabyte over the 5MB service limit.
        byte[] big = new byte[6 * 1024 * 1024];
        MockMultipartFile oversized = new MockMultipartFile(
                "file", "huge.png", "image/png", big);

        assertThatThrownBy(() -> storageService.store(oversized))
                .isInstanceOf(StorageException.class)
                .hasMessageContaining("too large");
    }

    @Test
    void storeShouldRejectPathTraversalFilename() {
        // A crafted name that tries to climb out of the upload folder must be refused.
        MockMultipartFile evil = new MockMultipartFile(
                "file", "../../evil.txt", "text/plain", "data".getBytes());

        assertThatThrownBy(() -> storageService.store(evil))
                .isInstanceOf(StorageException.class)
                .hasMessageContaining("illegal path");
    }

    @Test
    void storeShouldGenerateUniqueStoredNamesForSameOriginalName() {
        when(attachmentRepository.save(any(Attachment.class)))
                .thenAnswer(inv -> inv.getArgument(0));

        MockMultipartFile first = new MockMultipartFile(
                "file", "photo.png", "image/png", "first".getBytes());
        MockMultipartFile second = new MockMultipartFile(
                "file", "photo.png", "image/png", "second".getBytes());

        Attachment a = storageService.store(first);
        Attachment b = storageService.store(second);

        // Same original name, but the random stored names must differ so the
        // second upload never overwrites the first.
        assertThat(a.getStoredName()).isNotEqualTo(b.getStoredName());
    }

    @Test
    void loadAsResourceShouldReturnReadableResource(@TempDir Path tempDir) throws Exception {
        when(attachmentRepository.save(any(Attachment.class)))
                .thenAnswer(inv -> inv.getArgument(0));

        MockMultipartFile file = new MockMultipartFile(
                "file", "notes.txt", "text/plain", "hello world".getBytes());
        Attachment saved = storageService.store(file);

        Resource resource = storageService.loadAsResource(saved);

        assertThat(resource.exists()).isTrue();
        assertThat(resource.isReadable()).isTrue();
        assertThat(Files.readString(resource.getFile().toPath())).isEqualTo("hello world");
    }
}
```

These seven tests cover the service end to end. The first proves that a valid upload lands on disk with generated metadata, and importantly that the stored name does not contain the original name. The next four prove every rejection rule fires: empty file, disallowed extension, oversized file, and a path-traversal filename. The sixth proves two identical names get distinct stored names, which is the collision protection. The last reads the file back through `loadAsResource` and confirms the bytes are intact. The `MockMultipartFile` class from Spring's test support lets us fabricate an upload in memory with any name, type, and content we want.

Now the controller test. It uses the same `@WebMvcTest` slice and `@MockitoBean` pattern as the `PostControllerTest` from the testing tutorial. Create `src/test/java/com/qadrlabs/blog/controller/AttachmentControllerTest.java`:

```java
package com.qadrlabs.blog.controller;

import com.qadrlabs.blog.model.Attachment;
import com.qadrlabs.blog.service.FileStorageService;
import com.qadrlabs.blog.service.StorageException;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest;
import org.springframework.core.io.ByteArrayResource;
import org.springframework.core.io.Resource;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

import java.util.List;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.multipart;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.flash;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.header;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.model;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.redirectedUrl;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.view;

@WebMvcTest(AttachmentController.class)
class AttachmentControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockitoBean
    private FileStorageService storageService;

    @Test
    void indexShouldListAttachments() throws Exception {
        Attachment attachment = new Attachment();
        attachment.setId(1L);
        attachment.setOriginalName("report.pdf");
        when(storageService.listAttachments()).thenReturn(List.of(attachment));

        mockMvc.perform(get("/files"))
                .andExpect(status().isOk())
                .andExpect(view().name("files/index"))
                .andExpect(model().attributeExists("attachments"));
    }

    @Test
    void uploadShouldStoreFileAndRedirectWithSuccess() throws Exception {
        Attachment saved = new Attachment();
        saved.setOriginalName("photo.png");
        when(storageService.store(any())).thenReturn(saved);

        var file = new org.springframework.mock.web.MockMultipartFile(
                "file", "photo.png", "image/png", "image-bytes".getBytes());

        mockMvc.perform(multipart("/files").file(file))
                .andExpect(status().is3xxRedirection())
                .andExpect(redirectedUrl("/files"))
                .andExpect(flash().attributeExists("success"));

        // The controller must delegate the actual storing to the service.
        verify(storageService).store(any());
    }

    @Test
    void uploadShouldRedirectWithErrorWhenStorageFails() throws Exception {
        when(storageService.store(any()))
                .thenThrow(new StorageException("File type \".exe\" is not allowed."));

        var file = new org.springframework.mock.web.MockMultipartFile(
                "file", "malware.exe", "application/octet-stream", "MZ".getBytes());

        mockMvc.perform(multipart("/files").file(file))
                .andExpect(status().is3xxRedirection())
                .andExpect(redirectedUrl("/files"))
                .andExpect(flash().attribute("error", "File type \".exe\" is not allowed."));
    }

    @Test
    void downloadShouldReturnFileWithContentDispositionHeader() throws Exception {
        Attachment attachment = new Attachment();
        attachment.setId(1L);
        attachment.setOriginalName("report.pdf");
        attachment.setContentType("application/pdf");
        attachment.setStoredName("2026/06/uuid.pdf");

        Resource resource = new ByteArrayResource("PDF-CONTENT".getBytes());
        when(storageService.getAttachment(1L)).thenReturn(attachment);
        when(storageService.loadAsResource(attachment)).thenReturn(resource);

        mockMvc.perform(get("/files/1/download"))
                .andExpect(status().isOk())
                .andExpect(header().string("Content-Disposition", "attachment; filename=\"report.pdf\""))
                .andExpect(content().bytes("PDF-CONTENT".getBytes()));
    }

    @Test
    void downloadShouldSetContentTypeAndNoSniffHeader() throws Exception {
        Attachment attachment = new Attachment();
        attachment.setId(2L);
        attachment.setOriginalName("notes.txt");
        attachment.setContentType("text/plain");
        attachment.setStoredName("2026/06/uuid.txt");

        when(storageService.getAttachment(2L)).thenReturn(attachment);
        when(storageService.loadAsResource(attachment))
                .thenReturn(new ByteArrayResource("hello".getBytes()));

        mockMvc.perform(get("/files/2/download"))
                .andExpect(status().isOk())
                .andExpect(content().contentType("text/plain"))
                .andExpect(header().string("X-Content-Type-Options", "nosniff"));
    }
}
```

The key new tool here is `multipart("/files")`, the MockMvc request builder for `multipart/form-data` requests, combined with `.file(file)` to attach a `MockMultipartFile`. The upload tests mock the service so the controller logic is tested in isolation: one proves a successful store produces a success flash and a redirect, and one proves a `StorageException` becomes an error flash. The two download tests use a `ByteArrayResource` as a stand-in for a real file and assert on the response headers and body, confirming the `Content-Disposition`, `Content-Type`, `X-Content-Type-Options`, and the actual bytes are correct.

Run the full suite:

```bash
./mvnw test
```

```
[INFO] Running com.qadrlabs.blog.service.PostServiceTest
[INFO] Tests run: 6, Failures: 0, Errors: 0, Skipped: 0, Time elapsed: 0.911 s -- in com.qadrlabs.blog.service.PostServiceTest
[INFO] Running com.qadrlabs.blog.service.FileStorageServiceTest
[INFO] Tests run: 7, Failures: 0, Errors: 0, Skipped: 0, Time elapsed: 0.124 s -- in com.qadrlabs.blog.service.FileStorageServiceTest
[INFO] Running com.qadrlabs.blog.controller.AttachmentControllerTest
[INFO] Tests run: 5, Failures: 0, Errors: 0, Skipped: 0, Time elapsed: 1.711 s -- in com.qadrlabs.blog.controller.AttachmentControllerTest
[INFO] Running com.qadrlabs.blog.controller.PostControllerTest
[INFO] Tests run: 10, Failures: 0, Errors: 0, Skipped: 0, Time elapsed: 0.465 s -- in com.qadrlabs.blog.controller.PostControllerTest
[INFO] Running com.qadrlabs.blog.repository.PostRepositoryTest
[INFO] Tests run: 3, Failures: 0, Errors: 0, Skipped: 0, Time elapsed: 1.869 s -- in com.qadrlabs.blog.repository.PostRepositoryTest
[INFO] Running com.qadrlabs.blog.BlogApplicationTests
[INFO] Tests run: 1, Failures: 0, Errors: 0, Skipped: 0, Time elapsed: 0.794 s -- in com.qadrlabs.blog.BlogApplicationTests
[INFO] Tests run: 32, Failures: 0, Errors: 0, Skipped: 0
[INFO] BUILD SUCCESS
```

All thirty-two tests pass: the twenty from the earlier tutorials plus the twelve new ones for the Attachments feature. The earlier tests still pass untouched, which confirms the new feature did not break anything in the existing blog.

## How Spring Handles a Multipart Request {#how-spring-handles-multipart}

Now that the feature works, it is worth understanding what Spring does between the browser clicking "Upload" and our `store` method running. This mental model explains why some things, like the size limit, behave the way they do.

When a browser submits a form with `enctype="multipart/form-data"`, it does not send the body as ordinary form parameters. Instead it splits the body into parts, each with its own headers, separated by a boundary string. One part holds the file bytes, another holds the CSRF token, and so on. A normal `application/x-www-form-urlencoded` body cannot carry raw binary, which is exactly why the `enctype` is mandatory.

On the server, Spring Boot relies on the servlet container's built-in multipart support rather than an external library. When a multipart request arrives, the `DispatcherServlet` asks a `MultipartResolver` to parse it. The default implementation, `StandardServletMultipartResolver`, hands the work to the container's own Part API, which is why Spring Boot's own documentation recommends using the container's support instead of adding a dependency like Apache Commons FileUpload. Once parsed, each file part is exposed to your controller as a `MultipartFile`, and Spring binds it to your `@RequestParam("file")` argument by matching the part name.

This parsing happens early, before Spring decides which controller method to call. That detail is the reason our oversized-file handling lives in the service and not in a controller exception handler. When an upload exceeds `spring.servlet.multipart.max-file-size`, the container rejects it while parsing the request, which is before any handler is selected. A method-level `@ExceptionHandler` on the controller never runs, because at that point there is no controller. That is why we set the container cap higher than our real limit and enforce the friendly 5MB rule with a plain `if` check inside `store`, where we are guaranteed to be running.

## Security Considerations for File Uploads {#security-considerations}

File upload is one of the most attacked surfaces in any web application, because it lets an untrusted user put bytes onto your server. Everything we built was shaped by a handful of concrete threats, and it is worth naming them explicitly so you can apply the same thinking to your own features.

The first threat is path traversal. The user controls the filename, and a name like `../../../etc/cron.d/job` could, with a naive implementation, write a file far outside your intended folder. We defend against this in three layers: we never use the original name as a path, we reject any name containing `..` after cleaning it, and we verify the final resolved path still starts with our root directory before writing. Any one of these would usually be enough; together they make traversal extremely unlikely.

The second threat is content confusion, where a file is uploaded as one type but the browser decides to treat it as another. An attacker could upload an `.html` file full of JavaScript and, if the browser sniffs it and renders it inline, run a cross-site scripting attack against whoever opens it. We blunt this with two headers on download: `Content-Disposition: attachment` tells the browser to save the file rather than render it, and `X-Content-Type-Options: nosniff` forbids the browser from second-guessing our declared `Content-Type`. We also validate the extension against an allow-list, which is stricter and more predictable than trying to maintain a block-list of bad types.

The third threat is resource exhaustion. Without a size limit, a single user can upload a file large enough to fill your disk or, with a careless implementation that buffers into memory, crash the process. We cap the size at two levels, container and service, and we stream the bytes to disk with `Files.copy` over an `InputStream` so a large file never sits in memory all at once.

One more habit worth internalizing: never trust what the browser tells you. The `getOriginalFilename()` and `getContentType()` values come from the client and can be anything an attacker wants. We use them only as hints, for display and as a fallback `Content-Type`, and we never let them decide where a file is written or whether it is accepted. The decisions that matter, the extension and the storage path, are made from values we control. For a high-security application you would go further and inspect the actual file content (the "magic bytes") to confirm a file claiming to be a PNG really is one, but the validation in this tutorial is a solid baseline for a typical blog.

## Conclusion {#conclusion}

In this tutorial we added a complete file upload and download feature to the secured Spring Boot 4 blog. We configured multipart limits, received uploads as `MultipartFile`, validated them against size, type, and path-traversal rules, stored them on disk with dated folders and collision-proof names, persisted their metadata in JPA, and served them back through a streaming download endpoint with the right headers. We then proved the whole thing works with a suite of service and MockMvc tests that all pass alongside the existing blog tests.

The key takeaways:

- **Set explicit multipart limits, and layer them.** A container cap via `spring.servlet.multipart.max-file-size` is the hard backstop, but it fails during request parsing with a blunt 413. Setting the container cap above your real limit and enforcing the real limit in the service gives users a friendly message while keeping the outer safety net.
- **Never let the user's filename become a path.** Store files under a random name you generate, keep the original name only as metadata in the database, and the entire class of path-traversal attacks disappears. Reinforce it by rejecting `..` and verifying the resolved path stays under your root.
- **Validate type with an allow-list, not a block-list.** A whitelist of permitted extensions is finite and predictable, while a list of banned types is never complete. Anything not explicitly allowed should be refused before a single byte is written.
- **Stream files instead of buffering them.** Reading uploads with `getInputStream()` into `Files.copy`, and returning downloads as a `Resource`, keeps memory usage flat no matter how large the file. Loading whole files into a `byte[]` is how upload features take down servers.
- **Set `Content-Disposition` and `X-Content-Type-Options` on every download.** The first carries the original filename and forces a save dialog; the second stops the browser from sniffing a different content type and opens the door to safer downloads.
- **Keep all the risky logic in one service.** Putting every validation and disk operation in `FileStorageService` means the security review has exactly one file to read, and the controller stays a thin translator between HTTP and the service.
- **Test uploads with `MockMultipartFile` and `multipart()`.** Spring's test support lets you fabricate uploads in memory and drive multipart requests through MockMvc, so the validation rules and the download headers are covered by fast, repeatable tests rather than manual clicking.

The Attachments feature stands on its own, but the obvious next step is to connect it to the blog itself, letting each post carry a featured image or a set of downloadable attachments through a JPA relationship. That, along with serving images inline instead of as downloads, is a natural follow-up once you are comfortable with the storage foundation we built here.
