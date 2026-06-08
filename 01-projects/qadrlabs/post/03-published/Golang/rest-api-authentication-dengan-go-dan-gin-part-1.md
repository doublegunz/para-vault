---
title: "REST API Authentication dengan Go dan Gin"
slug: "rest-api-authentication-dengan-go-dan-gin-part-1"
category: "Golang"
date: "2025-06-28"
status: "published"
---

Halo, pada tutorial Go bagian pertama ini kita akan membahas bagaimana caranya membuat REST API untuk sistem authentication menggunakan bahasa pemrograman Go dan framework [Gin](https://gin-gonic.com/). Gin merupakan web framework yang ringan dan cepat untuk Go, dengan performance yang sangat baik dan API yang mudah digunakan.

Pada Part 1 ini kita akan fokus membangun fondasi aplikasi dan sistem authentication yang aman menggunakan JWT (JSON Web Token). Sistem authentication ini nantinya akan menjadi base untuk Part 2 dimana kita akan implementasikan CRUD operations.

Go sendiri merupakan bahasa pemrograman yang dikembangkan oleh Google yang terkenal dengan kesederhanaan sintaksnya, kecepatan eksekusi, dan dukungan concurrency yang sangat baik. Kombinasi Go dan Gin menjadi pilihan populer untuk membangun microservices dan API yang scalable.

## REST API Authentication dengan Go dan Gin - Part 1 {#table-of-content}

- [Overview](#overview)
- [Persiapan](#persiapan)
- [Step 1 - Setup Project Go](#step-1)
- [Step 2 - Install Dependencies](#step-2)
- [Step 3 - Setup Database Connection](#step-3)
- [Step 4 - Create User Model](#step-4)
- [Step 5 - Create JWT Middleware](#step-5)
- [Step 6 - Create Auth Controller](#step-6)
- [Step 7 - Setup Routes](#step-7)
- [Step 8 - Create Main Application](#step-8)
- [Step 9 - Uji Coba Authentication](#step-9)
- [Uji Coba Register](#uji-coba-1)
- [Uji Coba Login](#uji-coba-2)
- [Uji Coba Get Profile](#uji-coba-3)
- [Penutup](#penutup)

## Overview {#overview}

Pada Part 1 tutorial ini, kita akan membangun sebuah REST API yang memiliki sistem authentication lengkap. Sistem yang akan kita bangun mencakup:

1. **User Registration** - Endpoint untuk mendaftarkan user baru dengan validasi email unique dan password hashing
2. **User Login** - Endpoint untuk login dan mendapatkan JWT token
3. **Protected Routes** - Implementasi middleware untuk melindungi endpoint tertentu
4. **Get User Profile** - Endpoint protected untuk mendapatkan data user yang sedang login
5. **JWT Token Management** - Sistem generate dan validasi JWT token untuk authentication

Tujuan dari Part 1 ini adalah untuk memberikan pemahaman praktis tentang:
- Cara setup project Go dengan struktur yang baik
- Implementasi authentication yang aman menggunakan JWT
- Password hashing dengan bcrypt untuk keamanan
- Middleware pattern di Gin framework
- Best practices dalam membuat REST API authentication

Setelah menyelesaikan Part 1 ini, Anda akan memiliki REST API dengan sistem authentication yang solid dan siap untuk dikembangkan lebih lanjut dengan fitur-fitur lainnya di Part 2.

## Persiapan {#persiapan}

Sebelum kita mulai membangun aplikasi, ada beberapa tools dan software yang harus kita siapkan terlebih dahulu. Persiapan yang matang akan memastikan proses development berjalan lancar:

1. **Go Programming Language** - Download dan install Go dari situs resmi [golang.org](https://golang.org/dl/). Tutorial ini membutuhkan Go versi 1.21 atau lebih baru karena kita akan menggunakan beberapa fitur modern Go.

2. **MySQL Database** - Kita akan menggunakan MySQL sebagai database untuk menyimpan data user. Pastikan MySQL sudah terinstall dan berjalan di sistem Anda. Anda bisa menggunakan MySQL Community Edition yang gratis.

3. **Postman** - Download dari [postman.com](https://www.postman.com/downloads/) untuk testing API endpoints. Postman akan sangat membantu dalam proses development dan debugging API.

4. **Text Editor/IDE** - Gunakan VS Code dengan Go extension, GoLand, atau text editor pilihan Anda yang mendukung Go development. Syntax highlighting dan auto-completion akan sangat membantu.

Untuk memverifikasi Go sudah terinstall dengan benar, jalankan command berikut di terminal:
```bash
go version
```

Anda harus melihat output seperti:
```
go version go1.22.4 linux/amd64
```

## Step 1 - Setup Project Go {#step-1}

Mari kita mulai dengan membuat struktur project yang terorganisir. Struktur yang baik akan memudahkan maintenance dan pengembangan aplikasi ke depannya.

Pertama, buat direktori baru untuk project:

```bash
mkdir go-gin-auth-api
cd go-gin-auth-api
```

Inisialisasi Go module. Module name ini akan menjadi identifier project Anda:

```bash
go mod init github.com/username/go-gin-auth-api
```

**Catatan**: untuk username bisa menggunakan username github kita.

Sekarang kita buat struktur folder yang akan memisahkan berbagai komponen aplikasi:

```bash
mkdir -p controllers models middlewares config database utils
```

Setelah selesai, struktur folder kita akan terlihat seperti ini:
```
go-gin-auth-api/
├── config/         # Konfigurasi aplikasi
├── controllers/    # Handler untuk endpoints
├── database/       # Koneksi dan setup database
├── middlewares/    # Middleware functions
├── models/         # Data models/struktur
├── utils/          # Helper functions
├── go.mod          # Go module file
└── main.go         # Entry point aplikasi
```

Struktur ini mengikuti pattern yang umum digunakan dalam Go web development, memisahkan concerns berdasarkan fungsinya masing-masing.

## Step 2 - Install Dependencies {#step-2}

Sekarang kita akan menginstall semua dependencies yang diperlukan. Setiap dependency memiliki peran penting dalam aplikasi kita:

```bash
# Gin Web Framework - framework utama untuk routing dan middleware
go get -u github.com/gin-gonic/gin

# GORM - ORM library untuk interaksi dengan database
go get -u gorm.io/gorm
go get -u gorm.io/driver/mysql

# JWT - untuk generate dan validasi JSON Web Tokens
go get -u github.com/golang-jwt/jwt/v5

# Bcrypt - untuk hash dan verifikasi password
go get -u golang.org/x/crypto/bcrypt

# Godotenv - untuk load environment variables dari file .env
go get -u github.com/joho/godotenv
```

Setelah semua dependencies terinstall, buat file `.env` di root project untuk menyimpan konfigurasi sensitif:

```
# Database Configuration
DB_HOST=localhost
DB_PORT=3306
DB_USER=root
DB_PASSWORD=your_password
DB_NAME=go_auth_api

# JWT Configuration
JWT_SECRET=your-super-secret-jwt-key-change-this-in-production

# Server Configuration
PORT=8080
GIN_MODE=debug
```

**Penting**: Tambahkan `.env` ke `.gitignore` agar file ini tidak ter-commit ke repository:

```bash
echo ".env" >> .gitignore
```

## Step 3 - Setup Database Connection {#step-3}

Database connection adalah komponen kritis dalam aplikasi. Mari kita buat connection manager yang robust dengan proper error handling.

Buat file `database/connection.go`:

```go
package database

import (
    "fmt"
    "log"
    "os"
    "time"

    "gorm.io/driver/mysql"
    "gorm.io/gorm"
    "gorm.io/gorm/logger"
)

// DB adalah instance global database connection
var DB *gorm.DB

// ConnectDatabase menginisialisasi koneksi ke database MySQL
func ConnectDatabase() {
    // Membaca konfigurasi dari environment variables
    dbHost := os.Getenv("DB_HOST")
    dbPort := os.Getenv("DB_PORT")
    dbUser := os.Getenv("DB_USER")
    dbPassword := os.Getenv("DB_PASSWORD")
    dbName := os.Getenv("DB_NAME")

    // Validasi konfigurasi database
    if dbHost == "" || dbPort == "" || dbUser == "" || dbName == "" {
        log.Fatal("Database configuration is incomplete. Please check your .env file")
    }

    // Format DSN (Data Source Name) untuk MySQL
    // parseTime=True untuk parsing DATE dan DATETIME ke time.Time
    // loc=Local untuk menggunakan timezone lokal
    dsn := fmt.Sprintf("%s:%s@tcp(%s:%s)/%s?charset=utf8mb4&parseTime=True&loc=Local",
        dbUser, dbPassword, dbHost, dbPort, dbName)

    // Konfigurasi GORM
    config := &gorm.Config{
        Logger: logger.Default.LogMode(logger.Info), // Log semua SQL queries di development
        NowFunc: func() time.Time {
            return time.Now().Local()
        },
    }

    // Membuka koneksi ke database dengan retry mechanism
    var err error
    for i := 0; i < 3; i++ {
        DB, err = gorm.Open(mysql.Open(dsn), config)
        if err == nil {
            break
        }
        log.Printf("Failed to connect to database (attempt %d/3): %v", i+1, err)
        time.Sleep(2 * time.Second)
    }

    if err != nil {
        log.Fatal("Failed to connect to database after 3 attempts:", err)
    }

    // Configure connection pool untuk performance
    sqlDB, err := DB.DB()
    if err != nil {
        log.Fatal("Failed to configure database connection pool:", err)
    }

    // SetMaxIdleConns sets the maximum number of connections in the idle connection pool
    sqlDB.SetMaxIdleConns(10)

    // SetMaxOpenConns sets the maximum number of open connections to the database
    sqlDB.SetMaxOpenConns(100)

    // SetConnMaxLifetime sets the maximum amount of time a connection may be reused
    sqlDB.SetConnMaxLifetime(time.Hour)

    log.Println("✅ Database connected successfully")
}

// CloseDatabase menutup koneksi database dengan graceful
func CloseDatabase() {
    sqlDB, err := DB.DB()
    if err != nil {
        log.Printf("Error getting database instance: %v", err)
        return
    }
    
    if err := sqlDB.Close(); err != nil {
        log.Printf("Error closing database connection: %v", err)
    } else {
        log.Println("Database connection closed")
    }
}
```

Connection manager ini memiliki beberapa fitur penting:
- Retry mechanism untuk koneksi yang gagal
- Connection pooling untuk performance
- Proper error handling dan logging
- Graceful shutdown support

## Step 4 - Create User Model {#step-4}

Model User adalah representasi data user dalam aplikasi. Kita akan membuat model yang aman dengan password hashing.

Buat file `models/user.go`:

```go
package models

import (
    "errors"
    "time"

    "golang.org/x/crypto/bcrypt"
    "gorm.io/gorm"
)

// User model untuk authentication
type User struct {
    ID        uint      `json:"id" gorm:"primaryKey"`
    Name      string    `json:"name" gorm:"not null;size:100"`
    Email     string    `json:"email" gorm:"uniqueIndex;not null;size:100"`
    Password  string    `json:"-" gorm:"not null"` // json:"-" agar password tidak di-serialize ke JSON
    CreatedAt time.Time `json:"created_at"`
    UpdatedAt time.Time `json:"updated_at"`
}

// TableName menentukan nama table di database
func (User) TableName() string {
    return "users"
}

// BeforeCreate adalah hook yang dipanggil sebelum create user
func (u *User) BeforeCreate(tx *gorm.DB) error {
    // Validasi tambahan sebelum create
    if len(u.Password) < 6 {
        return errors.New("password must be at least 6 characters")
    }
    
    // Hash password sebelum save ke database
    hashedPassword, err := u.HashPassword(u.Password)
    if err != nil {
        return err
    }
    u.Password = hashedPassword
    
    return nil
}

// HashPassword mengenkripsi password menggunakan bcrypt
func (u *User) HashPassword(password string) (string, error) {
    // bcrypt.DefaultCost adalah 10, yang merupakan balance yang baik antara security dan performance
    bytes, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
    if err != nil {
        return "", err
    }
    return string(bytes), nil
}

// CheckPassword memverifikasi password dengan hash yang tersimpan
func (u *User) CheckPassword(password string) error {
    return bcrypt.CompareHashAndPassword([]byte(u.Password), []byte(password))
}

// PublicUser adalah struktur untuk response API (tanpa password)
type PublicUser struct {
    ID        uint      `json:"id"`
    Name      string    `json:"name"`
    Email     string    `json:"email"`
    CreatedAt time.Time `json:"created_at"`
}

// ToPublicUser mengkonversi User ke PublicUser untuk response API
func (u *User) ToPublicUser() PublicUser {
    return PublicUser{
        ID:        u.ID,
        Name:      u.Name,
        Email:     u.Email,
        CreatedAt: u.CreatedAt,
    }
}
```

Model ini memiliki beberapa fitur keamanan penting:
- Password tidak akan pernah di-serialize ke JSON response
- Automatic password hashing sebelum save
- Method untuk safe password verification
- PublicUser struct untuk response yang aman

## Step 5 - Create JWT Middleware {#step-5}

JWT middleware adalah komponen crucial untuk mengamankan API endpoints. Mari kita buat middleware yang robust dan reusable.

Buat file `middlewares/auth.go`:

```go
package middlewares

import (
    "fmt"
    "net/http"
    "os"
    "strings"
    "time"

    "github.com/gin-gonic/gin"
    "github.com/golang-jwt/jwt/v5"
)

// Claims struktur untuk JWT payload
type Claims struct {
    UserID uint   `json:"user_id"`
    Email  string `json:"email"`
    Name   string `json:"name"`
    jwt.RegisteredClaims
}

// GenerateToken membuat JWT token baru untuk user
func GenerateToken(userID uint, email, name string) (string, error) {
    // Token expiration time (24 jam)
    expirationTime := time.Now().Add(24 * time.Hour)
    
    // Membuat claims (payload) untuk token
    claims := &Claims{
        UserID: userID,
        Email:  email,
        Name:   name,
        RegisteredClaims: jwt.RegisteredClaims{
            ExpiresAt: jwt.NewNumericDate(expirationTime),
            IssuedAt:  jwt.NewNumericDate(time.Now()),
            NotBefore: jwt.NewNumericDate(time.Now()),
            Issuer:    "go-gin-auth-api",
            Subject:   fmt.Sprintf("%d", userID),
        },
    }

    // Membuat token dengan claims
    token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
    
    // Sign token dengan secret key
    jwtSecret := os.Getenv("JWT_SECRET")
    if jwtSecret == "" {
        return "", fmt.Errorf("JWT_SECRET is not set")
    }
    
    tokenString, err := token.SignedString([]byte(jwtSecret))
    if err != nil {
        return "", err
    }

    return tokenString, nil
}

// AuthMiddleware memverifikasi JWT token dari request header
func AuthMiddleware() gin.HandlerFunc {
    return func(c *gin.Context) {
        // Ambil token dari header Authorization
        authHeader := c.GetHeader("Authorization")
        
        // Validasi format header
        if authHeader == "" {
            c.JSON(http.StatusUnauthorized, gin.H{
                "error": "Authorization header is required",
                "message": "Please provide a valid JWT token in the Authorization header",
            })
            c.Abort()
            return
        }

        // Header format harus: Bearer <token>
        tokenParts := strings.Split(authHeader, " ")
        if len(tokenParts) != 2 || tokenParts[0] != "Bearer" {
            c.JSON(http.StatusUnauthorized, gin.H{
                "error": "Invalid authorization format",
                "message": "Authorization header must be in format: Bearer <token>",
            })
            c.Abort()
            return
        }

        tokenString := tokenParts[1]
        
        // Parse dan validasi token
        claims := &Claims{}
        token, err := jwt.ParseWithClaims(tokenString, claims, func(token *jwt.Token) (interface{}, error) {
            // Validasi signing method
            if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
                return nil, fmt.Errorf("unexpected signing method: %v", token.Header["alg"])
            }
            
            jwtSecret := os.Getenv("JWT_SECRET")
            if jwtSecret == "" {
                return nil, fmt.Errorf("JWT_SECRET is not configured")
            }
            
            return []byte(jwtSecret), nil
        })

        // Handle berbagai error cases
        if err != nil {
            if err == jwt.ErrSignatureInvalid {
                c.JSON(http.StatusUnauthorized, gin.H{
                    "error": "Invalid token signature",
                    "message": "The token signature is invalid",
                })
            } else if err == jwt.ErrTokenExpired {
                c.JSON(http.StatusUnauthorized, gin.H{
                    "error": "Token expired",
                    "message": "Your session has expired. Please login again",
                })
            } else {
                c.JSON(http.StatusUnauthorized, gin.H{
                    "error": "Invalid token",
                    "message": "The provided token is invalid",
                })
            }
            c.Abort()
            return
        }

        // Validasi token
        if !token.Valid {
            c.JSON(http.StatusUnauthorized, gin.H{
                "error": "Invalid token",
                "message": "The token is not valid",
            })
            c.Abort()
            return
        }

        // Simpan user info ke context untuk digunakan di handler
        c.Set("userID", claims.UserID)
        c.Set("userEmail", claims.Email)
        c.Set("userName", claims.Name)
        c.Set("claims", claims)

        // Lanjutkan ke handler berikutnya
        c.Next()
    }
}

// GetUserIDFromContext mengambil user ID dari context
func GetUserIDFromContext(c *gin.Context) (uint, bool) {
    userID, exists := c.Get("userID")
    if !exists {
        return 0, false
    }
    
    // Type assertion untuk convert ke uint
    if id, ok := userID.(uint); ok {
        return id, true
    }
    
    return 0, false
}
```

Middleware ini memiliki fitur-fitur penting:
- Token generation dengan expiration time
- Comprehensive error handling untuk berbagai kasus
- Token validation yang ketat
- Helper functions untuk mengakses user info dari context

## Step 6 - Create Auth Controller {#step-6}

Auth controller akan menangani semua logic untuk authentication endpoints. Mari kita buat controller yang comprehensive dengan validation dan error handling yang baik.

Buat file `controllers/auth_controller.go`:

```go
package controllers

import (
    "net/http"
    "strings"

    "github.com/gin-gonic/gin"
    "github.com/username/go-gin-auth-api/database"
    "github.com/username/go-gin-auth-api/middlewares"
    "github.com/username/go-gin-auth-api/models"
    "gorm.io/gorm"
)

// RegisterRequest struktur untuk validasi input register
type RegisterRequest struct {
    Name     string `json:"name" binding:"required,min=3,max=100"`
    Email    string `json:"email" binding:"required,email,max=100"`
    Password string `json:"password" binding:"required,min=6,max=100"`
}

// LoginRequest struktur untuk validasi input login
type LoginRequest struct {
    Email    string `json:"email" binding:"required,email"`
    Password string `json:"password" binding:"required"`
}

// AuthResponse struktur untuk response authentication
type AuthResponse struct {
    Message string             `json:"message"`
    User    models.PublicUser  `json:"user"`
    Token   string             `json:"token"`
}

// Register handler untuk membuat user baru
func Register(c *gin.Context) {
    var req RegisterRequest
    
    // Validasi dan bind request body
    if err := c.ShouldBindJSON(&req); err != nil {
        c.JSON(http.StatusBadRequest, gin.H{
            "error": "Validation failed",
            "message": err.Error(),
        })
        return
    }

    // Normalize email ke lowercase
    req.Email = strings.ToLower(strings.TrimSpace(req.Email))
    req.Name = strings.TrimSpace(req.Name)

    // Cek apakah email sudah terdaftar
    var existingUser models.User
    result := database.DB.Where("email = ?", req.Email).First(&existingUser)
    
    if result.Error == nil {
        // User dengan email ini sudah ada
        c.JSON(http.StatusConflict, gin.H{
            "error": "Email already registered",
            "message": "An account with this email already exists",
        })
        return
    } else if result.Error != gorm.ErrRecordNotFound {
        // Error database lainnya
        c.JSON(http.StatusInternalServerError, gin.H{
            "error": "Database error",
            "message": "Failed to check existing user",
        })
        return
    }

    // Buat user baru
    user := models.User{
        Name:     req.Name,
        Email:    req.Email,
        Password: req.Password, // Akan di-hash oleh BeforeCreate hook
    }

    // Simpan ke database
    if err := database.DB.Create(&user).Error; err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{
            "error": "Registration failed",
            "message": "Failed to create user account",
        })
        return
    }

    // Generate JWT token untuk auto-login setelah register
    token, err := middlewares.GenerateToken(user.ID, user.Email, user.Name)
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{
            "error": "Token generation failed",
            "message": "Account created but failed to generate authentication token",
        })
        return
    }

    // Success response
    c.JSON(http.StatusCreated, AuthResponse{
        Message: "Registration successful",
        User:    user.ToPublicUser(),
        Token:   token,
    })
}

// Login handler untuk autentikasi user
func Login(c *gin.Context) {
    var req LoginRequest
    
    // Validasi dan bind request body
    if err := c.ShouldBindJSON(&req); err != nil {
        c.JSON(http.StatusBadRequest, gin.H{
            "error": "Validation failed",
            "message": err.Error(),
        })
        return
    }

    // Normalize email
    req.Email = strings.ToLower(strings.TrimSpace(req.Email))

    // Cari user berdasarkan email
    var user models.User
    if err := database.DB.Where("email = ?", req.Email).First(&user).Error; err != nil {
        if err == gorm.ErrRecordNotFound {
            // User tidak ditemukan
            c.JSON(http.StatusUnauthorized, gin.H{
                "error": "Authentication failed",
                "message": "Invalid email or password",
            })
        } else {
            // Database error
            c.JSON(http.StatusInternalServerError, gin.H{
                "error": "Database error",
                "message": "Failed to fetch user data",
            })
        }
        return
    }

    // Verifikasi password
    if err := user.CheckPassword(req.Password); err != nil {
        c.JSON(http.StatusUnauthorized, gin.H{
            "error": "Authentication failed",
            "message": "Invalid email or password",
        })
        return
    }

    // Generate JWT token
    token, err := middlewares.GenerateToken(user.ID, user.Email, user.Name)
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{
            "error": "Token generation failed",
            "message": "Login successful but failed to generate authentication token",
        })
        return
    }

    // Success response
    c.JSON(http.StatusOK, AuthResponse{
        Message: "Login successful",
        User:    user.ToPublicUser(),
        Token:   token,
    })
}

// GetProfile handler untuk mendapatkan data user yang sedang login
func GetProfile(c *gin.Context) {
    // Ambil user ID dari context (di-set oleh auth middleware)
    userID, exists := middlewares.GetUserIDFromContext(c)
    if !exists {
        c.JSON(http.StatusUnauthorized, gin.H{
            "error": "Unauthorized",
            "message": "User ID not found in context",
        })
        return
    }
    
    // Fetch user data dari database
    var user models.User
    if err := database.DB.First(&user, userID).Error; err != nil {
        if err == gorm.ErrRecordNotFound {
            c.JSON(http.StatusNotFound, gin.H{
                "error": "User not found",
                "message": "User account no longer exists",
            })
        } else {
            c.JSON(http.StatusInternalServerError, gin.H{
                "error": "Database error",
                "message": "Failed to fetch user profile",
            })
        }
        return
    }

    // Success response
    c.JSON(http.StatusOK, gin.H{
        "message": "Profile fetched successfully",
        "user": user.ToPublicUser(),
    })
}

// RefreshToken handler untuk refresh JWT token
func RefreshToken(c *gin.Context) {
    // Ambil user info dari context
    userID, _ := middlewares.GetUserIDFromContext(c)
    userEmail, _ := c.Get("userEmail")
    userName, _ := c.Get("userName")
    
    // Generate token baru
    token, err := middlewares.GenerateToken(
        userID,
        userEmail.(string),
        userName.(string),
    )
    
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{
            "error": "Token generation failed",
            "message": "Failed to refresh authentication token",
        })
        return
    }

    // Success response
    c.JSON(http.StatusOK, gin.H{
        "message": "Token refreshed successfully",
        "token": token,
    })
}

// HealthCheck handler untuk cek status API
func HealthCheck(c *gin.Context) {
    c.JSON(http.StatusOK, gin.H{
        "status": "healthy",
        "message": "API is running",
    })
}
```

Controller ini implement best practices:
- Input validation menggunakan binding tags
- Consistent error responses
- Normalization untuk email (lowercase, trim)
- Security considerations (tidak membedakan response untuk email tidak ada vs password salah)
- Helper endpoints untuk refresh token dan health check

## Step 7 - Setup Routes {#step-7}

Routes adalah peta dari URL endpoints ke handler functions. Mari kita organize routes dengan baik.

Buat file `routes/routes.go`:

```go
package routes

import (
    "github.com/gin-gonic/gin"
    "github.com/username/go-gin-auth-api/controllers"
    "github.com/username/go-gin-auth-api/middlewares"
)

// SetupRoutes mengkonfigurasi semua routes aplikasi
func SetupRoutes(router *gin.Engine) {
    // Health check endpoint - selalu public
    router.GET("/health", controllers.HealthCheck)

    // API version grouping
    v1 := router.Group("/api/v1")
    {
        // Public auth routes (tidak perlu authentication)
        auth := v1.Group("/auth")
        {
            auth.POST("/register", controllers.Register)
            auth.POST("/login", controllers.Login)
        }

        // Protected routes (perlu authentication)
        protected := v1.Group("/")
        protected.Use(middlewares.AuthMiddleware()) // Apply auth middleware
        {
            // User routes
            protected.GET("/profile", controllers.GetProfile)
            protected.POST("/auth/refresh", controllers.RefreshToken)
        }
    }

    // Setup 404 handler untuk undefined routes
    router.NoRoute(func(c *gin.Context) {
        c.JSON(404, gin.H{
            "error": "Not Found",
            "message": "The requested endpoint does not exist",
        })
    })
}

// SetupMiddlewares mengkonfigurasi global middlewares
func SetupMiddlewares(router *gin.Engine) {
    router.Use(gin.Recovery())
    router.Use(gin.Logger())

    // CORS middleware
    // Catatan: Access-Control-Allow-Origin tidak boleh "*" jika
    // Access-Control-Allow-Credentials: true — browser akan menolaknya.
    // Gunakan origin spesifik sesuai frontend Nuxt yang berjalan.
    router.Use(func(c *gin.Context) {
        origin := c.Request.Header.Get("Origin")

        // Daftar origin yang diizinkan
        allowedOrigins := map[string]bool{
            "http://localhost:3000": true,
            "http://127.0.0.1:3000": true,
        }

        if allowedOrigins[origin] {
            c.Writer.Header().Set("Access-Control-Allow-Origin", origin)
        }

        c.Writer.Header().Set("Access-Control-Allow-Credentials", "true")
        c.Writer.Header().Set("Access-Control-Allow-Headers", "Content-Type, Content-Length, Accept-Encoding, X-CSRF-Token, Authorization, accept, origin, Cache-Control, X-Requested-With")
        c.Writer.Header().Set("Access-Control-Allow-Methods", "POST, OPTIONS, GET, PUT, DELETE")

        if c.Request.Method == "OPTIONS" {
            c.AbortWithStatus(204)
            return
        }

        c.Next()
    })
}
```

Route organization ini memiliki beberapa keuntungan:
- API versioning support (v1)
- Clear separation antara public dan protected routes
- Global middleware setup yang terpisah
- 404 handler untuk undefined routes
- CORS support untuk frontend integration

## Step 8 - Create Main Application {#step-8}

Sekarang kita buat entry point aplikasi yang menggabungkan semua komponen.

Buat file `main.go`:

```go
package main

import (
    "context"
    "log"
    "net/http"
    "os"
    "os/signal"
    "syscall"
    "time"

    "github.com/gin-gonic/gin"
    "github.com/joho/godotenv"
    "github.com/username/go-gin-auth-api/database"
    "github.com/username/go-gin-auth-api/models"
    "github.com/username/go-gin-auth-api/routes"
)

func init() {
    // Load .env file di development environment
    if os.Getenv("GO_ENV") != "production" {
        if err := godotenv.Load(); err != nil {
            log.Printf("Warning: .env file not found")
        }
    }
}

func main() {
    // Set Gin mode berdasarkan environment
    ginMode := os.Getenv("GIN_MODE")
    if ginMode == "" {
        ginMode = gin.DebugMode
    }
    gin.SetMode(ginMode)

    // Connect ke database
    database.ConnectDatabase()
    
    // Auto migrate models
    if err := database.DB.AutoMigrate(&models.User{}); err != nil {
        log.Fatal("Failed to migrate database:", err)
    }
    log.Println("✅ Database migration completed")

    // Setup Gin router
    router := gin.New()
    
    // Setup global middlewares
    routes.SetupMiddlewares(router)
    
    // Setup routes
    routes.SetupRoutes(router)

    // Get port dari environment atau gunakan default
    port := os.Getenv("PORT")
    if port == "" {
        port = "8080"
    }

    // Create HTTP server
    srv := &http.Server{
        Addr:         ":" + port,
        Handler:      router,
        ReadTimeout:  10 * time.Second,
        WriteTimeout: 10 * time.Second,
        IdleTimeout:  120 * time.Second,
    }

    // Start server dalam goroutine agar tidak blocking
    go func() {
        log.Printf("🚀 Server starting on port %s", port)
        log.Printf("📍 API endpoints available at http://localhost:%s/api/v1", port)
        
        if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
            log.Fatalf("Failed to start server: %v", err)
        }
    }()

    // Wait for interrupt signal untuk graceful shutdown
    quit := make(chan os.Signal, 1)
    signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
    <-quit
    
    log.Println("⚠️  Shutting down server...")

    // Graceful shutdown dengan timeout 5 detik
    ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
    defer cancel()
    
    if err := srv.Shutdown(ctx); err != nil {
        log.Fatal("Server forced to shutdown:", err)
    }

    // Close database connection
    database.CloseDatabase()
    
    log.Println("✅ Server exited properly")
}
```

Main application ini implement:
- Environment-based configuration
- Auto database migration
- Graceful shutdown support
- Proper timeout configurations
- Clear startup logs untuk developer experience

## Step 9 - Uji Coba Authentication {#step-9}

Sekarang saatnya menguji API authentication yang sudah kita buat. Pertama, pastikan MySQL database sudah berjalan, kemudian jalankan aplikasi:

```bash
go run main.go
```

Anda akan melihat output seperti:
```
2025/06/29 10:00:00 ✅ Database connected successfully
2025/06/29 10:00:00 ✅ Database migration completed
2025/06/29 10:00:00 🚀 Server starting on port 8080
2025/06/29 10:00:00 📍 API endpoints available at http://localhost:8080/api/v1
```

Buka Postman untuk mulai testing.

### Uji Coba Register {#uji-coba-1}

Mari kita test endpoint register untuk membuat user baru:

1. Pilih method **POST**
2. URL: `http://localhost:8080/api/v1/auth/register`
3. Pada tab **Headers**, tambahkan:
   - Key: `Content-Type`
   - Value: `application/json`
4. Pada tab **Body**, pilih **raw** dan **JSON**, kemudian masukkan:
```json
{
    "name": "John Doe",
    "email": "john.doe@example.com",
    "password": "securepassword123"
}
```
5. Klik **Send**

Response yang diharapkan untuk successful registration:
```json
{
    "message": "Registration successful",
    "user": {
        "id": 1,
        "name": "John Doe",
        "email": "john.doe@example.com",
        "created_at": "2024-03-12T10:00:00Z"
    },
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

Jika Anda mencoba register dengan email yang sama lagi, akan mendapat response:
```json
{
    "error": "Email already registered",
    "message": "An account with this email already exists"
}
```

### Uji Coba Login {#uji-coba-2}

Sekarang mari test login dengan credentials yang sudah didaftarkan:

1. Pilih method **POST**
2. URL: `http://localhost:8080/api/v1/auth/login`
3. Pada tab **Headers**, tambahkan:
   - Key: `Content-Type`
   - Value: `application/json`
4. Pada tab **Body**, pilih **raw** dan **JSON**:
```json
{
    "email": "john.doe@example.com",
    "password": "securepassword123"
}
```
5. Klik **Send**

Response yang diharapkan:
```json
{
    "message": "Login successful",
    "user": {
        "id": 1,
        "name": "John Doe",
        "email": "john.doe@example.com",
        "created_at": "2024-03-12T10:00:00Z"
    },
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

Simpan token yang diterima karena akan digunakan untuk mengakses protected endpoints.

Jika password salah, response akan seperti:
```json
{
    "error": "Authentication failed",
    "message": "Invalid email or password"
}
```

### Uji Coba Get Profile {#uji-coba-3}

Endpoint get profile adalah protected endpoint yang memerlukan JWT token. Mari test dengan token yang didapat dari login:

1. Pilih method **GET**
2. URL: `http://localhost:8080/api/v1/profile`
3. Pada tab **Headers**, tambahkan:
   - Key: `Authorization`
   - Value: `Bearer <token_dari_login>`
   (Ganti `<token_dari_login>` dengan token actual yang Anda terima)
4. Klik **Send**

Response yang diharapkan:
```json
{
    "message": "Profile fetched successfully",
    "user": {
        "id": 1,
        "name": "John Doe",
        "email": "john.doe@example.com",
        "created_at": "2024-03-12T10:00:00Z"
    }
}
```

Jika Anda tidak menyertakan token atau token invalid:
```json
{
    "error": "Authorization header is required",
    "message": "Please provide a valid JWT token in the Authorization header"
}
```

## Penutup {#penutup}

Selamat! Anda telah berhasil membangun REST API dengan sistem authentication yang solid menggunakan Go dan Gin framework. Berikut adalah key takeaways dari Part 1 tutorial ini:

1. **Struktur Project yang Terorganisir** - Kita telah mengimplementasikan struktur folder yang memisahkan concerns dengan jelas (models, controllers, middlewares, dll). Struktur ini memudahkan maintenance dan memungkinkan tim untuk bekerja pada berbagai komponen secara paralel.

2. **Authentication yang Aman dengan JWT** - Implementasi JWT dengan proper validation, expiration time, dan error handling memberikan layer keamanan yang robust. Password di-hash dengan bcrypt sebelum disimpan, dan token memiliki informasi user yang bisa digunakan tanpa query database berulang.

3. **Database Connection Management** - Setup database connection dengan connection pooling, retry mechanism, dan graceful shutdown memastikan aplikasi dapat handle production workload dengan baik.

4. **Input Validation dan Error Handling** - Setiap endpoint memiliki validation yang ketat dan mengembalikan error messages yang konsisten dan informatif, memudahkan debugging dan integrasi dengan frontend.

5. **Middleware Pattern** - Penggunaan middleware untuk authentication mendemonstrasikan bagaimana cross-cutting concerns dapat dihandle dengan elegant di Gin, dan dapat dengan mudah di-extend untuk kebutuhan lain seperti rate limiting atau logging.

6. **Best Practices Go Development** - Tutorial ini menunjukkan berbagai best practices seperti penggunaan environment variables, proper error handling, graceful shutdown, dan code organization yang idiomatic Go.

Fondasi authentication yang sudah kita bangun di Part 1 ini siap untuk dikembangkan lebih lanjut. Di [Part 2](https://qadrlabs.com/member/post/rest-api-crud-operations-dengan-go-dan-gin-part-2), kita akan menambahkan CRUD operations untuk resource management, mendemonstrasikan bagaimana protected endpoints digunakan untuk operasi yang memerlukan authentication.

Beberapa enhancement yang bisa Anda coba tambahkan ke sistem authentication ini:
- Email verification untuk new users
- Password reset functionality
- Rate limiting untuk prevent brute force attacks
- Refresh token mechanism untuk better security
- Role-based access control (RBAC)

Sistem authentication adalah fondasi critical untuk aplikasi modern, dan dengan implementasi yang solid seperti ini, Anda siap membangun aplikasi yang secure dan scalable.