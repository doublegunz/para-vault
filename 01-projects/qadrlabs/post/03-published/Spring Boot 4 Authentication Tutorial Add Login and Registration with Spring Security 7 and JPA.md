In the previous tutorials, we built a [CRUD blog with Spring Boot 4](https://qadrlabs.com/post/spring-boot-4-crud-tutorial-build-a-simple-blog-step-by-step) and then wrote a [complete test suite for it using JUnit 5, Mockito, and MockMvc](https://qadrlabs.com/post/spring-boot-4-testing-tutorial-test-the-crud-blog-with-junit-5-mockito-and-mockmvc). The application works, the tests pass, and everything looks polished. There is just one problem: anyone who knows the URL can visit `/posts`, click "Create New Post", and start writing. There is no concept of who owns the data, no way to stop a bot from spamming hundreds of posts, and no audit trail for who deleted what.

This is not a missing feature. It is the reason production applications never ship without authentication. Without a login wall, a public-facing blog is a vandalism magnet. Without password hashing, even the people who do log in are exposed to data breaches. Without proper session management, attackers can hijack user accounts with stolen cookies. These are not theoretical risks; they are the default state of any web app that lacks Spring Security.

The good news is that Spring Boot 4 ships with Spring Security 7, which makes building a robust login and registration flow surprisingly approachable. In this tutorial, we will add a user table to the database, implement a custom `UserDetailsService` that reads from JPA, configure Spring Security using the modern Lambda DSL, and build registration and login pages with Thymeleaf. By the end, every URL under `/posts` will require authentication, and we will have a working sign-up flow with BCrypt password hashing.

## Overview {#overview}

The three new components we are about to build form a chain that connects our database to Spring Security. The `User` entity stores the credentials in the database, just like any other JPA entity. The `CustomUserDetailsService` is a bridge that translates our `User` into a format Spring Security understands. The `SecurityConfig` configures the entire authentication pipeline using Spring Security 7's Lambda DSL. Once those three pieces are in place, Spring Security takes over the authentication flow automatically, and the rest of the tutorial is just building the registration form and login page.

### What You'll Build

- A registration page at `/register` with form validation, unique username checks, and password confirmation.
- A custom login page at `/login` with error messages, logout confirmation, and a link back to the registration page.
- A logout button in the navbar that ends the session and redirects back to the login page.
- Protection on every URL under `/posts`, redirecting unauthenticated users to the login page.
- A navbar greeting that shows the username of the currently logged-in user.

### What You'll Learn

- How to configure Spring Security 7 using the required Lambda DSL.
- How to implement `UserDetailsService` so Spring Security can read users from a JPA repository.
- How to hash passwords with `BCryptPasswordEncoder` and why hashing is non-negotiable.
- How CSRF protection works in Spring Security and how Thymeleaf integrates with it automatically.
- How to use a separate DTO for form binding so that fields like `confirmPassword` never reach the database.
- How to display authenticated user information in Thymeleaf using the Security Extras dialect.

### What You'll Need

- The CRUD blog and its test suite from the previous tutorials, fully running.
- Java 17 or higher (Java 21 recommended).
- Maven, a working MySQL database, and an IDE.
- Basic familiarity with form binding and validation from the CRUD tutorial.

## Step 1: Add Spring Security Dependencies {#step-1-add-security-dependencies}

Before we configure anything, we need to put Spring Security on the classpath. The moment Spring Security appears in the dependencies, Spring Boot's auto-configuration kicks in and starts protecting every endpoint by default. This is a deliberate "secure by default" policy: it forces you to think about who can access what before deploying, instead of finding out later that you forgot to protect a sensitive URL.

Open `pom.xml` and add two dependencies. The first one is the security starter itself. The second one is the Thymeleaf integration that lets us read authentication state from inside our templates.

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-security</artifactId>
</dependency>
<dependency>
    <groupId>org.thymeleaf.extras</groupId>
    <artifactId>thymeleaf-extras-springsecurity6</artifactId>
</dependency>
```

The artifact name `thymeleaf-extras-springsecurity6` is correct even though we are on Spring Security 7. The artifact has not been renamed yet; it continues to work fine across Security 6 and 7.

Now, before we write any configuration, let's see what Spring Security looks like out of the box. Run the application:

```bash
./mvnw spring-boot:run
```

Watch the console carefully during startup. You will see a line that looks like this:

```
Using generated security password: 8a3f2c1e-4b9d-4e7a-9f12-7a6b5c8d4e2f

This generated password is for development use only. Your security configuration must be updated before running your application in production.
```

That is Spring Boot telling you it has auto-configured a single user called `user` with a randomly generated password. Open `http://localhost:8080/posts` in your browser. Instead of the blog listing, you should see Spring Security's default login form. You can sign in with username `user` and the password from the console, but that is obviously not what we want for a real application. The default login exists so that protection is on from the very first second, even before you write any code.

Stop the server with Ctrl+C. We are about to replace that default with something useful.

## Step 2: Create the User Entity and Repository {#step-2-create-user-entity-repository}

Spring Security does not care where your user data comes from. It only requires that you provide a way to look up users by username and check their passwords. The cleanest approach is to store users in our existing MySQL database, alongside the posts, using exactly the same JPA patterns we already used for the `Post` entity.

Create the file `src/main/java/com/qadrlabs/blog/model/User.java`:

```java
package com.qadrlabs.blog.model;

import jakarta.persistence.*;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.LocalDateTime;

@Entity
@Table(name = "users")
public class User {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @NotBlank(message = "Username is required")
    @Size(min = 3, max = 50, message = "Username must be between 3 and 50 characters")
    @Column(nullable = false, unique = true)
    private String username;

    @NotBlank(message = "Email is required")
    @Email(message = "Email must be a valid address")
    @Column(nullable = false, unique = true)
    private String email;

    // Password is stored as a BCrypt hash, never as plain text.
    // The encoded hash is typically 60 characters long, so we leave room.
    @NotBlank(message = "Password is required")
    @Column(nullable = false)
    private String password;

    // Role is stored as a plain string like "ROLE_USER" so that
    // Spring Security can convert it into a GrantedAuthority directly.
    @Column(nullable = false)
    private String role = "ROLE_USER";

    @CreationTimestamp
    @Column(updatable = false)
    private LocalDateTime createdAt;

    @UpdateTimestamp
    private LocalDateTime updatedAt;

    // Default constructor required by JPA
    public User() {
    }

    // Getters and Setters
    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public String getUsername() { return username; }
    public void setUsername(String username) { this.username = username; }

    public String getEmail() { return email; }
    public void setEmail(String email) { this.email = email; }

    public String getPassword() { return password; }
    public void setPassword(String password) { this.password = password; }

    public String getRole() { return role; }
    public void setRole(String role) { this.role = role; }

    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }

    public LocalDateTime getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(LocalDateTime updatedAt) { this.updatedAt = updatedAt; }
}
```

There are two design decisions worth pausing on. The first is the `unique = true` constraint on both `username` and `email`. This is enforced at the database level, which means even if a race condition slips through your service logic, MySQL will reject a duplicate insert. The second is the `role` field as a plain `String`. We could model roles as a separate table with a many-to-many join, but for a blog with a single role per user, a string column is simpler and works perfectly with Spring Security's `GrantedAuthority` API. The convention is to prefix the role with `ROLE_`, which lets Spring Security's `hasRole("USER")` matcher find it correctly.

Now create the repository at `src/main/java/com/qadrlabs/blog/repository/UserRepository.java`:

```java
package com.qadrlabs.blog.repository;

import com.qadrlabs.blog.model.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface UserRepository extends JpaRepository<User, Long> {

    // Spring Data JPA generates: SELECT * FROM users WHERE username = ?
    Optional<User> findByUsername(String username);

    // Used during registration to give a friendly error before hitting the DB constraint
    boolean existsByUsername(String username);

    boolean existsByEmail(String email);
}
```

These three methods are all derived from their names by Spring Data JPA. We do not need to write any SQL or JPQL. The `Optional<User>` return type on `findByUsername` matters because Spring Security expects an exception (specifically, `UsernameNotFoundException`) when the user does not exist, and `Optional` gives us a clean way to handle that with `orElseThrow()`.

## Step 3: Implement the UserDetailsService {#step-3-implement-userdetailsservice}

Spring Security has its own model of what a "user" looks like: an object that implements the `UserDetails` interface, with methods like `getUsername()`, `getPassword()`, `getAuthorities()`, and a few flags about account status. Our `User` entity does not implement that interface, and that is intentional. We do not want our domain model to be coupled to a security framework. The bridge between the two worlds is `UserDetailsService`, a single-method interface that Spring Security calls during login to fetch the user record.

Create the file `src/main/java/com/qadrlabs/blog/service/CustomUserDetailsService.java`:

```java
package com.qadrlabs.blog.service;

import com.qadrlabs.blog.model.User;
import com.qadrlabs.blog.repository.UserRepository;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class CustomUserDetailsService implements UserDetailsService {

    private final UserRepository userRepository;

    public CustomUserDetailsService(UserRepository userRepository) {
        this.userRepository = userRepository;
    }

    @Override
    public UserDetails loadUserByUsername(String username) throws UsernameNotFoundException {
        // Step 1: look up the user in the database. If missing, throw the exception
        // that Spring Security expects (it converts this into a "Bad credentials" message
        // rather than exposing whether the username existed).
        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new UsernameNotFoundException(
                        "User not found with username: " + username));

        // Step 2: convert our role string into a GrantedAuthority. Spring Security
        // works with collections of authorities, not raw strings, so the conversion
        // happens here.
        List<SimpleGrantedAuthority> authorities = List.of(
                new SimpleGrantedAuthority(user.getRole())
        );

        // Step 3: wrap everything in Spring Security's built-in User class, which is
        // an immutable implementation of UserDetails. The password we pass in is the
        // BCrypt hash from the database; Spring Security will hash the submitted
        // password and compare them.
        return org.springframework.security.core.userdetails.User.builder()
                .username(user.getUsername())
                .password(user.getPassword())
                .authorities(authorities)
                .build();
    }
}
```

Notice the careful naming on the last lines. Both our `model.User` and Spring Security's `userdetails.User` are called `User`, which is why we use the fully qualified name `org.springframework.security.core.userdetails.User` to make the intent obvious. An alternative is to add an import alias, but in tutorial code the fully qualified name is more self-documenting.

The error message we throw deserves a brief mention. We say "User not found", but Spring Security never shows this message to the end user. By default, the framework converts any `UsernameNotFoundException` (and any `BadCredentialsException`) into the same generic "Bad credentials" message at the login page. This is a security feature, not a bug. If the login page said "User not found" when you typed the wrong username and "Wrong password" when you typed the wrong password, an attacker could enumerate valid usernames by trying random ones and watching for which message appears.

## Step 4: Configure Spring Security {#step-4-configure-spring-security}

This is the core of the whole tutorial. The security configuration tells Spring Security three things at once: which URLs are public, which URLs require authentication, and how the login and logout flows should look. In Spring Security 7 (which ships with Spring Boot 4), the only supported configuration style is the Lambda DSL. The older chained style with `.and()` calls has been removed, and the older `WebSecurityConfigurerAdapter` class was already removed in Spring Security 6.

Create the file `src/main/java/com/qadrlabs/blog/config/SecurityConfig.java`:

```java
package com.qadrlabs.blog.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;

@Configuration
@EnableWebSecurity
public class SecurityConfig {

    @Bean
    public PasswordEncoder passwordEncoder() {
        // BCrypt is the industry-standard password hashing algorithm.
        // It includes a salt automatically and is intentionally slow to
        // resist brute-force attacks.
        return new BCryptPasswordEncoder();
    }

    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        http
                // Define which URLs are public and which require authentication.
                // Order matters here: more specific patterns should come first.
                .authorizeHttpRequests(auth -> auth
                        .requestMatchers("/register", "/login").permitAll()
                        .requestMatchers("/css/**", "/js/**", "/images/**").permitAll()
                        .anyRequest().authenticated()
                )
                // Configure the form-based login flow with our custom pages.
                .formLogin(form -> form
                        .loginPage("/login")
                        .defaultSuccessUrl("/posts", true)
                        .failureUrl("/login?error")
                        .permitAll()
                )
                // Configure logout. Spring Security handles POST /logout automatically.
                .logout(logout -> logout
                        .logoutSuccessUrl("/login?logout")
                        .permitAll()
                );

        return http.build();
    }
}
```

This file is short, but every line is doing real work. Let's walk through it carefully.

The `PasswordEncoder` bean returns a `BCryptPasswordEncoder`. Two things happen because of this bean. First, when we register a new user, we will call `passwordEncoder.encode(plainPassword)` to get the hash that goes into the database. Second, when a user logs in, Spring Security's `DaoAuthenticationProvider` will call `passwordEncoder.matches(submittedPassword, storedHash)` to verify the password. Both steps use the same bean, which guarantees the hashing algorithms are consistent.

The `SecurityFilterChain` bean is where we describe the request rules. The `authorizeHttpRequests` block says that `/register`, `/login`, and any static assets are open to everyone, and every other URL requires an authenticated session. The order is significant: Spring Security checks the rules from top to bottom, and the first match wins. If you put `.anyRequest().authenticated()` before `.requestMatchers("/register").permitAll()`, registration would be impossible because the catch-all rule would match first.

The `formLogin` block tells Spring Security to use form-based authentication and points to our custom login page at `/login`. The `defaultSuccessUrl("/posts", true)` line sends the user to the posts list after a successful login, and the second argument `true` means "always go here, even if the user was originally trying to reach a different URL". Without `true`, Spring Security would remember the original target and send them there instead, which is sometimes what you want but adds complexity we do not need right now. The `failureUrl("/login?error")` line redirects back to the login page with an `error` query parameter when authentication fails, so the page can display an error message.

The `logout` block configures the logout flow. We do not need to write a logout controller because Spring Security provides one automatically at `POST /logout`. After logout, it redirects to `/login?logout`, which lets our login page show a confirmation message.

You might be wondering where `DaoAuthenticationProvider` is. The short answer is that Spring Boot autoconfigures it for us. As soon as it sees a `UserDetailsService` bean (our `CustomUserDetailsService` is annotated `@Service`) and a `PasswordEncoder` bean in the application context, it builds a `DaoAuthenticationProvider`, wires both beans into it, and registers it with the `AuthenticationManager`. This is a major improvement over older tutorials that required you to wire all three pieces by hand.

Finally, you might also wonder about CSRF protection. We never disabled it, and we never configured it either. That is on purpose. CSRF protection is enabled by default in Spring Security, and it is exactly what we want for a web app that uses session cookies. Thymeleaf will automatically inject a hidden `_csrf` token into every form that uses `th:action`, which means our forms will pass CSRF validation without any extra work on our part.

## Step 5: Build the Registration Flow {#step-5-build-registration-flow}

With the security foundation in place, we can build the user-facing parts. We will start with registration because login depends on having users to log in as.

A common mistake in registration flows is to bind the form directly to the `User` entity. This is tempting because the fields mostly line up, but it creates problems. The form has a `confirmPassword` field that has no place in the database. The form has a plain-text `password` that we must never store as-is. And binding directly to the entity means Spring's `@ModelAttribute` will eagerly try to populate fields like `id`, `role`, `createdAt`, and `updatedAt` from query parameters, which is a mass-assignment vulnerability waiting to happen.

The clean solution is a Data Transfer Object (DTO) that exists only for the form. Create `src/main/java/com/qadrlabs/blog/dto/RegistrationDto.java`:

```java
package com.qadrlabs.blog.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public class RegistrationDto {

    @NotBlank(message = "Username is required")
    @Size(min = 3, max = 50, message = "Username must be between 3 and 50 characters")
    private String username;

    @NotBlank(message = "Email is required")
    @Email(message = "Email must be a valid address")
    private String email;

    @NotBlank(message = "Password is required")
    @Size(min = 6, max = 100, message = "Password must be at least 6 characters")
    private String password;

    @NotBlank(message = "Please confirm your password")
    private String confirmPassword;

    public RegistrationDto() {}

    public String getUsername() { return username; }
    public void setUsername(String username) { this.username = username; }

    public String getEmail() { return email; }
    public void setEmail(String email) { this.email = email; }

    public String getPassword() { return password; }
    public void setPassword(String password) { this.password = password; }

    public String getConfirmPassword() { return confirmPassword; }
    public void setConfirmPassword(String confirmPassword) { this.confirmPassword = confirmPassword; }
}
```

The DTO has exactly the fields the form needs and nothing else. There is no `id`, no `role`, no timestamps, and no way for an attacker to set those values by adding extra parameters to the request. The validation annotations enforce the rules we care about: required fields, valid email format, password length.

Now we need a service that converts a valid DTO into a saved `User`. Create `src/main/java/com/qadrlabs/blog/service/UserService.java`:

```java
package com.qadrlabs.blog.service;

import com.qadrlabs.blog.dto.RegistrationDto;
import com.qadrlabs.blog.model.User;
import com.qadrlabs.blog.repository.UserRepository;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

@Service
public class UserService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;

    public UserService(UserRepository userRepository, PasswordEncoder passwordEncoder) {
        this.userRepository = userRepository;
        this.passwordEncoder = passwordEncoder;
    }

    public User register(RegistrationDto dto) {
        // Reject duplicate usernames with a friendly error rather than a DB constraint violation
        if (userRepository.existsByUsername(dto.getUsername())) {
            throw new IllegalArgumentException("Username is already taken");
        }

        if (userRepository.existsByEmail(dto.getEmail())) {
            throw new IllegalArgumentException("Email is already registered");
        }

        // Confirm the password fields match. The DTO cannot do this with annotations
        // alone because cross-field validation requires custom logic.
        if (!dto.getPassword().equals(dto.getConfirmPassword())) {
            throw new IllegalArgumentException("Passwords do not match");
        }

        // Convert the DTO into a User entity. Critically, the password is hashed
        // here and ONLY here. Plain-text passwords never leave this method.
        User user = new User();
        user.setUsername(dto.getUsername());
        user.setEmail(dto.getEmail());
        user.setPassword(passwordEncoder.encode(dto.getPassword()));
        user.setRole("ROLE_USER");

        return userRepository.save(user);
    }
}
```

Several details are worth highlighting. The order of checks matters: we check for duplicate username first because it is the most common cause of registration failure, and an immediate rejection is faster than running the password matcher. The password hashing happens at exactly one place, which makes it easy to audit. We hardcode `ROLE_USER` because we have no admin signup flow; an admin would be created manually or seeded by a startup script.

Now create the controller at `src/main/java/com/qadrlabs/blog/controller/AuthController.java`:

```java
package com.qadrlabs.blog.controller;

import com.qadrlabs.blog.dto.RegistrationDto;
import com.qadrlabs.blog.service.UserService;
import jakarta.validation.Valid;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.validation.BindingResult;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.ModelAttribute;
import org.springframework.web.bind.annotation.PostMapping;

@Controller
public class AuthController {

    private final UserService userService;

    public AuthController(UserService userService) {
        this.userService = userService;
    }

    @GetMapping("/login")
    public String login() {
        // No model needed; the login form is rendered by Spring Security via our Thymeleaf page
        return "auth/login";
    }

    @GetMapping("/register")
    public String showRegisterForm(Model model) {
        // An empty DTO acts as the form-backing object so Thymeleaf can bind fields
        model.addAttribute("registration", new RegistrationDto());
        return "auth/register";
    }

    @PostMapping("/register")
    public String register(@Valid @ModelAttribute("registration") RegistrationDto dto,
                           BindingResult bindingResult) {
        // First check: bean validation errors (empty fields, bad email format, short password)
        if (bindingResult.hasErrors()) {
            return "auth/register";
        }

        // Second check: business rule errors from the service (duplicate username/email, password mismatch)
        try {
            userService.register(dto);
        } catch (IllegalArgumentException e) {
            // reject() attaches a global error to the form; we use it because the message
            // is not tied to a single field
            bindingResult.reject("registration.error", e.getMessage());
            return "auth/register";
        }

        // Successful registration: redirect to login with a query flag the page can react to
        return "redirect:/login?registered";
    }
}
```

The two-stage validation pattern is important to understand. First, `@Valid` runs the annotations on the DTO (`@NotBlank`, `@Email`, `@Size`). If any of those fail, we return the form with field errors and stop. Only if those pass do we call the service, which performs the cross-field and database checks. Catching `IllegalArgumentException` is a deliberate trade-off; in larger applications, you might define a `RegistrationException` hierarchy for each kind of failure, but for our purposes a single exception type keeps the code readable.

Now build the registration template at `src/main/resources/templates/auth/register.html`:

```html
<!DOCTYPE html>
<html lang="en" xmlns:th="http://www.thymeleaf.org">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Register</title>
    <script src="https://cdn.tailwindcss.com"></script>
</head>
<body class="bg-gray-100 text-gray-800 font-sans p-6">
    <div class="max-w-md mx-auto bg-white p-6 md:p-8 rounded-lg shadow-md mt-10">
        <h1 class="text-2xl font-bold text-gray-900 mb-6 text-center">Create an Account</h1>

        <form th:action="@{/register}" th:object="${registration}" method="post" class="space-y-5">
            <!-- Global error message from the service layer (duplicate username, etc.) -->
            <div th:if="${#fields.hasGlobalErrors()}" class="bg-red-100 border border-red-300 text-red-700 px-4 py-3 rounded mb-4">
                <p th:each="err : ${#fields.globalErrors()}" th:text="${err}"></p>
            </div>

            <div>
                <label class="block text-sm font-medium text-gray-700 mb-1">Username</label>
                <input type="text" th:field="*{username}" class="w-full px-4 py-2 border border-gray-300 rounded-md focus:ring-blue-500 focus:border-blue-500 outline-none transition"
                       th:classappend="${#fields.hasErrors('username')} ? 'border-red-500' : ''">
                <p th:if="${#fields.hasErrors('username')}" th:errors="*{username}" class="text-red-500 text-sm mt-1"></p>
            </div>

            <div>
                <label class="block text-sm font-medium text-gray-700 mb-1">Email</label>
                <input type="email" th:field="*{email}" class="w-full px-4 py-2 border border-gray-300 rounded-md focus:ring-blue-500 focus:border-blue-500 outline-none transition"
                       th:classappend="${#fields.hasErrors('email')} ? 'border-red-500' : ''">
                <p th:if="${#fields.hasErrors('email')}" th:errors="*{email}" class="text-red-500 text-sm mt-1"></p>
            </div>

            <div>
                <label class="block text-sm font-medium text-gray-700 mb-1">Password</label>
                <input type="password" th:field="*{password}" class="w-full px-4 py-2 border border-gray-300 rounded-md focus:ring-blue-500 focus:border-blue-500 outline-none transition"
                       th:classappend="${#fields.hasErrors('password')} ? 'border-red-500' : ''">
                <p th:if="${#fields.hasErrors('password')}" th:errors="*{password}" class="text-red-500 text-sm mt-1"></p>
            </div>

            <div>
                <label class="block text-sm font-medium text-gray-700 mb-1">Confirm Password</label>
                <input type="password" th:field="*{confirmPassword}" class="w-full px-4 py-2 border border-gray-300 rounded-md focus:ring-blue-500 focus:border-blue-500 outline-none transition"
                       th:classappend="${#fields.hasErrors('confirmPassword')} ? 'border-red-500' : ''">
                <p th:if="${#fields.hasErrors('confirmPassword')}" th:errors="*{confirmPassword}" class="text-red-500 text-sm mt-1"></p>
            </div>

            <button type="submit" class="w-full bg-blue-600 hover:bg-blue-700 text-white font-semibold py-2 rounded-md transition duration-200 shadow-sm">
                Sign Up
            </button>
        </form>

        <p class="text-center text-sm text-gray-600 mt-6">
            Already have an account?
            <a th:href="@{/login}" class="text-blue-600 hover:underline">Sign in</a>
        </p>
    </div>
    <div class="mt-8 mb-6 text-center text-sm text-gray-500">
        <a href="https://qadrlabs.com" class="text-blue-600 hover:text-blue-800 hover:underline transition" target="_blank">Tutorial Spring Boot Authentication at qadrlabs.com</a>
    </div>
</body>
</html>
```

**A note on `#fields` scope.** The `${#fields.hasGlobalErrors()}` expression only works inside an element that carries a `th:object` attribute. Placing the error div outside the `<form th:object="...">` tag causes a `TemplateProcessingException` at render time because Thymeleaf has no form-binding context to resolve `#fields` against. Keeping the error banner as the first child inside the form is the correct pattern.

A subtle but important thing happens because we used `th:action="@{/register}"` instead of a plain `action="/register"`. Thymeleaf's Spring Security integration detects that the form is a POST request, sees that CSRF protection is enabled, and automatically injects a hidden `<input type="hidden" name="_csrf" value="..."/>` field into the rendered HTML. Without this, the form would be rejected by Spring Security with a 403 Forbidden response. The lesson is that you should always use `th:action` for POST forms; it costs nothing and protects against CSRF attacks by default.

## Step 6: Build the Login Page {#step-6-build-login-page}

The login flow is structurally simpler than registration because Spring Security does most of the work for us. We only need to provide the HTML page; the actual POST request will be handled by Spring Security's internal `UsernamePasswordAuthenticationFilter`, which we never see or write.

We already added the `@GetMapping("/login")` handler to `AuthController` in the previous step, so all we need now is the template. Create `src/main/resources/templates/auth/login.html`:

```html
<!DOCTYPE html>
<html lang="en" xmlns:th="http://www.thymeleaf.org">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Sign In</title>
    <script src="https://cdn.tailwindcss.com"></script>
</head>
<body class="bg-gray-100 text-gray-800 font-sans p-6">
    <div class="max-w-md mx-auto bg-white p-6 md:p-8 rounded-lg shadow-md mt-10">
        <h1 class="text-2xl font-bold text-gray-900 mb-6 text-center">Sign In</h1>

        <!-- Shown when Spring Security redirected here after a failed login -->
        <div th:if="${param.error}" class="bg-red-100 border border-red-300 text-red-700 px-4 py-3 rounded mb-4">
            Invalid username or password.
        </div>

        <!-- Shown when Spring Security redirected here after a successful logout -->
        <div th:if="${param.logout}" class="bg-green-100 border border-green-300 text-green-700 px-4 py-3 rounded mb-4">
            You have been signed out.
        </div>

        <!-- Shown when the registration controller redirected here after sign-up -->
        <div th:if="${param.registered}" class="bg-blue-100 border border-blue-300 text-blue-700 px-4 py-3 rounded mb-4">
            Account created. Please sign in.
        </div>

        <form th:action="@{/login}" method="post" class="space-y-5">
            <div>
                <label class="block text-sm font-medium text-gray-700 mb-1">Username</label>
                <input type="text" name="username" required class="w-full px-4 py-2 border border-gray-300 rounded-md focus:ring-blue-500 focus:border-blue-500 outline-none transition">
            </div>

            <div>
                <label class="block text-sm font-medium text-gray-700 mb-1">Password</label>
                <input type="password" name="password" required class="w-full px-4 py-2 border border-gray-300 rounded-md focus:ring-blue-500 focus:border-blue-500 outline-none transition">
            </div>

            <button type="submit" class="w-full bg-blue-600 hover:bg-blue-700 text-white font-semibold py-2 rounded-md transition duration-200 shadow-sm">
                Sign In
            </button>
        </form>

        <p class="text-center text-sm text-gray-600 mt-6">
            Don't have an account?
            <a th:href="@{/register}" class="text-blue-600 hover:underline">Sign up</a>
        </p>
    </div>
    <div class="mt-8 mb-6 text-center text-sm text-gray-500">
        <a href="https://qadrlabs.com" class="text-blue-600 hover:text-blue-800 hover:underline transition" target="_blank">Tutorial Spring Boot Authentication at qadrlabs.com</a>
    </div>
</body>
</html>
```

The input field names `username` and `password` are not arbitrary. They are the parameter names Spring Security's `UsernamePasswordAuthenticationFilter` expects by default. If you renamed `name="username"` to `name="login"`, the filter would not find the credentials and authentication would silently fail. You can change the expected parameter names with `.usernameParameter("email")` in the security config, but the convention is to stick with the defaults unless you have a reason to differ.

The three conditional blocks at the top of the form read query parameters using `${param.error}`, `${param.logout}`, and `${param.registered}`. These correspond to the redirects we configured: `failureUrl("/login?error")`, `logoutSuccessUrl("/login?logout")`, and `redirect:/login?registered`. Thymeleaf's `${param.x}` is non-null whenever the query string contains a parameter named `x`, regardless of its value, which is exactly the flag-style behavior we want here.

## Step 7: Update the Navbar with Authenticated User Info {#step-7-update-navbar}

Right now, a logged-in user has no way to see whose account they are using and no way to sign out. We need to update the posts index page to show this information. The Thymeleaf Security Extras dialect makes this almost trivial.

Open `src/main/resources/templates/posts/index.html`. At the top, update the `<html>` tag to declare the security namespace:

Old version:
```html
<html lang="en" xmlns:th="http://www.thymeleaf.org">
```

New version:
```html
<html lang="en" xmlns:th="http://www.thymeleaf.org"
      xmlns:sec="https://www.thymeleaf.org/thymeleaf-extras-springsecurity6">
```

Then find the existing header block. The old code looks like this:

```html
<div class="flex justify-between items-center mb-6">
    <h1 class="text-3xl font-bold text-gray-900">Manage Posts</h1>
    <a th:href="@{/posts/create}" class="bg-blue-600 hover:bg-blue-700 text-white font-semibold py-2 px-4 rounded-md transition duration-200 shadow-sm">
        Create New Post
    </a>
</div>
```

Replace it with this expanded version that includes the user greeting and logout button:

```html
<div class="flex justify-between items-center mb-6">
    <h1 class="text-3xl font-bold text-gray-900">Manage Posts</h1>
    <div class="flex items-center space-x-4">
        <!-- sec:authentication="name" reads the username from the SecurityContext -->
        <span class="text-sm text-gray-600">
            Signed in as
            <span class="font-semibold text-gray-900" sec:authentication="name">user</span>
        </span>
        <a th:href="@{/posts/create}" class="bg-blue-600 hover:bg-blue-700 text-white font-semibold py-2 px-4 rounded-md transition duration-200 shadow-sm">
            Create New Post
        </a>
        <!-- Spring Security expects logout to be a POST; this form gets a CSRF token automatically -->
        <form th:action="@{/logout}" method="post" class="inline">
            <button type="submit" class="bg-gray-200 hover:bg-gray-300 text-gray-800 font-medium py-2 px-4 rounded-md transition duration-200">
                Sign Out
            </button>
        </form>
    </div>
</div>
```

The `sec:authentication="name"` attribute reads the `name` property of the current `Authentication` object, which by default is the username. The text inside the span (`user`) is a placeholder that gets replaced at render time; you can keep it for offline preview or remove it if you prefer.

The logout form uses `method="post"` because Spring Security 4 and later require logout to be a POST request. This is a defense against CSRF: if logout were a GET, a malicious site could log you out by embedding a hidden image tag pointing to `/logout`. Annoying for the user, harmless on its own, but a bad precedent. Forcing POST means the request must include a CSRF token that only your own site can provide.

## Step 8: Try It Out {#step-8-try-it-out}

We have written all the code. Now we get to see it work end to end. Start the application:

```bash
./mvnw spring-boot:run
```

Wait for the startup log to settle, then open `http://localhost:8080/posts` in your browser. You should be redirected immediately to `http://localhost:8080/login` because the security filter chain rejected the unauthenticated request. Notice that the URL changed; the redirect is real, not a server-side render of the login page on the posts URL.

### Test the Registration Flow

Click the "Sign up" link at the bottom of the login form. You should land on the registration page. Try submitting it with all fields empty and observe that each field shows its own error message. Fix the errors, fill in a username, email, and matching passwords, and click "Sign Up". You should be redirected to `/login?registered`, and the login page should show a blue confirmation banner saying "Account created. Please sign in."

While you are at it, verify the duplicate-username protection. Open the registration page in a new tab, register a second user with the same username you just used, and confirm that the form returns with a red banner saying "Username is already taken."

### Test the Login Flow

On the login page, sign in with the username and password you just registered. You should be redirected to `/posts`, and the navbar should show "Signed in as <yourname>" with a "Sign Out" button next to "Create New Post".

Now test the failure path. Sign out, then try logging back in with the wrong password. You should be redirected to `/login?error` and see a red banner saying "Invalid username or password." Notice that the same message appears whether you typed the wrong username or the wrong password; this is the security feature mentioned earlier preventing username enumeration.

### Test the Logout Flow

Sign in again and click "Sign Out". You should be redirected to `/login?logout` with a green banner saying "You have been signed out." Now try to navigate directly to `http://localhost:8080/posts`. You should be bounced back to the login page, proving the session was actually destroyed and is not just hidden by client-side state.

### Verify the Password Is Hashed

This is the test that makes everything worth it. Open your MySQL client and run:

```sql
SELECT username, password FROM users;
```

You should see something like this:

```
+----------+--------------------------------------------------------------+
| username | password                                                     |
+----------+--------------------------------------------------------------+
| alice    | $2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy |
+----------+--------------------------------------------------------------+
```

The `$2a$10$` prefix is the marker for BCrypt. The `10` is the cost factor (2^10 hash rounds), and the rest is the salt and hash combined. If a database leak happened tomorrow, an attacker would need to brute-force every password individually, and at 2^10 rounds per attempt, that takes a meaningfully long time per password. Compare this to the plain-text disaster of `password=alice123` being readable in one glance, and you can see why hashing is mandatory rather than optional.

## How Spring Security Form Login Works {#how-spring-security-form-login-works}

Now that everything works, let's pull back the curtain on what happens during a single login request. Understanding the flow will help you debug problems later and give you a mental model for adding features like remember-me, two-factor authentication, or OAuth2.

When the browser submits `POST /login` with the username and password, the request travels through Spring Security's filter chain before it reaches any of your code. The relevant filter is `UsernamePasswordAuthenticationFilter`. This filter recognizes the `POST /login` URL, extracts the `username` and `password` parameters from the request body, and packages them into a `UsernamePasswordAuthenticationToken`. This token is not yet authenticated; it is just a container holding the credentials the user claims to have.

The filter hands this unauthenticated token to the `AuthenticationManager`, which is Spring Security's central decision-maker. The `AuthenticationManager` does not authenticate by itself; instead, it asks each registered `AuthenticationProvider` whether it can handle this kind of token. In our setup, there is only one provider, the auto-configured `DaoAuthenticationProvider`. This provider says yes to `UsernamePasswordAuthenticationToken` and goes to work.

`DaoAuthenticationProvider` calls our `CustomUserDetailsService.loadUserByUsername()` with the submitted username. We respond with a `UserDetails` object that contains the BCrypt-hashed password from the database. The provider then asks the `PasswordEncoder` whether the submitted plain-text password matches the stored hash. The encoder hashes the submission with the same salt embedded in the stored hash and compares the result. If they match, authentication succeeds.

On success, `DaoAuthenticationProvider` returns a fully authenticated `Authentication` object back to the `AuthenticationManager`, which returns it to the filter. The filter stores this `Authentication` in the `SecurityContextHolder`, which is backed by a `ThreadLocal` for the duration of the request and gets persisted to the HTTP session at the end. From that point on, every subsequent request from the same browser carries a `JSESSIONID` cookie, and Spring Security uses that cookie to retrieve the same `Authentication` from the session and put it back into the `SecurityContextHolder`. That is how the system remembers you are logged in.

If authentication fails (wrong password, unknown user, account disabled), `DaoAuthenticationProvider` throws an `AuthenticationException`. The filter catches it, clears any partial security context, and triggers the failure handler. In our config, the failure handler is the default one that redirects to the URL we set with `failureUrl("/login?error")`.

If you come from PHP and Laravel, here is a rough mapping that may help your intuition:

| Spring Security | Laravel Equivalent |
|---|---|
| `UserDetailsService` | The `User` Eloquent model used by the auth driver |
| `BCryptPasswordEncoder` | `Hash::make()` and `Hash::check()` |
| `SecurityFilterChain` | Middleware groups attached to routes |
| `SecurityContextHolder` | `Auth::user()` and `Auth::check()` |
| `@AuthenticationPrincipal` | `auth()->user()` injected into controllers |
| CSRF token in forms | The `@csrf` Blade directive |
| `formLogin()` | `Auth::routes()` plus the login controller |
| Default logout URL | `Auth::logout()` and the corresponding route |

The mapping is not perfect because Spring Security is more general-purpose, but it should give you a starting point if you are translating concepts from one framework to the other.

## Conclusion {#conclusion}

In this tutorial, we transformed an open blog into a properly secured application. We added a `User` entity to JPA, implemented a `CustomUserDetailsService` to bridge it with Spring Security, configured Spring Security 7 with the modern Lambda DSL, built registration and login pages with Thymeleaf, and verified that passwords land in the database as BCrypt hashes rather than plain text. The CRUD posts feature now requires authentication, and we have a complete sign-up and sign-in flow that does not depend on any default credentials.

The key takeaways:

- **Spring Security 7 enforces the Lambda DSL.** The older chained style with `.and()` calls and the older `WebSecurityConfigurerAdapter` class are both gone. Every new Spring Boot 4 project must declare a `SecurityFilterChain` bean and configure it with lambdas. The good news is that the Lambda DSL is more readable than what it replaced.
- **`UserDetailsService` is the bridge between your User entity and Spring Security.** You implement one method, `loadUserByUsername()`, and that single integration point lets Spring Security stay completely ignorant of how you store users. You can swap MySQL for MongoDB or LDAP later and only this class changes.
- **`BCryptPasswordEncoder` handles hashing and verification.** Expose it once as a Spring bean, and both the registration service (which calls `encode()`) and the auto-configured `DaoAuthenticationProvider` (which calls `matches()`) use the same instance. Hashing happens at exactly one place in your codebase, the registration service, which makes the security audit trivial.
- **Spring Boot auto-wires `DaoAuthenticationProvider`.** Because we exposed `UserDetailsService` and `PasswordEncoder` as beans, Spring Boot detected them at startup and built the provider for us. You no longer write the wiring code by hand the way older tutorials show.
- **CSRF protection is enabled by default.** Every POST form needs a CSRF token, and Thymeleaf provides one automatically as long as you use `th:action="@{/url}"` instead of a plain `action="/url"`. Disabling CSRF is almost never the right answer for a web app; if you have a problem with it, you usually have a bug to fix, not a feature to turn off.
- **Thymeleaf Security Extras expose authentication info to templates.** The `sec:authentication="name"` attribute is the cleanest way to display the username, and `sec:authorize="isAuthenticated()"` lets you conditionally show or hide UI based on login state. The artifact name still ends in `-springsecurity6`, but it works on Spring Security 7 without changes.
- **A registration DTO separates the form from the entity.** Binding the form directly to the `User` entity invites mass-assignment vulnerabilities and forces the entity to carry fields like `confirmPassword` that have no business being persisted. A dedicated DTO with its own validation rules keeps the entity clean and the form ergonomic.
- **The `POST /login` and `POST /logout` endpoints are provided by Spring Security.** You never write them yourself. You only write the GET handler that serves the login page, and Spring Security plugs in the form processor, the session manager, and the redirect logic behind the scenes.

With authentication in place, the natural next step is authorization. Right now, every logged-in user can edit and delete every post, including posts written by other users. In a real blog, each post should belong to its author, and only the author (or an admin) should be allowed to modify it. That is exactly the topic for the next article in this series. We will also revisit the test suite from the testing tutorial and update it to handle secured endpoints, because adding security tends to break controller tests that did not account for the new login wall.