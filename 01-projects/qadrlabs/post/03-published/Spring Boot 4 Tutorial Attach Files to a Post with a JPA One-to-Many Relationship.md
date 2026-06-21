# Spring Boot 4 Tutorial: Attach Files to a Post with a JPA One-to-Many Relationship

In the [file upload tutorial](https://qadrlabs.com/post/spring-boot-4-file-upload-and-download-tutorial-multipart-validation-and-safe-storage) we built a safe file storage feature, and in the [authorization tutorial](https://qadrlabs.com/post/spring-boot-4-authorization-tutorial-post-ownership-and-role-based-access-with-preauthorize) we made sure only a post's author or an admin can change it. But those two features still live in separate worlds. The uploaded files sit on a standalone `/files` page with no connection to any post, and a post is just text with no way to carry an image or a downloadable document. A reader looking at a blog post cannot see the screenshot that belongs to it, because the screenshot does not belong to it; it belongs to nothing.

That disconnect is the gap this tutorial closes. A real blog post owns its media: the diagram in the article, the sample PDF readers download, the cover image. Those files should be attached to the post, displayed on its page, and managed by the same person who owns the post. Right now none of that is possible, because there is no relationship between a file and a post in the database.

In this tutorial we will model that relationship as a JPA one-to-many: a post has many attachments, and each attachment optionally belongs to a post. We will let the post's owner upload files directly on the post page, preview images inline, download any file, and remove attachments, all gated by the ownership rules we already built. The standalone `/files` uploader keeps working untouched, because we make the new link optional rather than ripping out what already exists. This tutorial ties together the last three: storage, ownership, and now a real domain relationship.

## Overview {#overview}

The heart of this change is one foreign key. We add a nullable `post_id` column to the `attachments` table, expressed in JPA as a `@ManyToOne` on `Attachment` and a matching `@OneToMany` on `Post`. Making it nullable is a deliberate choice: files uploaded through the old `/files` page have no post, while files uploaded on a post's page point back to it, and both coexist happily. With the relationship in place, we extend the storage service to accept a post, add a delete that cleans up both the database row and the file on disk, and build a small controller scoped under `/posts/{postId}/attachments`. The upload and delete actions reuse the exact `@PreAuthorize` ownership rule from the authorization tutorial, so authorization comes almost for free.

### What You'll Build

- A one-to-many relationship so each post owns a list of attachments, while standalone files still work.
- An upload form on the post detail page, visible only to the post's author or an admin.
- An inline image preview for image attachments and a download link for every file.
- A delete button per attachment that removes both the database row and the file on disk, owner or admin only.
- Server-side authorization that returns 403 when anyone else tries to attach or delete files on a post.

### What You'll Learn

- How to model a JPA `@OneToMany` / `@ManyToOne` relationship and which side owns the foreign key.
- The difference between `cascade` and `orphanRemoval`, and what each does when a post is deleted.
- How to reuse an existing method-security rule (`@postSecurity.isOwner`) on a brand new controller.
- How to serve a file inline for previewing versus as an attachment for downloading, using `Content-Disposition`.
- How to test a secured, post-scoped file controller with `MockMultipartFile`, `@WithMockUser`, and CSRF.

### What You'll Need

- The blog from the file upload and authorization tutorials, fully running with login, ownership, and the `/files` feature.
- Java 17 or higher (Java 21 recommended).
- Maven, a running MariaDB or MySQL database, and an IDE.
- Familiarity with the `FileStorageService`, the `Attachment` entity, and the `@PreAuthorize` ownership rule from the previous two tutorials.

## Step 1: Establish a Baseline {#step-1-establish-a-baseline}

As always, start from a known-good state so any later breakage is obvious. Run the full suite:

```bash
./mvnw test
```

```
[INFO] Tests run: 37, Failures: 0, Errors: 0, Skipped: 0
[INFO] BUILD SUCCESS
```

Thirty-seven tests pass: the CRUD, testing, upload, and authorization work from the earlier tutorials. By the end of this one the suite will be larger, with new tests for the post-attachment relationship and its authorization, and every original test will still pass because our change is additive.

## Step 2: Model the One-to-Many Relationship {#step-2-model-the-one-to-many-relationship}

A post can have many attachments, and an attachment belongs to at most one post. That is a one-to-many relationship, and in JPA the "many" side owns the foreign key. So the `Attachment` entity gets a `@ManyToOne` reference to `Post`, which maps to a `post_id` column, and the `Post` entity gets a `@OneToMany` collection that mirrors it.

Open `src/main/java/com/qadrlabs/blog/model/Attachment.java`. The old entity ended its fields with the size and the creation timestamp:

```java
// The size in bytes, handy for display and for setting Content-Length.
@Column(nullable = false)
private long size;

@CreationTimestamp
```

Add the post relationship before the timestamp:

```java
// The size in bytes, handy for display and for setting Content-Length.
@Column(nullable = false)
private long size;

// The post this file is attached to. It is nullable on purpose: files uploaded
// through the standalone /files page have no post, while files uploaded on a
// post's page point back to it. LAZY so listing files never force-loads posts.
@ManyToOne(fetch = FetchType.LAZY)
@JoinColumn(name = "post_id")
private Post post;

@CreationTimestamp
```

Because there is no `nullable = false` on the `@JoinColumn`, the `post_id` column allows null, which is what lets standalone files keep existing. Add the getter and setter alongside the others:

```java
public Post getPost() { return post; }
public void setPost(Post post) { this.post = post; }
```

Now the inverse side. Open `src/main/java/com/qadrlabs/blog/model/Post.java` and add two imports for the collection:

```java
import java.util.ArrayList;
import java.util.List;
```

Then add the `attachments` collection right after the `author` field we introduced in the authorization tutorial:

```java
@ManyToOne(fetch = FetchType.LAZY, optional = false)
@JoinColumn(name = "author_id", nullable = false)
private User author;

// The files attached to this post. mappedBy points at the "post" field in
// Attachment, so Attachment owns the foreign key. orphanRemoval = true means
// removing an attachment from this list deletes its row; cascade = ALL means
// deleting a post deletes its attachment rows too.
@OneToMany(mappedBy = "post", cascade = CascadeType.ALL, orphanRemoval = true)
@OrderBy("createdAt ASC")
private List<Attachment> attachments = new ArrayList<>();
```

And the getter and setter:

```java
public List<Attachment> getAttachments() {
    return attachments;
}

public void setAttachments(List<Attachment> attachments) {
    this.attachments = attachments;
}
```

The `mappedBy = "post"` is the crucial detail. It tells JPA that the `Attachment.post` field, not this collection, owns the foreign key, so Hibernate does not try to create a second join column or a join table. The `@OrderBy("createdAt ASC")` returns attachments oldest first when we read the list. The `cascade` and `orphanRemoval` settings deserve a closer look, which we give them in the reference section after the steps. The short version: deleting a post will also delete its attachment rows.

## Step 3: Extend the Storage Service {#step-3-extend-the-storage-service}

The `FileStorageService` from the upload tutorial already knows how to validate and write a file. It just does not know about posts, and it cannot delete. We add both capabilities without disturbing the existing `/files` flow.

Open `src/main/java/com/qadrlabs/blog/service/FileStorageService.java` and add the `Post` import:

```java
import com.qadrlabs.blog.model.Post;
```

The old service had a single `store` method that took only the file:

```java
public Attachment store(MultipartFile file) {
    // 1. Reject empty submissions early. An empty part usually means the user
    //    clicked upload without choosing a file.
    if (file.isEmpty()) {
```

Split it into a post-aware version plus a one-line overload that preserves the old behavior. The old single-argument method now delegates with a null post:

```java
// The original single-argument method now delegates to the post-aware version
// with a null post, so the standalone /files uploader keeps working unchanged.
public Attachment store(MultipartFile file) {
    return store(file, null);
}

public Attachment store(MultipartFile file, Post post) {
    // 1. Reject empty submissions early. An empty part usually means the user
    //    clicked upload without choosing a file.
    if (file.isEmpty()) {
```

The rest of the validation and disk-writing logic stays exactly the same. The only other change inside the method is setting the post before saving. The old ending built the attachment without a post:

```java
Attachment attachment = new Attachment();
attachment.setOriginalName(originalName);
attachment.setStoredName(relativePath);
attachment.setContentType(file.getContentType());
attachment.setSize(file.getSize());
return attachmentRepository.save(attachment);
```

The new ending stamps the post, which is null for standalone uploads and a real post for post uploads:

```java
Attachment attachment = new Attachment();
attachment.setOriginalName(originalName);
attachment.setStoredName(relativePath);
attachment.setContentType(file.getContentType());
attachment.setSize(file.getSize());
// Link the file to its post when one was supplied; null means a standalone file.
attachment.setPost(post);
return attachmentRepository.save(attachment);
```

Now add a delete method. The upload tutorial never needed one, but per-post attachments do, and a correct delete has to clean up two things: the row in the database and the file on disk. Add this method to the service:

```java
public void deleteAttachment(Attachment attachment) {
    // Remove the file from disk first, then the metadata row. The same
    // startsWith guard used on write protects this delete from path traversal.
    try {
        Path file = rootLocation.resolve(attachment.getStoredName()).normalize();
        if (!file.startsWith(rootLocation)) {
            throw new StorageException("Cannot delete file outside the upload directory.");
        }
        Files.deleteIfExists(file);
    } catch (IOException e) {
        throw new StorageException("Failed to delete file " + attachment.getOriginalName(), e);
    }
    attachmentRepository.delete(attachment);
}
```

We reuse the same `startsWith(rootLocation)` traversal guard from the write path, because a delete that trusts a stored path blindly is just as dangerous as a write that does. `Files.deleteIfExists` does not complain if the file is already gone, which keeps the delete idempotent. We remove the file before the row so that, if the disk delete fails, the row stays and we can retry rather than losing track of an orphaned file.

## Step 4: Build the Post Attachment Controller {#step-4-build-the-post-attachment-controller}

The new endpoints belong under a post, so we give them their own controller scoped to `/posts/{postId}/attachments`. It has three jobs: accept an upload, serve a file inline for previewing, and delete an attachment. Upload and delete are owner-or-admin actions and reuse the exact `@PreAuthorize` expression from the authorization tutorial, just with `#postId` instead of `#id`.

Create `src/main/java/com/qadrlabs/blog/controller/PostAttachmentController.java`:

```java
package com.qadrlabs.blog.controller;

import com.qadrlabs.blog.model.Attachment;
import com.qadrlabs.blog.model.Post;
import com.qadrlabs.blog.service.FileStorageService;
import com.qadrlabs.blog.service.PostService;
import com.qadrlabs.blog.service.StorageException;
import org.springframework.core.io.Resource;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

@Controller
@RequestMapping("/posts/{postId}/attachments")
public class PostAttachmentController {

    private final FileStorageService storageService;
    private final PostService postService;

    public PostAttachmentController(FileStorageService storageService, PostService postService) {
        this.storageService = storageService;
        this.postService = postService;
    }

    // Only the post's author or an admin may attach files. #postId binds to the
    // path variable, exactly like the edit/update/delete rules on PostController.
    @PreAuthorize("hasRole('ADMIN') or @postSecurity.isOwner(#postId, authentication.name)")
    @PostMapping
    public String upload(@PathVariable Long postId,
                         @RequestParam("file") MultipartFile file,
                         RedirectAttributes redirectAttributes) {
        Post post = postService.getPostById(postId);
        try {
            Attachment saved = storageService.store(file, post);
            redirectAttributes.addFlashAttribute("success",
                    "Attached \"" + saved.getOriginalName() + "\" to the post.");
        } catch (StorageException e) {
            redirectAttributes.addFlashAttribute("error", e.getMessage());
        }
        return "redirect:/posts/" + postId;
    }

    // Serve the raw bytes inline so an <img> tag can preview an image. Viewing is
    // open to any authenticated user; only upload and delete are owner-gated.
    @GetMapping("/{id}")
    public ResponseEntity<Resource> view(@PathVariable Long postId, @PathVariable Long id) {
        Attachment attachment = storageService.getAttachment(id);
        Resource resource = storageService.loadAsResource(attachment);

        String contentType = attachment.getContentType() != null
                ? attachment.getContentType()
                : MediaType.APPLICATION_OCTET_STREAM_VALUE;

        // inline tells the browser to render the file in place rather than download it.
        return ResponseEntity.ok()
                .contentType(MediaType.parseMediaType(contentType))
                .header(HttpHeaders.CONTENT_DISPOSITION,
                        "inline; filename=\"" + attachment.getOriginalName() + "\"")
                .header("X-Content-Type-Options", "nosniff")
                .body(resource);
    }

    @PreAuthorize("hasRole('ADMIN') or @postSecurity.isOwner(#postId, authentication.name)")
    @PostMapping("/{id}/delete")
    public String delete(@PathVariable Long postId,
                         @PathVariable Long id,
                         RedirectAttributes redirectAttributes) {
        Attachment attachment = storageService.getAttachment(id);
        storageService.deleteAttachment(attachment);
        redirectAttributes.addFlashAttribute("success",
                "Removed \"" + attachment.getOriginalName() + "\" from the post.");
        return "redirect:/posts/" + postId;
    }
}
```

Three things are worth pointing out. The upload and delete methods carry the same `@PreAuthorize` rule as the post edit and delete handlers, only binding `#postId` because that is the path variable here; this is the payoff of having put the ownership logic in the reusable `postSecurity` bean. The `view` method has no `@PreAuthorize`, because viewing a file is not a privileged action; any logged-in user can preview an image, just as they can read the post. And the `view` method sets `Content-Disposition: inline` rather than `attachment`, which is the difference between the browser rendering the file in place and forcing a download. We do not add a separate download endpoint, because the `/files/{id}/download` route from the upload tutorial already serves any attachment as a download.

## Step 5: Show Attachments on the Post Page {#step-5-show-attachments-on-the-post-page}

With the backend in place, we surface attachments on the post detail page. The page should list every attachment, preview images inline, offer a download for each file, and show an upload form and per-file delete buttons only to the owner or an admin.

Open `src/main/resources/templates/posts/show.html`. It already declares the security namespace and computes a `canModify` flag in the header, from the authorization tutorial. Add a whole Attachments section between the post content and the footer line. The old template went straight from the content to the posted-date footer:

```html
<div class="prose max-w-none text-gray-800 leading-relaxed whitespace-pre-wrap" th:text="${post.content}"></div>

<div class="mt-10 pt-6 border-t border-gray-100 text-sm text-gray-500">
```

Insert the Attachments block in between:

```html
<div class="prose max-w-none text-gray-800 leading-relaxed whitespace-pre-wrap" th:text="${post.content}"></div>

<!-- Attachments. canModify mirrors the server rule: owner or admin. -->
<div class="mt-8 pt-6 border-t border-gray-100"
     th:with="canModify=${(post.author != null and post.author.username == #authentication.name) or #authorization.expression('hasRole(''ADMIN'')')}">
    <h2 class="text-lg font-semibold text-gray-900 mb-4">Attachments</h2>

    <!-- Flash messages from the upload/delete redirects -->
    <div th:if="${success}" class="bg-green-100 border border-green-400 text-green-700 px-4 py-2 rounded mb-4 text-sm">
        <span th:text="${success}"></span>
    </div>
    <div th:if="${error}" class="bg-red-100 border border-red-400 text-red-700 px-4 py-2 rounded mb-4 text-sm">
        <span th:text="${error}"></span>
    </div>

    <div th:if="${#lists.isEmpty(post.attachments)}" class="text-sm text-gray-500 mb-4">No attachments yet.</div>

    <ul class="space-y-3 mb-6">
        <li th:each="file : ${post.attachments}" class="flex items-center gap-4 border border-gray-200 rounded-md p-3">
            <!-- Inline image preview, served by the view endpoint with Content-Disposition: inline -->
            <img th:if="${file.contentType != null and #strings.startsWith(file.contentType, 'image/')}"
                 th:src="@{/posts/{postId}/attachments/{id}(postId=${post.id},id=${file.id})}"
                 alt="" class="w-16 h-16 object-cover rounded border border-gray-200">
            <div class="flex-1 min-w-0">
                <p class="text-sm font-medium text-gray-900 truncate" th:text="${file.originalName}"></p>
                <p class="text-xs text-gray-500" th:text="${file.contentType}"></p>
            </div>
            <!-- Download reuses the endpoint built in the file upload tutorial -->
            <a th:href="@{/files/{id}/download(id=${file.id})}"
               class="text-xs font-medium text-white bg-blue-600 hover:bg-blue-700 px-3 py-1.5 rounded-md transition">Download</a>
            <!-- Delete is a POST with a CSRF token, shown only to the owner or an admin -->
            <form th:if="${canModify}" th:action="@{/posts/{postId}/attachments/{id}/delete(postId=${post.id},id=${file.id})}"
                  method="post" onsubmit="return confirm('Remove this attachment?')" class="inline">
                <button type="submit" class="text-xs font-medium text-white bg-red-600 hover:bg-red-700 px-3 py-1.5 rounded-md transition">Delete</button>
            </form>
        </li>
    </ul>

    <!-- Upload form, shown only to the owner or an admin -->
    <form th:if="${canModify}" th:action="@{/posts/{postId}/attachments(postId=${post.id})}"
          method="post" enctype="multipart/form-data" class="flex items-center gap-3 bg-gray-50 border border-gray-200 rounded-lg p-3">
        <input type="file" name="file" required
               class="block w-full text-sm text-gray-700 file:mr-4 file:py-1.5 file:px-3 file:rounded-md file:border-0 file:bg-blue-600 file:text-white hover:file:bg-blue-700 file:cursor-pointer">
        <button type="submit" class="bg-blue-600 hover:bg-blue-700 text-white font-semibold py-1.5 px-4 rounded-md transition whitespace-nowrap">Attach</button>
    </form>

<div class="mt-10 pt-6 border-t border-gray-100 text-sm text-gray-500">
```

A few details make this work. The `th:with="canModify=..."` recomputes the owner-or-admin flag for this section, the same expression used in the header, so the upload form and delete buttons appear only for users allowed to use them. The image preview uses `#strings.startsWith(file.contentType, 'image/')` to decide whether to render an `<img>` pointing at our inline view endpoint, while every file gets a Download link to the `/files/{id}/download` route. The upload form carries `enctype="multipart/form-data"` so the bytes are actually sent, and because it uses `th:action`, Thymeleaf injects the CSRF token automatically. The delete control is a small POST form rather than a link, because a destructive action should never be a GET that a stray crawler could trigger.

## Step 6: Try It Out {#step-6-try-it-out}

Start the application:

```bash
./mvnw spring-boot:run
```

Log in, create a post, and open its detail page. Because you are the author, you will see the Attachments section with an empty list and an upload form. Upload an image and a PDF. Each upload redirects back to the post with a green confirmation, the image shows a thumbnail preview, and both files appear in the list. You can confirm the link in the database, where the new rows carry the post's id in `post_id`:

```sql
SELECT id, original_name, content_type, post_id FROM attachments;
```

```
id	original_name	content_type	post_id
4	pic.png	image/png	2
5	doc.pdf	application/pdf	2
```

Both files now belong to post 2. Files uploaded through the old standalone `/files` page would show a `NULL` in `post_id`, which is exactly why we made the column nullable: the two kinds of upload coexist.

Now look at the two ways a file is served. The inline view endpoint, which the `<img>` tag uses, returns the image to be rendered in place:

```
HTTP/1.1 200 
Content-Disposition: inline; filename="pic.png"
X-Content-Type-Options: nosniff
Content-Type: image/png
```

The download endpoint from the upload tutorial returns the same kind of file but tells the browser to save it:

```
HTTP/1.1 200 
Content-Disposition: attachment; filename="doc.pdf"
Content-Type: application/pdf
```

The only meaningful difference is `inline` versus `attachment` in the `Content-Disposition` header, and that single word decides whether the browser previews or downloads.

Next, verify authorization. Log in as a different user who does not own the post and try to attach or delete a file by posting to the endpoints directly. Both are refused:

```
bob attach -> 403
bob delete -> 403
```

The `@PreAuthorize` rule stops them before the controller body runs, and they see the same friendly 403 page from the authorization tutorial. Finally, as the owner, delete one of the attachments. The action removes both the row and the file on disk:

```
disk file before: uploads/2026/06/dffd9a82-1784-47fc-adff-4902951b2c2c.pdf
EXISTS
alice delete 5 -> 302
row 5 after: 0
disk file after: missing
```

The row count for that attachment drops to zero and the file is gone from disk, which is the `deleteAttachment` method doing both halves of the cleanup.

## Step 7: Update the Test Suite {#step-7-update-the-test-suite}

We added behavior, so we add tests, and we keep the existing ones green. The storage service gained two abilities, and the new controller needs its own secured test. The standalone `/files` tests are untouched because the original `store(MultipartFile)` overload still behaves exactly as before.

First, two new cases in `FileStorageServiceTest.java`. Add the `Post` import and the `verify` static import, then append these tests:

```java
@Test
void storeShouldAttachToPostWhenProvided() {
    when(attachmentRepository.save(any(Attachment.class)))
            .thenAnswer(inv -> inv.getArgument(0));

    Post post = new Post();
    post.setId(7L);
    MockMultipartFile file = new MockMultipartFile(
            "file", "diagram.png", "image/png", "image".getBytes());

    Attachment saved = storageService.store(file, post);

    // The post-aware overload must link the attachment back to its post.
    assertThat(saved.getPost()).isEqualTo(post);
}

@Test
void deleteAttachmentShouldRemoveFileFromDiskAndRow() throws Exception {
    when(attachmentRepository.save(any(Attachment.class)))
            .thenAnswer(inv -> inv.getArgument(0));

    MockMultipartFile file = new MockMultipartFile(
            "file", "report.txt", "text/plain", "data".getBytes());
    Attachment saved = storageService.store(file);

    // Resolve the actual path through the service so we assert against the
    // same root directory it used to write the file.
    Path onDisk = storageService.loadAsResource(saved).getFile().toPath();
    assertThat(Files.exists(onDisk)).isTrue();

    storageService.deleteAttachment(saved);

    assertThat(Files.exists(onDisk)).isFalse();
    verify(attachmentRepository).delete(saved);
}
```

The first proves the post-aware overload links the attachment to its post. The second writes a real file into the test's temporary directory, deletes it through the service, and asserts both that the file vanished from disk and that the repository row was deleted.

Now the controller test. It uses the same secured-slice recipe as `PostControllerTest`: import `SecurityConfig` to activate method security, include `HomeController` so the `/403` forward resolves, build MockMvc with `springSecurity()`, and register the `postSecurity` mock under its exact bean name. Create `src/test/java/com/qadrlabs/blog/controller/PostAttachmentControllerTest.java`:

```java
@WebMvcTest({PostAttachmentController.class, HomeController.class})
@Import(SecurityConfig.class)
class PostAttachmentControllerTest {

    @Autowired
    private WebApplicationContext context;

    private MockMvc mockMvc;

    @BeforeEach
    void setUp() {
        mockMvc = MockMvcBuilders.webAppContextSetup(context)
                .apply(springSecurity())
                .build();
    }

    @MockitoBean
    private FileStorageService storageService;

    @MockitoBean
    private PostService postService;

    @MockitoBean(name = "postSecurity")
    private PostSecurity postSecurity;

    @Test
    @WithMockUser(username = "alice")
    void ownerCanUploadAttachment() throws Exception {
        when(postSecurity.isOwner(1L, "alice")).thenReturn(true);
        when(postService.getPostById(1L)).thenReturn(new Post());
        Attachment saved = new Attachment();
        saved.setOriginalName("diagram.png");
        when(storageService.store(any(), any(Post.class))).thenReturn(saved);

        MockMultipartFile file = new MockMultipartFile(
                "file", "diagram.png", "image/png", "image".getBytes());

        mockMvc.perform(multipart("/posts/1/attachments").file(file).with(csrf()))
                .andExpect(status().is3xxRedirection())
                .andExpect(redirectedUrl("/posts/1"));

        verify(storageService).store(any(), any(Post.class));
    }

    @Test
    @WithMockUser(username = "bob")
    void nonOwnerCannotUploadAttachment() throws Exception {
        when(postSecurity.isOwner(1L, "bob")).thenReturn(false);

        MockMultipartFile file = new MockMultipartFile(
                "file", "diagram.png", "image/png", "image".getBytes());

        mockMvc.perform(multipart("/posts/1/attachments").file(file).with(csrf()))
                .andExpect(status().isForbidden());

        verify(storageService, never()).store(any(), any(Post.class));
    }

    @Test
    @WithMockUser(username = "alice")
    void ownerCanDeleteAttachment() throws Exception {
        when(postSecurity.isOwner(1L, "alice")).thenReturn(true);
        Attachment attachment = new Attachment();
        attachment.setOriginalName("diagram.png");
        when(storageService.getAttachment(5L)).thenReturn(attachment);

        mockMvc.perform(post("/posts/1/attachments/5/delete").with(csrf()))
                .andExpect(status().is3xxRedirection())
                .andExpect(redirectedUrl("/posts/1"));

        verify(storageService).deleteAttachment(attachment);
    }

    @Test
    @WithMockUser(username = "bob")
    void nonOwnerCannotDeleteAttachment() throws Exception {
        when(postSecurity.isOwner(1L, "bob")).thenReturn(false);

        mockMvc.perform(post("/posts/1/attachments/5/delete").with(csrf()))
                .andExpect(status().isForbidden());

        verify(storageService, never()).deleteAttachment(any());
    }

    @Test
    @WithMockUser(username = "carol")
    void viewServesImageInline() throws Exception {
        Attachment attachment = new Attachment();
        attachment.setOriginalName("diagram.png");
        attachment.setContentType("image/png");
        attachment.setStoredName("2026/06/uuid.png");
        when(storageService.getAttachment(5L)).thenReturn(attachment);
        when(storageService.loadAsResource(attachment))
                .thenReturn(new ByteArrayResource("PNG-BYTES".getBytes()));

        mockMvc.perform(get("/posts/1/attachments/5"))
                .andExpect(status().isOk())
                .andExpect(content().contentType("image/png"))
                .andExpect(header().string("Content-Disposition", "inline; filename=\"diagram.png\""))
                .andExpect(content().bytes("PNG-BYTES".getBytes()));
    }
}
```

These five tests cover the whole controller. The owner can upload and delete; the non-owner is forbidden on both, with the service never touched; and the inline view returns the right bytes, content type, and `Content-Disposition: inline`. The owner and non-owner cases differ only in what `postSecurity.isOwner(...)` is stubbed to return, which is exactly the seam the `@PreAuthorize` rule depends on.

Run the whole suite:

```bash
./mvnw test
```

```
[INFO] Running com.qadrlabs.blog.service.PostServiceTest
[INFO] Tests run: 6, Failures: 0, Errors: 0, Skipped: 0, Time elapsed: 0.934 s -- in com.qadrlabs.blog.service.PostServiceTest
[INFO] Running com.qadrlabs.blog.service.FileStorageServiceTest
[INFO] Tests run: 9, Failures: 0, Errors: 0, Skipped: 0, Time elapsed: 0.154 s -- in com.qadrlabs.blog.service.FileStorageServiceTest
[INFO] Running com.qadrlabs.blog.security.PostSecurityTest
[INFO] Tests run: 4, Failures: 0, Errors: 0, Skipped: 0, Time elapsed: 0.020 s -- in com.qadrlabs.blog.security.PostSecurityTest
[INFO] Running com.qadrlabs.blog.controller.AttachmentControllerTest
[INFO] Tests run: 5, Failures: 0, Errors: 0, Skipped: 0, Time elapsed: 1.910 s -- in com.qadrlabs.blog.controller.AttachmentControllerTest
[INFO] Running com.qadrlabs.blog.controller.PostAttachmentControllerTest
[INFO] Tests run: 5, Failures: 0, Errors: 0, Skipped: 0, Time elapsed: 0.921 s -- in com.qadrlabs.blog.controller.PostAttachmentControllerTest
[INFO] Running com.qadrlabs.blog.controller.PostControllerTest
[INFO] Tests run: 11, Failures: 0, Errors: 0, Skipped: 0, Time elapsed: 0.817 s -- in com.qadrlabs.blog.controller.PostControllerTest
[INFO] Running com.qadrlabs.blog.repository.PostRepositoryTest
[INFO] Tests run: 3, Failures: 0, Errors: 0, Skipped: 0, Time elapsed: 2.095 s -- in com.qadrlabs.blog.repository.PostRepositoryTest
[INFO] Running com.qadrlabs.blog.BlogApplicationTests
[INFO] Tests run: 1, Failures: 0, Errors: 0, Skipped: 0, Time elapsed: 0.923 s -- in com.qadrlabs.blog.BlogApplicationTests
[INFO] Tests run: 44, Failures: 0, Errors: 0, Skipped: 0
[INFO] BUILD SUCCESS
```

Forty-four tests pass, up from thirty-seven. We added two storage-service tests and five controller tests, and every test from the previous tutorials still passes, including the standalone `AttachmentControllerTest` for `/files`, which proves the additive overload did not change the old behavior.

## How the One-to-Many Maps to the Schema {#how-the-one-to-many-maps-to-the-schema}

Now that it works, it is worth understanding what JPA actually did with our two annotations, because the mapping has a few sharp edges. A one-to-many relationship in a relational database is a single foreign key on the "many" table. There is no second column on the "one" side; the `posts` table has no attachment columns at all. Our `Attachment.post` field, with its `@JoinColumn(name = "post_id")`, is what creates that foreign key, which makes `Attachment` the owning side of the relationship.

The `@OneToMany(mappedBy = "post")` on `Post` is the inverse, non-owning side. The word `mappedBy` tells Hibernate "the foreign key for this relationship is managed by the `post` field over in `Attachment`, so do not invent your own column or join table." Forgetting `mappedBy` is the classic one-to-many mistake; without it, Hibernate assumes each side owns its own mapping and creates an extra join table you never wanted.

The `cascade` and `orphanRemoval` settings control what happens to attachments when their post changes. With `cascade = CascadeType.ALL`, persisting or deleting a post cascades to its attachments, so deleting a post deletes its attachment rows in the same transaction. With `orphanRemoval = true`, removing an attachment from the in-memory `post.getAttachments()` list also deletes its row, because an attachment with no parent post is considered an orphan. There is one honest limitation to flag: these settings clean up database rows, not files on disk. Deleting a post will remove its attachment rows but leave the actual files in the upload folder. Our per-attachment delete handles the disk, so for a complete cleanup you would also iterate the attachments and call `deleteAttachment` inside `PostService.deletePost`. We kept that out of scope here to stay focused, but it is the natural next hardening step.

Finally, the `fetch = FetchType.LAZY` on both sides means neither the post nor its attachments are loaded until you actually touch them. The reason the template can still render `post.getAttachments()` is the `spring.jpa.open-in-view` setting, enabled by default, which keeps the persistence session open during view rendering. That is convenient for a server-rendered app like this one, though in a REST API you would typically fetch the attachments explicitly to avoid lazy-loading surprises.

## Serving Files Inline vs as a Download {#serving-files-inline-vs-as-a-download}

This tutorial serves the same files two different ways, and the distinction is entirely in one HTTP header. The `Content-Disposition` header tells the browser what to do with a response body. When it says `inline`, the browser tries to render the content in the current page, which is exactly what we want for the `<img>` preview. When it says `attachment`, the browser opens a save dialog and downloads the file instead of displaying it, which is what we want for a "Download" button.

Our inline view endpoint sets `Content-Disposition: inline` along with the file's real content type, so an image renders and a PDF would open in the browser's viewer. The download endpoint from the upload tutorial sets `Content-Disposition: attachment`, so the same bytes are saved to disk instead. Both endpoints also send `X-Content-Type-Options: nosniff`, which forbids the browser from second-guessing the declared content type, an important safety measure when you are serving user-uploaded files. The practical rule of thumb is simple: use `inline` for things you want previewed, like images shown on a page, and `attachment` for things you want downloaded, like documents and archives.

## Conclusion {#conclusion}

In this tutorial we connected files to posts. We modeled a JPA one-to-many relationship with a nullable foreign key so post attachments and standalone files coexist, extended the storage service to link a file to a post and to delete both the row and the disk file, built a post-scoped controller that reuses the ownership rule from the authorization tutorial, and rendered attachments on the post page with inline image previews, downloads, and owner-only management. The full suite grew from thirty-seven to forty-four passing tests.

The key takeaways:

- **The "many" side owns the foreign key.** `Attachment` carries `@ManyToOne` and the `post_id` column, while `Post` uses `@OneToMany(mappedBy = "post")` as the inverse side. The `mappedBy` is what stops Hibernate from creating an unwanted join table.
- **A nullable foreign key keeps the change additive.** Because `post_id` allows null, the standalone `/files` uploader and its tests keep working unchanged, while post uploads set the link. New features should extend, not break, what already exists.
- **`cascade` and `orphanRemoval` manage rows, not files.** Deleting a post deletes its attachment rows, but the files on disk need explicit cleanup, which the per-attachment delete provides and a full implementation would extend to post deletion.
- **Authorization rules are reusable across controllers.** The new upload and delete endpoints carry the same `@PreAuthorize("hasRole('ADMIN') or @postSecurity.isOwner(#postId, authentication.name)")` as the post editing actions, which is the dividend of having put ownership logic in a dedicated bean.
- **`Content-Disposition` decides preview versus download.** `inline` renders a file in place for image previews; `attachment` forces a save dialog. The same bytes serve both purposes depending on a single header.
- **Additive changes should leave the old tests green.** Keeping the original `store(MultipartFile)` overload meant the upload tutorial's tests never changed, and the suite proves the new relationship and authorization without regressing anything.

The blog now has authored posts that own their images and downloads, all managed by the right people. A natural next step is to clean up orphaned files when a post is deleted, or to add image thumbnailing so large uploads are resized for the inline preview instead of being served at full size.
