---
title: "REST API Upload File dengan Go dan Gin"
slug: "rest-api-upload-file-dengan-go-dan-gin"
category: "Golang"
date: "2025-07-05"
status: "published"
---

Halo, selamat datang di Part 3 tutorial Go dan Gin! Pada bagian ini kita akan melanjutkan pengembangan REST API dengan menambahkan fitur upload file yang comprehensive. Kita akan memanfaatkan sistem authentication dan CRUD operations yang sudah dibangun di [Part 1](https://qadrlabs.com/member/post/rest-api-authentication-dengan-go-dan-gin-part-1) dan [Part 2](https://qadrlabs.com/member/post/rest-api-crud-operations-dengan-go-dan-gin-part-2) untuk membuat sistem upload file yang aman dan scalable.

Upload file adalah fitur critical dalam aplikasi modern, terutama untuk e-commerce, social media, atau aplikasi content management. Tutorial ini akan mendemonstrasikan best practices dalam handling file uploads dengan Go dan Gin, termasuk validation, security measures, dan optimization techniques.

**Prasyarat**: Pastikan Anda sudah menyelesaikan Part 1 dan Part 2 tutorial ini, karena Part 3 bergantung pada sistem authentication dan product management yang sudah dibangun sebelumnya.

## Table of Content {#table-of-content}

- [Overview](#overview)
- [Persiapan](#persiapan)
- [Step 1 - Setup File Storage Structure](#step-1)
- [Step 2 - Create File Model](#step-2)
- [Step 3 - Create Upload Utilities](#step-3)
- [Step 4 - Create File Repository](#step-4)
- [Step 5 - Create Upload Controller](#step-5)
- [Step 6 - Update Product Model untuk File Relations](#step-6)
- [Step 7 - Update Routes](#step-7)
- [Step 8 - Create File Serving Middleware](#step-8)
- [Step 9 - Update Main Application](#step-9)
- [Step 10 - Uji Coba Upload Operations](#step-10)
- [Uji Coba Single File Upload](#uji-coba-1)
- [Uji Coba Multiple Files Upload](#uji-coba-2)
- [Uji Coba Image Upload dengan Processing](#uji-coba-3)
- [Uji Coba File Management](#uji-coba-4)
- [Uji Coba Security Validations](#uji-coba-5)
- [Penutup](#penutup)

## Overview {#overview}

Pada Part 3 ini, kita akan mengembangkan REST API lebih lanjut dengan menambahkan sistem upload file yang comprehensive. Fitur-fitur yang akan kita implementasikan meliputi:

1. **Single dan Multiple File Upload** - Support untuk upload single file dan batch upload multiple files sekaligus
2. **File Type Validation** - Validasi format file yang diizinkan dengan whitelist approach
3. **File Size Limitations** - Implementasi size limits untuk mencegah abuse dan manage storage
4. **Image Processing** - Auto-resize dan optimization untuk images dengan berbagai sizes
5. **Secure File Storage** - Organized file storage dengan unique naming dan directory structure
6. **File Metadata Management** - Database tracking untuk file information dan relationships
7. **File Serving** - Secure file serving dengan access control dan streaming support
8. **Integration dengan Product** - Attachment files ke products untuk real-world use case

Tujuan dari Part 3 ini adalah untuk memberikan pemahaman mendalam tentang:

- Best practices dalam handling file uploads di Go
- Security considerations untuk file upload systems
- Image processing dan optimization techniques
- Scalable file storage organization
- Integration file uploads dengan existing business logic
- Performance optimization untuk file operations

Setelah menyelesaikan Part 3, Anda akan memiliki REST API dengan sistem file upload yang production-ready, secure, dan scalable.

## Persiapan {#persiapan}

Sebelum memulai Part 3, pastikan Anda memiliki:

1. **Project dari Part 1 & 2** - Semua code dari tutorial sebelumnya harus sudah berjalan dengan baik
2. **Additional Dependencies** - Kita akan menambahkan beberapa libraries untuk image processing dan file handling
3. **Storage Directory** - Setup direktori untuk menyimpan uploaded files
4. **Environment Variables** - Konfigurasi tambahan untuk file upload settings

Mari install dependencies tambahan:

```bash
# Image processing library
go get -u github.com/disintegration/imaging

# UUID generator untuk unique filenames  
go get -u github.com/google/uuid

# Mime type detection
go get -u github.com/gabriel-vasile/mimetype

# File path utilities
go get -u path/filepath
```

Update file `.env` dengan konfigurasi upload:

```
# Existing configurations...
DB_HOST=localhost
DB_PORT=3306
DB_USER=root
DB_PASSWORD=your_password
DB_NAME=go_auth_api
JWT_SECRET=your-super-secret-jwt-key-change-this-in-production
PORT=8080
GIN_MODE=debug

# File Upload Configuration
UPLOAD_PATH=./uploads
MAX_FILE_SIZE=10485760
MAX_FILES_PER_REQUEST=5
ALLOWED_IMAGE_TYPES=jpg,jpeg,png,gif,webp
ALLOWED_DOCUMENT_TYPES=pdf,doc,docx,txt
ENABLE_IMAGE_PROCESSING=true
IMAGE_QUALITY=85
```

Struktur folder akan berkembang menjadi:

```
go-gin-auth-api/
├── config/
├── controllers/
├── database/
├── middlewares/
├── models/
├── repositories/
├── utils/
├── routes/
├── uploads/           # NEW: direktori untuk file storage
│   ├── images/       # Subdirectory untuk images
│   ├── documents/    # Subdirectory untuk documents
│   └── temp/         # Temporary upload directory
├── static/           # NEW: static file serving
├── go.mod
├── go.sum
├── .env
└── main.go
```

## Step 1 - Setup File Storage Structure {#step-1}

Pertama, kita akan membuat utilities untuk setup dan manage file storage directory structure dengan organized approach.

Buat file `utils/storage.go`:

```go
package utils

import (
    "fmt"
    "os"
    "path/filepath"
    "time"
)

// StorageConfig konfigurasi untuk file storage
type StorageConfig struct {
    BasePath     string
    ImagePath    string
    DocumentPath string
    TempPath     string
    MaxFileSize  int64
    MaxFiles     int
}

// GetStorageConfig mengambil konfigurasi storage dari environment
func GetStorageConfig() *StorageConfig {
    basePath := os.Getenv("UPLOAD_PATH")
    if basePath == "" {
        basePath = "./uploads"
    }

    maxFileSize := int64(10 * 1024 * 1024) // 10MB default
    if envSize := os.Getenv("MAX_FILE_SIZE"); envSize != "" {
        if size, err := ParseSize(envSize); err == nil {
            maxFileSize = size
        }
    }

    maxFiles := 5 // default
    if envFiles := os.Getenv("MAX_FILES_PER_REQUEST"); envFiles != "" {
        if files, err := ParseInt(envFiles); err == nil {
            maxFiles = files
        }
    }

    return &StorageConfig{
        BasePath:     basePath,
        ImagePath:    filepath.Join(basePath, "images"),
        DocumentPath: filepath.Join(basePath, "documents"),
        TempPath:     filepath.Join(basePath, "temp"),
        MaxFileSize:  maxFileSize,
        MaxFiles:     maxFiles,
    }
}

// InitializeStorage membuat direktori storage yang diperlukan
func InitializeStorage() error {
    config := GetStorageConfig()
    
    directories := []string{
        config.BasePath,
        config.ImagePath,
        config.DocumentPath,
        config.TempPath,
    }

    for _, dir := range directories {
        // Buat directory dengan subdirectory berdasarkan tahun/bulan untuk organization
        yearMonth := time.Now().Format("2006/01")
        fullPath := filepath.Join(dir, yearMonth)
        
        if err := os.MkdirAll(fullPath, 0755); err != nil {
            return fmt.Errorf("failed to create directory %s: %w", fullPath, err)
        }
    }

    return nil
}

// GetUploadPath mendapatkan path upload berdasarkan file type dan date
func GetUploadPath(fileType string) string {
    config := GetStorageConfig()
    yearMonth := time.Now().Format("2006/01")
    
    switch fileType {
    case "image":
        return filepath.Join(config.ImagePath, yearMonth)
    case "document":
        return filepath.Join(config.DocumentPath, yearMonth)
    default:
        return filepath.Join(config.TempPath, yearMonth)
    }
}

// CleanupTempFiles membersihkan temporary files yang sudah lama
func CleanupTempFiles() error {
    config := GetStorageConfig()
    
    // Hapus files di temp directory yang lebih dari 24 jam
    return filepath.Walk(config.TempPath, func(path string, info os.FileInfo, err error) error {
        if err != nil {
            return err
        }
        
        if !info.IsDir() && time.Since(info.ModTime()) > 24*time.Hour {
            if err := os.Remove(path); err != nil {
                return fmt.Errorf("failed to remove temp file %s: %w", path, err)
            }
        }
        
        return nil
    })
}

// GetFileSize mendapatkan ukuran file dalam bytes
func GetFileSize(filePath string) (int64, error) {
    info, err := os.Stat(filePath)
    if err != nil {
        return 0, err
    }
    return info.Size(), nil
}

// EnsureDirectoryExists memastikan directory ada, buat jika belum ada
func EnsureDirectoryExists(path string) error {
    if _, err := os.Stat(path); os.IsNotExist(err) {
        return os.MkdirAll(path, 0755)
    }
    return nil
}
```

Juga buat file `utils/file_helper.go` untuk utility functions:

```go
package utils

import (
    "fmt"
    "path/filepath"
    "strconv"
    "strings"
    "time"
    "os"

    "github.com/google/uuid"
)

// FileType enum untuk tipe file
type FileType string

const (
    FileTypeImage    FileType = "image"
    FileTypeDocument FileType = "document"
    FileTypeOther    FileType = "other"
)

// GenerateUniqueFilename membuat nama file yang unik
func GenerateUniqueFilename(originalName string) string {
    ext := filepath.Ext(originalName)
    filename := strings.TrimSuffix(originalName, ext)
    
    // Sanitize filename - hapus karakter yang tidak diinginkan
    filename = SanitizeFilename(filename)
    
    // Generate UUID untuk uniqueness
    uniqueID := uuid.New().String()
    timestamp := time.Now().Unix()
    
    return fmt.Sprintf("%s_%d_%s%s", filename, timestamp, uniqueID[:8], ext)
}

// SanitizeFilename membersihkan nama file dari karakter berbahaya
func SanitizeFilename(filename string) string {
    // Hapus karakter yang tidak diinginkan
    replacer := strings.NewReplacer(
        " ", "_",
        "/", "_",
        "\\", "_",
        ":", "_",
        "*", "_",
        "?", "_",
        "\"", "_",
        "<", "_",
        ">", "_",
        "|", "_",
    )
    
    sanitized := replacer.Replace(filename)
    
    // Limit panjang nama file
    if len(sanitized) > 50 {
        sanitized = sanitized[:50]
    }
    
    return sanitized
}

// DetectFileType mendeteksi tipe file berdasarkan extension
func DetectFileType(filename string) FileType {
    ext := strings.ToLower(filepath.Ext(filename))
    
    imageExts := []string{".jpg", ".jpeg", ".png", ".gif", ".bmp", ".webp", ".svg"}
    documentExts := []string{".pdf", ".doc", ".docx", ".txt", ".rtf", ".odt"}
    
    for _, imageExt := range imageExts {
        if ext == imageExt {
            return FileTypeImage
        }
    }
    
    for _, docExt := range documentExts {
        if ext == docExt {
            return FileTypeDocument
        }
    }
    
    return FileTypeOther
}

// IsAllowedFileType mengecek apakah file type diizinkan
func IsAllowedFileType(filename string, fileType FileType) bool {
    ext := strings.ToLower(strings.TrimPrefix(filepath.Ext(filename), "."))
    
    var allowedTypes []string
    
    switch fileType {
    case FileTypeImage:
        allowedTypesStr := GetEnvWithDefault("ALLOWED_IMAGE_TYPES", "jpg,jpeg,png,gif,webp")
        allowedTypes = strings.Split(allowedTypesStr, ",")
    case FileTypeDocument:
        allowedTypesStr := GetEnvWithDefault("ALLOWED_DOCUMENT_TYPES", "pdf,doc,docx,txt")
        allowedTypes = strings.Split(allowedTypesStr, ",")
    default:
        return false
    }
    
    for _, allowedType := range allowedTypes {
        if strings.TrimSpace(allowedType) == ext {
            return true
        }
    }
    
    return false
}

// ParseSize mengubah string size ke bytes (contoh: "10MB" -> 10485760)
func ParseSize(sizeStr string) (int64, error) {
    sizeStr = strings.ToUpper(strings.TrimSpace(sizeStr))
    
    if strings.HasSuffix(sizeStr, "KB") {
        size, err := strconv.ParseInt(strings.TrimSuffix(sizeStr, "KB"), 10, 64)
        return size * 1024, err
    } else if strings.HasSuffix(sizeStr, "MB") {
        size, err := strconv.ParseInt(strings.TrimSuffix(sizeStr, "MB"), 10, 64)
        return size * 1024 * 1024, err
    } else if strings.HasSuffix(sizeStr, "GB") {
        size, err := strconv.ParseInt(strings.TrimSuffix(sizeStr, "GB"), 10, 64)
        return size * 1024 * 1024 * 1024, err
    }
    
    // Assume bytes if no suffix
    return strconv.ParseInt(sizeStr, 10, 64)
}

// ParseInt helper untuk parse integer dari string
func ParseInt(str string) (int, error) {
    return strconv.Atoi(strings.TrimSpace(str))
}

// GetEnvWithDefault helper untuk get environment variable dengan default value
func GetEnvWithDefault(key, defaultValue string) string {
    if value := os.Getenv(key); value != "" {
        return value
    }
    return defaultValue
}

// FormatFileSize mengubah bytes ke human readable format
func FormatFileSize(bytes int64) string {
    const unit = 1024
    if bytes < unit {
        return fmt.Sprintf("%d B", bytes)
    }
    
    div, exp := int64(unit), 0
    for n := bytes / unit; n >= unit; n /= unit {
        div *= unit
        exp++
    }
    
    return fmt.Sprintf("%.1f %cB", float64(bytes)/float64(div), "KMGTPE"[exp])
}
```

File storage utilities ini memberikan:

- **Organized directory structure** berdasarkan tahun/bulan
- **Unique filename generation** untuk mencegah conflicts
- **File type detection** dan validation
- **Cleanup mechanisms** untuk temporary files
- **Security measures** dengan filename sanitization

## Step 2 - Create File Model {#step-2}

Sekarang kita buat model untuk menyimpan metadata file di database. Model ini akan track semua informasi penting tentang uploaded files.

Buat file `models/file.go`:

```go
package models

import (
    "time"
	"fmt"
    "gorm.io/gorm"
)

// File model untuk menyimpan metadata uploaded files
type File struct {
    ID           uint           `json:"id" gorm:"primaryKey"`
    OriginalName string         `json:"original_name" gorm:"not null;size:255"`
    Filename     string         `json:"filename" gorm:"not null;size:255;uniqueIndex"`
    FilePath     string         `json:"file_path" gorm:"not null;size:500"`
    FileSize     int64          `json:"file_size" gorm:"not null"`
    MimeType     string         `json:"mime_type" gorm:"not null;size:100"`
    FileType     string         `json:"file_type" gorm:"not null;size:50;index"` // image, document, other
    Extension    string         `json:"extension" gorm:"not null;size:10"`
    UserID       uint           `json:"user_id" gorm:"not null;index"`
    User         User           `json:"user,omitempty" gorm:"foreignKey:UserID;constraint:OnDelete:CASCADE"`
    
    // Metadata untuk images
    Width        *int           `json:"width,omitempty"`
    Height       *int           `json:"height,omitempty"`
    
    // Status dan flags
    IsPublic     bool           `json:"is_public" gorm:"default:false;index"`
    IsProcessed  bool           `json:"is_processed" gorm:"default:false"`
    
    // Timestamps
    CreatedAt    time.Time      `json:"created_at"`
    UpdatedAt    time.Time      `json:"updated_at"`
    DeletedAt    gorm.DeletedAt `json:"deleted_at,omitempty" gorm:"index"`
}

// TableName menentukan nama table di database
func (File) TableName() string {
    return "files"
}

// BeforeCreate hook sebelum create file record
func (f *File) BeforeCreate(tx *gorm.DB) error {
    // Set default values atau validasi additional
    if f.FileType == "" {
        f.FileType = "other"
    }
    
    return nil
}

// FileResponse struktur untuk API response
type FileResponse struct {
    ID           uint      `json:"id"`
    OriginalName string    `json:"original_name"`
    Filename     string    `json:"filename"`
    FileSize     int64     `json:"file_size"`
    FileSizeFormatted string `json:"file_size_formatted"`
    MimeType     string    `json:"mime_type"`
    FileType     string    `json:"file_type"`
    Extension    string    `json:"extension"`
    UserID       uint      `json:"user_id"`
    Width        *int      `json:"width,omitempty"`
    Height       *int      `json:"height,omitempty"`
    IsPublic     bool      `json:"is_public"`
    IsProcessed  bool      `json:"is_processed"`
    URL          string    `json:"url"`
    ThumbnailURL string    `json:"thumbnail_url,omitempty"`
    CreatedAt    time.Time `json:"created_at"`
    UpdatedAt    time.Time `json:"updated_at"`
}

// ToResponse converts File to FileResponse dengan URL generation
func (f *File) ToResponse(baseURL string) FileResponse {
    response := FileResponse{
        ID:           f.ID,
        OriginalName: f.OriginalName,
        Filename:     f.Filename,
        FileSize:     f.FileSize,
        FileSizeFormatted: formatFileSize(f.FileSize),
        MimeType:     f.MimeType,
        FileType:     f.FileType,
        Extension:    f.Extension,
        UserID:       f.UserID,
        Width:        f.Width,
        Height:       f.Height,
        IsPublic:     f.IsPublic,
        IsProcessed:  f.IsProcessed,
        URL:          generateFileURL(baseURL, f.Filename),
        CreatedAt:    f.CreatedAt,
        UpdatedAt:    f.UpdatedAt,
    }
    
    // Add thumbnail URL for images
    if f.FileType == "image" {
        response.ThumbnailURL = generateThumbnailURL(baseURL, f.Filename)
    }
    
    return response
}

// ProductFile model untuk many-to-many relationship antara Product dan File
type ProductFile struct {
    ID        uint `json:"id" gorm:"primaryKey"`
    ProductID uint `json:"product_id" gorm:"not null;index"`
    FileID    uint `json:"file_id" gorm:"not null;index"`
    IsPrimary bool `json:"is_primary" gorm:"default:false"` // Main image/file untuk product
    SortOrder int  `json:"sort_order" gorm:"default:0"`
    
    // Relationships
    Product   Product   `json:"product,omitempty" gorm:"foreignKey:ProductID;constraint:OnDelete:CASCADE"`
    File      File      `json:"file,omitempty" gorm:"foreignKey:FileID;constraint:OnDelete:CASCADE"`
    
    CreatedAt time.Time `json:"created_at"`
    UpdatedAt time.Time `json:"updated_at"`
}

// TableName untuk ProductFile
func (ProductFile) TableName() string {
    return "product_files"
}

// Utility functions untuk FileResponse
func formatFileSize(bytes int64) string {
    const unit = 1024
    if bytes < unit {
        return fmt.Sprintf("%d B", bytes)
    }
    
    div, exp := int64(unit), 0
    for n := bytes / unit; n >= unit; n /= unit {
        div *= unit
        exp++
    }
    
    return fmt.Sprintf("%.1f %cB", float64(bytes)/float64(div), "KMGTPE"[exp])
}

func generateFileURL(baseURL, filename string) string {
    return fmt.Sprintf("%s/api/v1/files/serve/%s", baseURL, filename)
}

func generateThumbnailURL(baseURL, filename string) string {
    return fmt.Sprintf("%s/api/v1/files/thumbnail/%s", baseURL, filename)
}
```

Model File ini mencakup:

- **Complete metadata tracking** untuk semua types of files
- **Image-specific metadata** seperti width dan height
- **Relationship dengan User** untuk ownership tracking
- **Many-to-many relationship** dengan Product melalui ProductFile
- **Public/private flags** untuk access control
- **Processing status** untuk async operations

## Step 3 - Create Upload Utilities {#step-3}

Sekarang kita buat utilities untuk handle file upload operations, termasuk validation, processing, dan image manipulation.

Buat file `utils/upload.go`:

```go
package utils

import (
    "fmt"
    "image"
    "image/jpeg"
    "image/png"
    "io"
    "mime/multipart"
    "os"
    "path/filepath"
    "strings"

    "github.com/disintegration/imaging"
    "github.com/gabriel-vasile/mimetype"
)

// UploadConfig konfigurasi untuk upload operations
type UploadConfig struct {
    MaxFileSize      int64
    MaxFiles         int
    AllowedTypes     map[FileType][]string
    EnableProcessing bool
    ImageQuality     int
}

// GetUploadConfig mengambil konfigurasi upload dari environment
func GetUploadConfig() *UploadConfig {
    maxFileSize, _ := ParseSize(GetEnvWithDefault("MAX_FILE_SIZE", "10MB"))
    maxFiles, _ := ParseInt(GetEnvWithDefault("MAX_FILES_PER_REQUEST", "5"))
    imageQuality, _ := ParseInt(GetEnvWithDefault("IMAGE_QUALITY", "85"))
    
    allowedTypes := map[FileType][]string{
        FileTypeImage: strings.Split(
            GetEnvWithDefault("ALLOWED_IMAGE_TYPES", "jpg,jpeg,png,gif,webp"), ","),
        FileTypeDocument: strings.Split(
            GetEnvWithDefault("ALLOWED_DOCUMENT_TYPES", "pdf,doc,docx,txt"), ","),
    }
    
    return &UploadConfig{
        MaxFileSize:      maxFileSize,
        MaxFiles:         maxFiles,
        AllowedTypes:     allowedTypes,
        EnableProcessing: GetEnvWithDefault("ENABLE_IMAGE_PROCESSING", "true") == "true",
        ImageQuality:     imageQuality,
    }
}

// FileUploadResult hasil dari upload operation
type FileUploadResult struct {
    Filename     string
    OriginalName string
    FilePath     string
    FileSize     int64
    MimeType     string
    FileType     FileType
    Extension    string
    Width        *int
    Height       *int
    Error        error
}

// ValidateFile memvalidasi uploaded file
func ValidateFile(fileHeader *multipart.FileHeader) error {
    config := GetUploadConfig()
    
    // Check file size
    if fileHeader.Size > config.MaxFileSize {
        return fmt.Errorf("file size %s exceeds maximum allowed size %s",
            FormatFileSize(fileHeader.Size),
            FormatFileSize(config.MaxFileSize))
    }
    
    // Detect file type
    fileType := DetectFileType(fileHeader.Filename)
    
    // Check if file type is allowed
    if !IsAllowedFileType(fileHeader.Filename, fileType) {
        return fmt.Errorf("file type %s is not allowed", filepath.Ext(fileHeader.Filename))
    }
    
    return nil
}

// ProcessSingleUpload memproses single file upload
func ProcessSingleUpload(fileHeader *multipart.FileHeader, userID uint) (*FileUploadResult, error) {
    // Validate file
    if err := ValidateFile(fileHeader); err != nil {
        return nil, err
    }
    
    // Open uploaded file
    file, err := fileHeader.Open()
    if err != nil {
        return nil, fmt.Errorf("failed to open uploaded file: %w", err)
    }
    defer file.Close()
    
    // Detect MIME type
    mimeType, err := detectMimeType(file)
    if err != nil {
        return nil, fmt.Errorf("failed to detect mime type: %w", err)
    }
    
    // Reset file pointer
    file.Seek(0, 0)
    
    // Generate unique filename
    filename := GenerateUniqueFilename(fileHeader.Filename)
    fileType := DetectFileType(filename)
    
    // Get upload path
    uploadPath := GetUploadPath(string(fileType))
    if err := EnsureDirectoryExists(uploadPath); err != nil {
        return nil, fmt.Errorf("failed to create upload directory: %w", err)
    }
    
    // Full file path
    filePath := filepath.Join(uploadPath, filename)
    
    // Create destination file
    dst, err := os.Create(filePath)
    if err != nil {
        return nil, fmt.Errorf("failed to create destination file: %w", err)
    }
    defer dst.Close()
    
    // Copy file content
    fileSize, err := io.Copy(dst, file)
    if err != nil {
        return nil, fmt.Errorf("failed to save file: %w", err)
    }
    
    result := &FileUploadResult{
        Filename:     filename,
        OriginalName: fileHeader.Filename,
        FilePath:     filePath,
        FileSize:     fileSize,
        MimeType:     mimeType,
        FileType:     fileType,
        Extension:    strings.TrimPrefix(filepath.Ext(filename), "."),
    }
    
    // Process image if enabled
    if fileType == FileTypeImage && GetUploadConfig().EnableProcessing {
        if err := processImage(result); err != nil {
            return result, fmt.Errorf("image processing failed: %w", err)
        }
    }
    
    return result, nil
}

// ProcessMultipleUpload memproses multiple file upload
func ProcessMultipleUpload(fileHeaders []*multipart.FileHeader, userID uint) ([]*FileUploadResult, error) {
    config := GetUploadConfig()
    
    // Check maximum files limit
    if len(fileHeaders) > config.MaxFiles {
        return nil, fmt.Errorf("too many files: maximum %d files allowed", config.MaxFiles)
    }
    
    results := make([]*FileUploadResult, 0, len(fileHeaders))
    
    for _, fileHeader := range fileHeaders {
        result, err := ProcessSingleUpload(fileHeader, userID)
        if err != nil {
            // Continue processing other files even if one fails
            result = &FileUploadResult{
                OriginalName: fileHeader.Filename,
                Error:        err,
            }
        }
        results = append(results, result)
    }
    
    return results, nil
}

// detectMimeType mendeteksi MIME type dari file content
func detectMimeType(file multipart.File) (string, error) {
    // Read first 512 bytes untuk MIME detection
    buffer := make([]byte, 512)
    n, err := file.Read(buffer)
    if err != nil && err != io.EOF {
        return "", err
    }
    
    mtype := mimetype.Detect(buffer[:n])
    return mtype.String(), nil
}

// processImage memproses image files (resize, compress, dll)
func processImage(result *FileUploadResult) error {
    // Open image file
    img, err := imaging.Open(result.FilePath)
    if err != nil {
        return fmt.Errorf("failed to open image: %w", err)
    }
    
    // Get original dimensions
    bounds := img.Bounds()
    width := bounds.Dx()
    height := bounds.Dy()
    
    result.Width = &width
    result.Height = &height
    
    // Create thumbnail
    if err := createThumbnail(result.FilePath, img); err != nil {
        return fmt.Errorf("failed to create thumbnail: %w", err)
    }
    
    // Optimize original image if too large
    maxWidth := 2048
    maxHeight := 2048
    
    if width > maxWidth || height > maxHeight {
        resized := imaging.Fit(img, maxWidth, maxHeight, imaging.Lanczos)
        
        // Save optimized image
        if err := saveImage(result.FilePath, resized, result.Extension); err != nil {
            return fmt.Errorf("failed to save optimized image: %w", err)
        }
        
        // Update dimensions
        newBounds := resized.Bounds()
        newWidth := newBounds.Dx()
        newHeight := newBounds.Dy()
        result.Width = &newWidth
        result.Height = &newHeight
    }
    
    return nil
}

// createThumbnail membuat thumbnail dari image
func createThumbnail(originalPath string, img image.Image) error {
    // Generate thumbnail filename
    dir := filepath.Dir(originalPath)
    ext := filepath.Ext(originalPath)
    base := strings.TrimSuffix(filepath.Base(originalPath), ext)
    thumbnailPath := filepath.Join(dir, base+"_thumb"+ext)
    
    // Create 300x300 thumbnail
    thumbnail := imaging.Fit(img, 300, 300, imaging.Lanczos)
    
    // Save thumbnail
    return saveImage(thumbnailPath, thumbnail, strings.TrimPrefix(ext, "."))
}

// saveImage menyimpan image dengan quality compression
func saveImage(path string, img image.Image, extension string) error {
    file, err := os.Create(path)
    if err != nil {
        return err
    }
    defer file.Close()
    
    switch strings.ToLower(extension) {
    case "jpg", "jpeg":
        quality := GetUploadConfig().ImageQuality
        return jpeg.Encode(file, img, &jpeg.Options{Quality: quality})
    case "png":
        return png.Encode(file, img)
    default:
        return jpeg.Encode(file, img, &jpeg.Options{Quality: 85})
    }
}

// DeleteFile menghapus file dari storage
func DeleteFile(filePath string) error {
    if err := os.Remove(filePath); err != nil {
        return fmt.Errorf("failed to delete file %s: %w", filePath, err)
    }
    
    // Try to delete thumbnail if exists
    dir := filepath.Dir(filePath)
    ext := filepath.Ext(filePath)
    base := strings.TrimSuffix(filepath.Base(filePath), ext)
    thumbnailPath := filepath.Join(dir, base+"_thumb"+ext)
    
    if _, err := os.Stat(thumbnailPath); err == nil {
        os.Remove(thumbnailPath) // Ignore error untuk thumbnail
    }
    
    return nil
}

// GetThumbnailPath mendapatkan path thumbnail untuk image
func GetThumbnailPath(originalPath string) string {
    dir := filepath.Dir(originalPath)
    ext := filepath.Ext(originalPath)
    base := strings.TrimSuffix(filepath.Base(originalPath), ext)
    return filepath.Join(dir, base+"_thumb"+ext)
}
```

Upload utilities ini menyediakan:

- **Comprehensive file validation** dengan size dan type checking
- **MIME type detection** untuk additional security
- **Automatic image processing** dengan resize dan compression
- **Thumbnail generation** untuk images
- **Error handling** yang robust untuk edge cases

## Step 4 - Create File Repository {#step-4}

Sekarang kita buat repository untuk manage file data di database dengan pattern yang konsisten dengan tutorial sebelumnya.

Buat file `repositories/file_repository.go`:

```go
package repositories

import (
    "errors"
    "fmt"

    "github.com/username/go-gin-auth-api/models"
    "gorm.io/gorm"
)

// FileRepository interface untuk file operations
type FileRepository interface {
    Create(file *models.File) error
    GetByID(id uint) (*models.File, error)
    GetByFilename(filename string) (*models.File, error)
    GetByUserID(userID uint, params QueryParams) (*PaginatedResult, error)
    GetAll(params QueryParams) (*PaginatedResult, error)
    Update(file *models.File) error
    Delete(id uint) error
    SoftDelete(id uint) error
    
    // Product file associations
    AttachToProduct(productID, fileID uint, isPrimary bool) error
    DetachFromProduct(productID, fileID uint) error
    GetProductFiles(productID uint) ([]models.File, error)
    SetPrimaryFile(productID, fileID uint) error
}

// fileRepository implementasi dari FileRepository
type fileRepository struct {
    db *gorm.DB
}

// NewFileRepository membuat instance baru FileRepository
func NewFileRepository(db *gorm.DB) FileRepository {
    return &fileRepository{db: db}
}

// Create menyimpan file record baru
func (r *fileRepository) Create(file *models.File) error {
    if err := r.db.Create(file).Error; err != nil {
        return fmt.Errorf("failed to create file record: %w", err)
    }
    return nil
}

// GetByID mengambil file berdasarkan ID
func (r *fileRepository) GetByID(id uint) (*models.File, error) {
    var file models.File
    
    err := r.db.Preload("User").First(&file, id).Error
    if err != nil {
        if errors.Is(err, gorm.ErrRecordNotFound) {
            return nil, errors.New("file not found")
        }
        return nil, fmt.Errorf("failed to get file: %w", err)
    }
    
    return &file, nil
}

// GetByFilename mengambil file berdasarkan filename
func (r *fileRepository) GetByFilename(filename string) (*models.File, error) {
    var file models.File
    
    err := r.db.Where("filename = ?", filename).
        Preload("User").
        First(&file).Error
        
    if err != nil {
        if errors.Is(err, gorm.ErrRecordNotFound) {
            return nil, errors.New("file not found")
        }
        return nil, fmt.Errorf("failed to get file: %w", err)
    }
    
    return &file, nil
}

// GetByUserID mengambil files berdasarkan user dengan pagination
func (r *fileRepository) GetByUserID(userID uint, params QueryParams) (*PaginatedResult, error) {
    var files []models.File
    var total int64
    
    // Base query
    query := r.db.Model(&models.File{}).
        Where("user_id = ?", userID).
        Preload("User")
    
    // Apply search filter
    if params.Search != "" {
        searchPattern := "%" + params.Search + "%"
        query = query.Where("original_name LIKE ? OR filename LIKE ?", 
            searchPattern, searchPattern)
    }
    
    // Apply file type filter
    if params.Category != "" {
        query = query.Where("file_type = ?", params.Category)
    }
    
    // Count total
    if err := query.Count(&total).Error; err != nil {
        return nil, fmt.Errorf("failed to count files: %w", err)
    }
    
    // Apply sorting
    sortOrder := "DESC"
    if !params.SortDesc {
        sortOrder = "ASC"
    }
    query = query.Order(fmt.Sprintf("%s %s", params.SortBy, sortOrder))
    
    // Apply pagination
    offset := (params.Page - 1) * params.PageSize
    query = query.Offset(offset).Limit(params.PageSize)
    
    // Execute query
    if err := query.Find(&files).Error; err != nil {
        return nil, fmt.Errorf("failed to get files: %w", err)
    }
    
    // Calculate total pages
    totalPages := int(total) / params.PageSize
    if int(total)%params.PageSize > 0 {
        totalPages++
    }
    
    return &PaginatedResult{
        Data:       files,
        Total:      total,
        Page:       params.Page,
        PageSize:   params.PageSize,
        TotalPages: totalPages,
    }, nil
}

// GetAll mengambil semua files dengan pagination (admin function)
func (r *fileRepository) GetAll(params QueryParams) (*PaginatedResult, error) {
    var files []models.File
    var total int64
    
    // Base query
    query := r.db.Model(&models.File{}).Preload("User")
    
    // Apply search filter
    if params.Search != "" {
        searchPattern := "%" + params.Search + "%"
        query = query.Where("original_name LIKE ? OR filename LIKE ?", 
            searchPattern, searchPattern)
    }
    
    // Apply file type filter
    if params.Category != "" {
        query = query.Where("file_type = ?", params.Category)
    }
    
    // Count total
    if err := query.Count(&total).Error; err != nil {
        return nil, fmt.Errorf("failed to count files: %w", err)
    }
    
    // Apply sorting
    sortOrder := "DESC"
    if !params.SortDesc {
        sortOrder = "ASC"
    }
    query = query.Order(fmt.Sprintf("%s %s", params.SortBy, sortOrder))
    
    // Apply pagination
    offset := (params.Page - 1) * params.PageSize
    query = query.Offset(offset).Limit(params.PageSize)
    
    // Execute query
    if err := query.Find(&files).Error; err != nil {
        return nil, fmt.Errorf("failed to get files: %w", err)
    }
    
    // Calculate total pages
    totalPages := int(total) / params.PageSize
    if int(total)%params.PageSize > 0 {
        totalPages++
    }
    
    return &PaginatedResult{
        Data:       files,
        Total:      total,
        Page:       params.Page,
        PageSize:   params.PageSize,
        TotalPages: totalPages,
    }, nil
}

// Update mengupdate file record
func (r *fileRepository) Update(file *models.File) error {
    if err := r.db.Model(file).Updates(file).Error; err != nil {
        return fmt.Errorf("failed to update file: %w", err)
    }
    return nil
}

// Delete menghapus file secara permanent
func (r *fileRepository) Delete(id uint) error {
    if err := r.db.Unscoped().Delete(&models.File{}, id).Error; err != nil {
        return fmt.Errorf("failed to delete file: %w", err)
    }
    return nil
}

// SoftDelete menghapus file secara soft delete
func (r *fileRepository) SoftDelete(id uint) error {
    if err := r.db.Delete(&models.File{}, id).Error; err != nil {
        return fmt.Errorf("failed to soft delete file: %w", err)
    }
    return nil
}

// AttachToProduct menghubungkan file dengan product
func (r *fileRepository) AttachToProduct(productID, fileID uint, isPrimary bool) error {
    // Check if association already exists
    var count int64
    r.db.Model(&models.ProductFile{}).
        Where("product_id = ? AND file_id = ?", productID, fileID).
        Count(&count)
    
    if count > 0 {
        return errors.New("file already attached to product")
    }
    
    // If setting as primary, unset other primary files
    if isPrimary {
        r.db.Model(&models.ProductFile{}).
            Where("product_id = ?", productID).
            Update("is_primary", false)
    }
    
    // Create association
    productFile := &models.ProductFile{
        ProductID: productID,
        FileID:    fileID,
        IsPrimary: isPrimary,
    }
    
    if err := r.db.Create(productFile).Error; err != nil {
        return fmt.Errorf("failed to attach file to product: %w", err)
    }
    
    return nil
}

// DetachFromProduct menghapus hubungan file dengan product
func (r *fileRepository) DetachFromProduct(productID, fileID uint) error {
    result := r.db.Where("product_id = ? AND file_id = ?", productID, fileID).
        Delete(&models.ProductFile{})
    
    if result.Error != nil {
        return fmt.Errorf("failed to detach file from product: %w", result.Error)
    }
    
    if result.RowsAffected == 0 {
        return errors.New("file not attached to product")
    }
    
    return nil
}

// GetProductFiles mengambil semua files yang terhubung dengan product
func (r *fileRepository) GetProductFiles(productID uint) ([]models.File, error) {
    var files []models.File
    
    err := r.db.
        Joins("JOIN product_files ON files.id = product_files.file_id").
        Where("product_files.product_id = ?", productID).
        Order("product_files.is_primary DESC, product_files.sort_order ASC").
        Find(&files).Error
    
    if err != nil {
        return nil, fmt.Errorf("failed to get product files: %w", err)
    }
    
    return files, nil
}

// SetPrimaryFile set file sebagai primary untuk product
func (r *fileRepository) SetPrimaryFile(productID, fileID uint) error {
    // Start transaction
    tx := r.db.Begin()
    defer func() {
        if r := recover(); r != nil {
            tx.Rollback()
        }
    }()
    
    // Unset all primary files for the product
    if err := tx.Model(&models.ProductFile{}).
        Where("product_id = ?", productID).
        Update("is_primary", false).Error; err != nil {
        tx.Rollback()
        return fmt.Errorf("failed to unset primary files: %w", err)
    }
    
    // Set new primary file
    result := tx.Model(&models.ProductFile{}).
        Where("product_id = ? AND file_id = ?", productID, fileID).
        Update("is_primary", true)
    
    if result.Error != nil {
        tx.Rollback()
        return fmt.Errorf("failed to set primary file: %w", result.Error)
    }
    
    if result.RowsAffected == 0 {
        tx.Rollback()
        return errors.New("file not attached to product")
    }
    
    return tx.Commit().Error
}
```

Repository ini menyediakan:

- **Complete file CRUD operations** dengan proper error handling
- **Product-file associations** untuk real-world use cases
- **Search dan filtering capabilities** untuk file management
- **Primary file management** untuk products
- **Transaction support** untuk data consistency

## Step 5 - Create Upload Controller {#step-5}

Sekarang kita buat controller untuk handle HTTP requests yang berkaitan dengan file upload operations.

Buat file `controllers/upload_controller.go`:

```go
package controllers

import (
    "fmt"
    "net/http"
    "strconv"
    "strings"

    "github.com/gin-gonic/gin"
    "github.com/username/go-gin-auth-api/middlewares"
    "github.com/username/go-gin-auth-api/models"
    "github.com/username/go-gin-auth-api/repositories"
    "github.com/username/go-gin-auth-api/utils"
)

// UploadController struct untuk dependency injection
type UploadController struct {
    fileRepo    repositories.FileRepository
    productRepo repositories.ProductRepository
}

// NewUploadController membuat instance baru UploadController
func NewUploadController(fileRepo repositories.FileRepository, productRepo repositories.ProductRepository) *UploadController {
    return &UploadController{
        fileRepo:    fileRepo,
        productRepo: productRepo,
    }
}

// SingleUploadRequest struktur untuk single file upload
type SingleUploadRequest struct {
    IsPublic bool `form:"is_public"`
}

// MultipleUploadRequest struktur untuk multiple file upload
type MultipleUploadRequest struct {
    IsPublic bool `form:"is_public"`
}

// AttachFileRequest struktur untuk attach file ke product
type AttachFileRequest struct {
    ProductID uint `json:"product_id" binding:"required"`
    FileID    uint `json:"file_id" binding:"required"`
    IsPrimary bool `json:"is_primary"`
}

// UploadSingle handler untuk upload single file
func (uc *UploadController) UploadSingle(c *gin.Context) {
    // Get user ID dari context
    userID, exists := middlewares.GetUserIDFromContext(c)
    if !exists {
        c.JSON(http.StatusUnauthorized, gin.H{
            "error": "Unauthorized",
            "message": "User ID not found",
        })
        return
    }
    
    // Parse form request
    var req SingleUploadRequest
    if err := c.ShouldBind(&req); err != nil {
        c.JSON(http.StatusBadRequest, gin.H{
            "error": "Invalid form data",
            "message": err.Error(),
        })
        return
    }
    
    // Get uploaded file
    fileHeader, err := c.FormFile("file")
    if err != nil {
        c.JSON(http.StatusBadRequest, gin.H{
            "error": "No file uploaded",
            "message": "Please select a file to upload",
        })
        return
    }
    
    // Process upload
    uploadResult, err := utils.ProcessSingleUpload(fileHeader, userID)
    if err != nil {
        c.JSON(http.StatusBadRequest, gin.H{
            "error": "Upload failed",
            "message": err.Error(),
        })
        return
    }
    
    // Create file record in database
    file := &models.File{
        OriginalName: uploadResult.OriginalName,
        Filename:     uploadResult.Filename,
        FilePath:     uploadResult.FilePath,
        FileSize:     uploadResult.FileSize,
        MimeType:     uploadResult.MimeType,
        FileType:     string(uploadResult.FileType),
        Extension:    uploadResult.Extension,
        UserID:       userID,
        Width:        uploadResult.Width,
        Height:       uploadResult.Height,
        IsPublic:     req.IsPublic,
        IsProcessed:  true,
    }
    
    if err := uc.fileRepo.Create(file); err != nil {
        // Cleanup uploaded file jika database save gagal
        utils.DeleteFile(uploadResult.FilePath)
        
        c.JSON(http.StatusInternalServerError, gin.H{
            "error": "Failed to save file record",
            "message": "File uploaded but failed to save metadata",
        })
        return
    }
    
    // Generate response URL
    baseURL := getBaseURL(c)
    
    c.JSON(http.StatusCreated, gin.H{
        "message": "File uploaded successfully",
        "file":    file.ToResponse(baseURL),
    })
}

// UploadMultiple handler untuk upload multiple files
func (uc *UploadController) UploadMultiple(c *gin.Context) {
    // Get user ID dari context
    userID, exists := middlewares.GetUserIDFromContext(c)
    if !exists {
        c.JSON(http.StatusUnauthorized, gin.H{
            "error": "Unauthorized",
            "message": "User ID not found",
        })
        return
    }
    
    // Parse form request
    var req MultipleUploadRequest
    if err := c.ShouldBind(&req); err != nil {
        c.JSON(http.StatusBadRequest, gin.H{
            "error": "Invalid form data",
            "message": err.Error(),
        })
        return
    }
    
    // Get uploaded files
    form, err := c.MultipartForm()
    if err != nil {
        c.JSON(http.StatusBadRequest, gin.H{
            "error": "Invalid multipart form",
            "message": err.Error(),
        })
        return
    }
    
    fileHeaders := form.File["files"]
    if len(fileHeaders) == 0 {
        c.JSON(http.StatusBadRequest, gin.H{
            "error": "No files uploaded",
            "message": "Please select files to upload",
        })
        return
    }
    
    // Process uploads
    uploadResults, err := utils.ProcessMultipleUpload(fileHeaders, userID)
    if err != nil {
        c.JSON(http.StatusBadRequest, gin.H{
            "error": "Upload failed",
            "message": err.Error(),
        })
        return
    }
    
    // Process results dan save ke database
    var successFiles []models.FileResponse
    var failedFiles []map[string]interface{}
    
    baseURL := getBaseURL(c)
    
    for _, result := range uploadResults {
        if result.Error != nil {
            failedFiles = append(failedFiles, map[string]interface{}{
                "original_name": result.OriginalName,
                "error":         result.Error.Error(),
            })
            continue
        }
        
        // Create file record
        file := &models.File{
            OriginalName: result.OriginalName,
            Filename:     result.Filename,
            FilePath:     result.FilePath,
            FileSize:     result.FileSize,
            MimeType:     result.MimeType,
            FileType:     string(result.FileType),
            Extension:    result.Extension,
            UserID:       userID,
            Width:        result.Width,
            Height:       result.Height,
            IsPublic:     req.IsPublic,
            IsProcessed:  true,
        }
        
        if err := uc.fileRepo.Create(file); err != nil {
            // Cleanup uploaded file
            utils.DeleteFile(result.FilePath)
            
            failedFiles = append(failedFiles, map[string]interface{}{
                "original_name": result.OriginalName,
                "error":         "Failed to save file metadata",
            })
            continue
        }
        
        successFiles = append(successFiles, file.ToResponse(baseURL))
    }
    
    response := gin.H{
        "message":       fmt.Sprintf("Processed %d files", len(uploadResults)),
        "success_count": len(successFiles),
        "failed_count":  len(failedFiles),
        "success_files": successFiles,
    }
    
    if len(failedFiles) > 0 {
        response["failed_files"] = failedFiles
    }
    
    statusCode := http.StatusCreated
    if len(failedFiles) > 0 && len(successFiles) == 0 {
        statusCode = http.StatusBadRequest
    } else if len(failedFiles) > 0 {
        statusCode = http.StatusPartialContent
    }
    
    c.JSON(statusCode, response)
}

// GetMyFiles handler untuk mendapatkan files milik user
func (uc *UploadController) GetMyFiles(c *gin.Context) {
    // Get user ID dari context
    userID, exists := middlewares.GetUserIDFromContext(c)
    if !exists {
        c.JSON(http.StatusUnauthorized, gin.H{
            "error": "Unauthorized",
            "message": "User ID not found",
        })
        return
    }
    
    // Parse query parameters
    var params repositories.QueryParams
    if err := c.ShouldBindQuery(&params); err != nil {
        c.JSON(http.StatusBadRequest, gin.H{
            "error": "Invalid query parameters",
            "message": err.Error(),
        })
        return
    }
    
    // Validate pagination params
    if params.Page < 1 {
        params.Page = 1
    }
    if params.PageSize < 1 || params.PageSize > 100 {
        params.PageSize = 10
    }
    
    // Get files from repository
    result, err := uc.fileRepo.GetByUserID(userID, params)
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{
            "error": "Failed to fetch files",
            "message": "An error occurred while fetching your files",
        })
        return
    }
    
    // Convert to response format
    files := result.Data.([]models.File)
    baseURL := getBaseURL(c)
    fileResponses := make([]models.FileResponse, len(files))
    for i, file := range files {
        fileResponses[i] = file.ToResponse(baseURL)
    }
    
    result.Data = fileResponses
    
    c.JSON(http.StatusOK, result)
}

// GetFileByID handler untuk mendapatkan file berdasarkan ID
func (uc *UploadController) GetFileByID(c *gin.Context) {
    // Parse file ID
    id, err := strconv.ParseUint(c.Param("id"), 10, 32)
    if err != nil {
        c.JSON(http.StatusBadRequest, gin.H{
            "error": "Invalid file ID",
            "message": "File ID must be a valid number",
        })
        return
    }
    
    // Get file from repository
    file, err := uc.fileRepo.GetByID(uint(id))
    if err != nil {
        if err.Error() == "file not found" {
            c.JSON(http.StatusNotFound, gin.H{
                "error": "File not found",
                "message": "The requested file does not exist",
            })
        } else {
            c.JSON(http.StatusInternalServerError, gin.H{
                "error": "Failed to fetch file",
                "message": "An error occurred while fetching the file",
            })
        }
        return
    }
    
    baseURL := getBaseURL(c)
    
    c.JSON(http.StatusOK, gin.H{
        "file": file.ToResponse(baseURL),
    })
}

// DeleteFile handler untuk menghapus file
func (uc *UploadController) DeleteFile(c *gin.Context) {
    // Parse file ID
    id, err := strconv.ParseUint(c.Param("id"), 10, 32)
    if err != nil {
        c.JSON(http.StatusBadRequest, gin.H{
            "error": "Invalid file ID",
            "message": "File ID must be a valid number",
        })
        return
    }
    
    // Get user ID dari context
    userID, exists := middlewares.GetUserIDFromContext(c)
    if !exists {
        c.JSON(http.StatusUnauthorized, gin.H{
            "error": "Unauthorized",
            "message": "User ID not found",
        })
        return
    }
    
    // Get file untuk check ownership
    file, err := uc.fileRepo.GetByID(uint(id))
    if err != nil {
        if err.Error() == "file not found" {
            c.JSON(http.StatusNotFound, gin.H{
                "error": "File not found",
                "message": "The requested file does not exist",
            })
        } else {
            c.JSON(http.StatusInternalServerError, gin.H{
                "error": "Failed to fetch file",
                "message": "An error occurred while fetching the file",
            })
        }
        return
    }
    
    // Check ownership
    if file.UserID != userID {
        c.JSON(http.StatusForbidden, gin.H{
            "error": "Access denied",
            "message": "You don't have permission to delete this file",
        })
        return
    }
    
    // Delete physical file
    if err := utils.DeleteFile(file.FilePath); err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{
            "error": "Failed to delete file",
            "message": "File record deleted but physical file removal failed",
        })
        // Continue dengan database deletion
    }
    
    // Delete dari database
    if err := uc.fileRepo.SoftDelete(uint(id)); err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{
            "error": "Failed to delete file record",
            "message": "An error occurred while deleting the file record",
        })
        return
    }
    
    c.JSON(http.StatusOK, gin.H{
        "message": "File deleted successfully",
    })
}

// AttachFileToProduct handler untuk attach file ke product
func (uc *UploadController) AttachFileToProduct(c *gin.Context) {
    var req AttachFileRequest
    
    // Validate request
    if err := c.ShouldBindJSON(&req); err != nil {
        c.JSON(http.StatusBadRequest, gin.H{
            "error": "Validation failed",
            "message": err.Error(),
        })
        return
    }
    
    // Get user ID dari context
    userID, exists := middlewares.GetUserIDFromContext(c)
    if !exists {
        c.JSON(http.StatusUnauthorized, gin.H{
            "error": "Unauthorized",
            "message": "User ID not found",
        })
        return
    }
    
    // Check product ownership
    product, err := uc.productRepo.GetByIDAndUser(req.ProductID, userID)
    if err != nil {
        c.JSON(http.StatusNotFound, gin.H{
            "error": "Product not found",
            "message": "Product not found or you don't have permission to modify it",
        })
        return
    }
    
    // Check file ownership
    file, err := uc.fileRepo.GetByID(req.FileID)
    if err != nil {
        c.JSON(http.StatusNotFound, gin.H{
            "error": "File not found",
            "message": "The requested file does not exist",
        })
        return
    }
    
    if file.UserID != userID {
        c.JSON(http.StatusForbidden, gin.H{
            "error": "Access denied",
            "message": "You don't have permission to use this file",
        })
        return
    }
    
    // Attach file ke product
    if err := uc.fileRepo.AttachToProduct(req.ProductID, req.FileID, req.IsPrimary); err != nil {
        if strings.Contains(err.Error(), "already attached") {
            c.JSON(http.StatusConflict, gin.H{
                "error": "File already attached",
                "message": "This file is already attached to the product",
            })
        } else {
            c.JSON(http.StatusInternalServerError, gin.H{
                "error": "Failed to attach file",
                "message": "An error occurred while attaching the file to product",
            })
        }
        return
    }
    
    c.JSON(http.StatusOK, gin.H{
        "message": "File attached to product successfully",
        "product": product.ToResponse(),
        "file":    file.ToResponse(getBaseURL(c)),
    })
}

// DetachFileFromProduct handler untuk detach file dari product
func (uc *UploadController) DetachFileFromProduct(c *gin.Context) {
    var req AttachFileRequest
    
    // Validate request
    if err := c.ShouldBindJSON(&req); err != nil {
        c.JSON(http.StatusBadRequest, gin.H{
            "error": "Validation failed",
            "message": err.Error(),
        })
        return
    }
    
    // Get user ID dari context
    userID, exists := middlewares.GetUserIDFromContext(c)
    if !exists {
        c.JSON(http.StatusUnauthorized, gin.H{
            "error": "Unauthorized",
            "message": "User ID not found",
        })
        return
    }
    
    // Check product ownership
    _, err := uc.productRepo.GetByIDAndUser(req.ProductID, userID)
    if err != nil {
        c.JSON(http.StatusNotFound, gin.H{
            "error": "Product not found",
            "message": "Product not found or you don't have permission to modify it",
        })
        return
    }
    
    // Detach file dari product
    if err := uc.fileRepo.DetachFromProduct(req.ProductID, req.FileID); err != nil {
        if strings.Contains(err.Error(), "not attached") {
            c.JSON(http.StatusNotFound, gin.H{
                "error": "File not attached",
                "message": "This file is not attached to the product",
            })
        } else {
            c.JSON(http.StatusInternalServerError, gin.H{
                "error": "Failed to detach file",
                "message": "An error occurred while detaching the file from product",
            })
        }
        return
    }
    
    c.JSON(http.StatusOK, gin.H{
        "message": "File detached from product successfully",
    })
}

// GetProductFiles handler untuk mendapatkan files yang attached ke product
func (uc *UploadController) GetProductFiles(c *gin.Context) {
    // Parse product ID
    id, err := strconv.ParseUint(c.Param("id"), 10, 32)
    if err != nil {
        c.JSON(http.StatusBadRequest, gin.H{
            "error": "Invalid product ID",
            "message": "Product ID must be a valid number",
        })
        return
    }
    
    // Get files
    files, err := uc.fileRepo.GetProductFiles(uint(id))
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{
            "error": "Failed to fetch product files",
            "message": "An error occurred while fetching product files",
        })
        return
    }
    
    // Convert to response format
    baseURL := getBaseURL(c)
    fileResponses := make([]models.FileResponse, len(files))
    for i, file := range files {
        fileResponses[i] = file.ToResponse(baseURL)
    }
    
    c.JSON(http.StatusOK, gin.H{
        "files": fileResponses,
    })
}

// getBaseURL helper untuk generate base URL
func getBaseURL(c *gin.Context) string {
    scheme := "http"
    if c.Request.TLS != nil {
        scheme = "https"
    }
    
    return fmt.Sprintf("%s://%s", scheme, c.Request.Host)
}
```

Controller ini mengimplementasikan:

- **Single dan multiple file upload** dengan proper validation
- **File management** dengan ownership checks
- **Product-file associations** untuk real-world use cases
- **Comprehensive error handling** dengan meaningful responses
- **Security measures** untuk access control

## Step 6 - Update Product Model untuk File Relations {#step-6}

Sekarang kita perlu update Product model untuk include file relationships dan menambahkan methods untuk easier file access.

Update file `models/product.go`, tambahkan di bagian struct Product:

```go
// Update existing Product struct - tambahkan fields berikut:
type Product struct {
    // ... existing fields ...
    ID          uint           `json:"id" gorm:"primaryKey"`
    Name        string         `json:"name" gorm:"not null;size:200"`
    Description string         `json:"description" gorm:"type:text"`
    Price       float64        `json:"price" gorm:"not null;check:price >= 0"`
    Stock       int            `json:"stock" gorm:"default:0;check:stock >= 0"`
    SKU         string         `json:"sku" gorm:"uniqueIndex;size:50"`
    Category    string         `json:"category" gorm:"size:100;index"`
    IsActive    bool           `json:"is_active" gorm:"default:true;index"`
    UserID      uint           `json:"user_id" gorm:"not null;index"`
    User        User           `json:"user,omitempty" gorm:"foreignKey:UserID;constraint:OnDelete:CASCADE"`
    
    // TAMBAHKAN RELATIONSHIP UNTUK FILES
    Files       []File         `json:"files,omitempty" gorm:"many2many:product_files;"`
    
    CreatedAt   time.Time      `json:"created_at"`
    UpdatedAt   time.Time      `json:"updated_at"`
    DeletedAt   gorm.DeletedAt `json:"deleted_at,omitempty" gorm:"index"`
}

// Update ProductResponse struct juga
type ProductResponse struct {
    ID          uint       `json:"id"`
    Name        string     `json:"name"`
    Description string     `json:"description"`
    Price       float64    `json:"price"`
    Stock       int        `json:"stock"`
    SKU         string     `json:"sku"`
    Category    string     `json:"category"`
    IsActive    bool       `json:"is_active"`
    UserID      uint       `json:"user_id"`
    User        PublicUser `json:"owner,omitempty"`
    
    // TAMBAHKAN FILE FIELDS
    Files       []FileResponse `json:"files,omitempty"`
    PrimaryFile *FileResponse  `json:"primary_file,omitempty"`
    
    CreatedAt   time.Time  `json:"created_at"`
    UpdatedAt   time.Time  `json:"updated_at"`
}

// Update ToResponse method
func (p *Product) ToResponse() ProductResponse {
    response := ProductResponse{
        ID:          p.ID,
        Name:        p.Name,
        Description: p.Description,
        Price:       p.Price,
        Stock:       p.Stock,
        SKU:         p.SKU,
        Category:    p.Category,
        IsActive:    p.IsActive,
        UserID:      p.UserID,
        CreatedAt:   p.CreatedAt,
        UpdatedAt:   p.UpdatedAt,
    }
    
    // Include user data if loaded
    if p.User.ID != 0 {
        response.User = p.User.ToPublicUser()
    }
    
    // TAMBAHKAN FILE HANDLING
    // Include files if loaded
    if len(p.Files) > 0 {
        baseURL := "http://localhost:8080" // TODO: get from config
        response.Files = make([]FileResponse, len(p.Files))
        
        for i, file := range p.Files {
            response.Files[i] = file.ToResponse(baseURL)
        }
        
        // Find primary file
        for _, file := range p.Files {
            // Check if this is primary file (you'll need to query ProductFile table)
            // For now, we'll use the first file as primary
            if response.PrimaryFile == nil {
                fileResponse := file.ToResponse(baseURL)
                response.PrimaryFile = &fileResponse
                break
            }
        }
    }
    
    return response
}

// TAMBAHKAN METHOD BARU UNTUK FILE MANAGEMENT
// GetPrimaryFile mendapatkan primary file untuk product
func (p *Product) GetPrimaryFile() *File {
    // This will need to be implemented with proper query
    // untuk sekarang return nil, akan diimplementasi di repository
    return nil
}

// HasFiles mengecek apakah product memiliki files
func (p *Product) HasFiles() bool {
    return len(p.Files) > 0
}

// GetFilesByType mendapatkan files berdasarkan type
func (p *Product) GetFilesByType(fileType string) []File {
    var filteredFiles []File
    for _, file := range p.Files {
        if file.FileType == fileType {
            filteredFiles = append(filteredFiles, file)
        }
    }
    return filteredFiles
}
```

Juga buat file `models/file_upload.go` untuk request/response structures yang spesifik untuk upload:

```go
package models

// UploadResponse struktur untuk response upload
type UploadResponse struct {
    Message     string         `json:"message"`
    File        *FileResponse  `json:"file,omitempty"`
    Files       []FileResponse `json:"files,omitempty"`
    SuccessCount int           `json:"success_count,omitempty"`
    FailedCount  int           `json:"failed_count,omitempty"`
    FailedFiles []FailedFile   `json:"failed_files,omitempty"`
}

// FailedFile struktur untuk files yang gagal upload
type FailedFile struct {
    OriginalName string `json:"original_name"`
    Error        string `json:"error"`
}

// FileUploadStats struktur untuk statistik upload
type FileUploadStats struct {
    TotalFiles    int    `json:"total_files"`
    TotalSize     int64  `json:"total_size"`
    TotalSizeFormatted string `json:"total_size_formatted"`
    ImageFiles    int    `json:"image_files"`
    DocumentFiles int    `json:"document_files"`
    OtherFiles    int    `json:"other_files"`
}

// ProductWithFiles extended product response dengan file details
type ProductWithFiles struct {
    ProductResponse
    FileStats FileUploadStats `json:"file_stats"`
}
```

Update ini menambahkan:

- **Many-to-many relationship** antara Product dan File
- **File-related methods** untuk easier access
- **Enhanced response structures** dengan file information
- **Statistics tracking** untuk file uploads

## Step 7 - Update Routes {#step-7}

Sekarang kita update routes untuk menambahkan endpoints untuk file upload operations. Update file `routes/routes.go`:

```go
package routes

import (
    "github.com/gin-gonic/gin"
    "github.com/username/go-gin-auth-api/controllers"
    "github.com/username/go-gin-auth-api/database"
    "github.com/username/go-gin-auth-api/middlewares"
    "github.com/username/go-gin-auth-api/repositories"
)

// SetupRoutes mengkonfigurasi semua routes aplikasi
func SetupRoutes(router *gin.Engine) {
    // Initialize repositories
    productRepo := repositories.NewProductRepository(database.DB)
    fileRepo := repositories.NewFileRepository(database.DB) // TAMBAHKAN INI
    
    // Initialize controllers dengan dependency injection
    productController := controllers.NewProductController(productRepo)
    uploadController := controllers.NewUploadController(fileRepo, productRepo) // TAMBAHKAN INI
    
    // Health check endpoint
    router.GET("/health", controllers.HealthCheck)

    // API version grouping
    v1 := router.Group("/api/v1")
    {
        // Public auth routes
        auth := v1.Group("/auth")
        {
            auth.POST("/register", controllers.Register)
            auth.POST("/login", controllers.Login)
        }

        // Protected routes
        protected := v1.Group("/")
        protected.Use(middlewares.AuthMiddleware())
        {
            // User routes
            protected.GET("/profile", controllers.GetProfile)
            protected.POST("/auth/refresh", controllers.RefreshToken)
            
            // Product routes - CRUD operations
            products := protected.Group("/products")
            {
                products.POST("", productController.CreateProduct)
                products.GET("", productController.GetAllProducts)
                products.GET("/my", productController.GetMyProducts)
                products.GET("/:id", productController.GetProductByID)
                products.PUT("/:id", productController.UpdateProduct)
                products.DELETE("/:id", productController.DeleteProduct)
                products.GET("/categories", productController.GetProductCategories)
                
                // TAMBAHKAN PRODUCT FILE ROUTES
                products.GET("/:id/files", uploadController.GetProductFiles)
            }
            
            // TAMBAHKAN FILE UPLOAD ROUTES
            files := protected.Group("/files")
            {
                // Upload endpoints
                files.POST("/upload", uploadController.UploadSingle)
                files.POST("/upload/multiple", uploadController.UploadMultiple)
                
                // File management
                files.GET("/my", uploadController.GetMyFiles)
                files.GET("/:id", uploadController.GetFileByID)
                files.DELETE("/:id", uploadController.DeleteFile)
                
                // Product-file associations
                files.POST("/attach", uploadController.AttachFileToProduct)
                files.POST("/detach", uploadController.DetachFileFromProduct)
            }
        }
        
        // TAMBAHKAN PUBLIC FILE SERVING ROUTES (tanpa auth)
        publicFiles := v1.Group("/files")
        {
            // File serving endpoints - akan diimplementasi di step berikutnya
            publicFiles.GET("/serve/:filename", controllers.ServeFile)
            publicFiles.GET("/thumbnail/:filename", controllers.ServeThumbnail)
        }
        
        // Public product routes (existing)
        publicProducts := v1.Group("/products")
        {
            publicProducts.GET("/public", productController.GetAllProducts)
            publicProducts.GET("/public/:id", productController.GetProductByID)
        }
    }

    // 404 handler
    router.NoRoute(func(c *gin.Context) {
        c.JSON(404, gin.H{
            "error": "Not Found",
            "message": "The requested endpoint does not exist",
        })
    })
}

// SetupMiddlewares tetap sama seperti sebelumnya
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

Routes yang ditambahkan:

**Protected File Routes (Perlu Authentication):**

- `POST /api/v1/files/upload` - Upload single file
- `POST /api/v1/files/upload/multiple` - Upload multiple files
- `GET /api/v1/files/my` - Get user's files
- `GET /api/v1/files/:id` - Get file by ID
- `DELETE /api/v1/files/:id` - Delete file
- `POST /api/v1/files/attach` - Attach file to product
- `POST /api/v1/files/detach` - Detach file from product
- `GET /api/v1/products/:id/files` - Get product files

**Public File Routes (Tanpa Authentication):**

- `GET /api/v1/files/serve/:filename` - Serve file
- `GET /api/v1/files/thumbnail/:filename` - Serve thumbnail

## Step 8 - Create File Serving Middleware {#step-8}

Sekarang kita buat controller untuk serve files secara aman dengan access control dan streaming support.

Buat file `controllers/file_serve_controller.go`:

```go
package controllers

import (
    "fmt"
    "io"
    "net/http"
    "os"
    "path/filepath"
    "strconv"
    "strings"

    "github.com/gin-gonic/gin"
    "github.com/username/go-gin-auth-api/database"
    "github.com/username/go-gin-auth-api/models"
    "github.com/username/go-gin-auth-api/repositories"
    "github.com/username/go-gin-auth-api/utils"
    "github.com/disintegration/imaging"
)

// ServeFile handler untuk serve uploaded files
func ServeFile(c *gin.Context) {
    filename := c.Param("filename")
    if filename == "" {
        c.JSON(http.StatusBadRequest, gin.H{
            "error": "Invalid filename",
            "message": "Filename is required",
        })
        return
    }
    
    // Sanitize filename untuk security
    filename = filepath.Base(filename)
    
    // Get file record dari database
    fileRepo := repositories.NewFileRepository(database.DB)
    file, err := fileRepo.GetByFilename(filename)
    if err != nil {
        c.JSON(http.StatusNotFound, gin.H{
            "error": "File not found",
            "message": "The requested file does not exist",
        })
        return
    }
    
    // Check if file is public atau user memiliki akses
    if !file.IsPublic {
        // Check authentication untuk private files
        userID, exists := getUserIDFromToken(c)
        if !exists || file.UserID != userID {
            c.JSON(http.StatusForbidden, gin.H{
                "error": "Access denied",
                "message": "You don't have permission to access this file",
            })
            return
        }
    }
    
    // Check if physical file exists
    if _, err := os.Stat(file.FilePath); os.IsNotExist(err) {
        c.JSON(http.StatusNotFound, gin.H{
            "error": "File not found",
            "message": "Physical file does not exist",
        })
        return
    }
    
    // Set appropriate headers
    setFileHeaders(c, file)
    
    // Serve file dengan streaming support
    serveFileWithRange(c, file.FilePath)
}

// ServeThumbnail handler untuk serve thumbnails
func ServeThumbnail(c *gin.Context) {
    filename := c.Param("filename")
    if filename == "" {
        c.JSON(http.StatusBadRequest, gin.H{
            "error": "Invalid filename",
            "message": "Filename is required",
        })
        return
    }
    
    // Sanitize filename
    filename = filepath.Base(filename)
    
    // Get file record
    fileRepo := repositories.NewFileRepository(database.DB)
    file, err := fileRepo.GetByFilename(filename)
    if err != nil {
        c.JSON(http.StatusNotFound, gin.H{
            "error": "File not found",
            "message": "The requested file does not exist",
        })
        return
    }
    
    // Only serve thumbnails for images
    if file.FileType != "image" {
        c.JSON(http.StatusBadRequest, gin.H{
            "error": "Not an image",
            "message": "Thumbnails are only available for images",
        })
        return
    }
    
    // Check access (sama seperti file original)
    if !file.IsPublic {
        userID, exists := getUserIDFromToken(c)
        if !exists || file.UserID != userID {
            c.JSON(http.StatusForbidden, gin.H{
                "error": "Access denied",
                "message": "You don't have permission to access this file",
            })
            return
        }
    }
    
    // Generate thumbnail path
    thumbnailPath := utils.GetThumbnailPath(file.FilePath)
    
    // Check if thumbnail exists
    if _, err := os.Stat(thumbnailPath); os.IsNotExist(err) {
        // Generate thumbnail on-the-fly jika belum ada
        if err := generateThumbnailOnDemand(file.FilePath, thumbnailPath); err != nil {
            c.JSON(http.StatusInternalServerError, gin.H{
                "error": "Thumbnail generation failed",
                "message": "Could not generate thumbnail for this image",
            })
            return
        }
    }
    
    // Set headers untuk thumbnail
    c.Header("Content-Type", file.MimeType)
    c.Header("Cache-Control", "public, max-age=86400") // Cache 24 hours
    c.Header("Content-Disposition", fmt.Sprintf("inline; filename=\"thumb_%s\"", file.OriginalName))
    
    // Serve thumbnail
    c.File(thumbnailPath)
}

// serveFileWithRange serve file dengan HTTP Range support untuk large files
func serveFileWithRange(c *gin.Context, filePath string) {
    file, err := os.Open(filePath)
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{
            "error": "Failed to open file",
            "message": "Could not open the requested file",
        })
        return
    }
    defer file.Close()
    
    // Get file info
    fileInfo, err := file.Stat()
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{
            "error": "Failed to get file info",
            "message": "Could not get file information",
        })
        return
    }
    
    fileSize := fileInfo.Size()
    
    // Handle Range requests untuk streaming
    rangeHeader := c.GetHeader("Range")
    if rangeHeader != "" {
        handleRangeRequest(c, file, fileSize, rangeHeader)
        return
    }
    
    // Normal file serving
    c.Header("Content-Length", strconv.FormatInt(fileSize, 10))
    c.Header("Accept-Ranges", "bytes")
    
    // Copy file content to response
    io.Copy(c.Writer, file)
}

// handleRangeRequest handle HTTP Range requests
func handleRangeRequest(c *gin.Context, file *os.File, fileSize int64, rangeHeader string) {
    // Parse range header (contoh: "bytes=0-1023")
    if !strings.HasPrefix(rangeHeader, "bytes=") {
        c.Status(http.StatusRequestedRangeNotSatisfiable)
        return
    }
    
    rangeSpec := strings.TrimPrefix(rangeHeader, "bytes=")
    rangeParts := strings.Split(rangeSpec, "-")
    
    if len(rangeParts) != 2 {
        c.Status(http.StatusRequestedRangeNotSatisfiable)
        return
    }
    
    var start, end int64
    var err error
    
    // Parse start
    if rangeParts[0] == "" {
        start = 0
    } else {
        start, err = strconv.ParseInt(rangeParts[0], 10, 64)
        if err != nil {
            c.Status(http.StatusRequestedRangeNotSatisfiable)
            return
        }
    }
    
    // Parse end
    if rangeParts[1] == "" {
        end = fileSize - 1
    } else {
        end, err = strconv.ParseInt(rangeParts[1], 10, 64)
        if err != nil {
            c.Status(http.StatusRequestedRangeNotSatisfiable)
            return
        }
    }
    
    // Validate range
    if start > end || start >= fileSize || end >= fileSize {
        c.Status(http.StatusRequestedRangeNotSatisfiable)
        return
    }
    
    contentLength := end - start + 1
    
    // Set partial content headers
    c.Header("Content-Range", fmt.Sprintf("bytes %d-%d/%d", start, end, fileSize))
    c.Header("Content-Length", strconv.FormatInt(contentLength, 10))
    c.Header("Accept-Ranges", "bytes")
    c.Status(http.StatusPartialContent)
    
    // Seek to start position
    file.Seek(start, 0)
    
    // Copy specified range
    io.CopyN(c.Writer, file, contentLength)
}

// setFileHeaders set appropriate headers untuk file serving
func setFileHeaders(c *gin.Context, file *models.File) {
    // MIME type
    c.Header("Content-Type", file.MimeType)
    
    // Cache control berdasarkan file type
    if file.FileType == "image" {
        c.Header("Cache-Control", "public, max-age=86400") // 24 hours untuk images
    } else {
        c.Header("Cache-Control", "private, max-age=3600") // 1 hour untuk files lain
    }
    
    // Security headers
    c.Header("X-Content-Type-Options", "nosniff")
    
    // Content disposition
    if isInlineViewable(file.MimeType) {
        c.Header("Content-Disposition", fmt.Sprintf("inline; filename=\"%s\"", file.OriginalName))
    } else {
        c.Header("Content-Disposition", fmt.Sprintf("attachment; filename=\"%s\"", file.OriginalName))
    }
    
    // Last modified
    if fileInfo, err := os.Stat(file.FilePath); err == nil {
        c.Header("Last-Modified", fileInfo.ModTime().UTC().Format(http.TimeFormat))
    }
}

// isInlineViewable check apakah file bisa ditampilkan di browser
func isInlineViewable(mimeType string) bool {
    inlineTypes := []string{
        "image/jpeg", "image/png", "image/gif", "image/webp",
        "text/plain", "application/pdf",
    }
    
    for _, inlineType := range inlineTypes {
        if mimeType == inlineType {
            return true
        }
    }
    
    return false
}

// getUserIDFromToken extract user ID dari JWT token (optional)
func getUserIDFromToken(c *gin.Context) (uint, bool) {
    // Try to get from context (jika sudah melalui auth middleware)
    if userID, exists := c.Get("userID"); exists {
        if id, ok := userID.(uint); ok {
            return id, true
        }
    }
    
    // Try to parse token manually untuk public endpoints
    authHeader := c.GetHeader("Authorization")
    if authHeader == "" {
        return 0, false
    }
    
    tokenParts := strings.Split(authHeader, " ")
    if len(tokenParts) != 2 || tokenParts[0] != "Bearer" {
        return 0, false
    }
    
    // TODO: Parse JWT token here if needed untuk public file access
    // For now, return false untuk public endpoints
    return 0, false
}

// generateThumbnailOnDemand generate thumbnail on-demand jika belum ada
func generateThumbnailOnDemand(originalPath, thumbnailPath string) error {
    // Pastikan directory thumbnail ada
    if err := utils.EnsureDirectoryExists(filepath.Dir(thumbnailPath)); err != nil {
        return err
    }
    
    // Generate thumbnail menggunakan imaging library
    img, err := imaging.Open(originalPath)
    if err != nil {
        return fmt.Errorf("failed to open image: %w", err)
    }
    
    // Create 300x300 thumbnail
    thumbnail := imaging.Fit(img, 300, 300, imaging.Lanczos)
    
    // Save thumbnail
    if err := imaging.Save(thumbnail, thumbnailPath); err != nil {
        return fmt.Errorf("failed to save thumbnail: %w", err)
    }
    
    return nil
}
```

File serving controller ini menyediakan:

- **Secure file serving** dengan access control
- **HTTP Range support** untuk streaming large files
- **Automatic thumbnail generation** on-demand
- **Proper caching headers** untuk performance
- **Security measures** untuk prevent directory traversal

## Step 9 - Update Main Application {#step-9}

Update `main.go` untuk include File dan ProductFile models dalam auto migration dan initialize storage:

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
    "github.com/username/go-gin-auth-api/utils" // TAMBAHKAN IMPORT UTILS
)

func init() {
    // Load .env file in development
    if os.Getenv("GO_ENV") != "production" {
        if err := godotenv.Load(); err != nil {
            log.Printf("Warning: .env file not found")
        }
    }
    
    // TAMBAHKAN STORAGE INITIALIZATION
    // Initialize storage directories
    if err := utils.InitializeStorage(); err != nil {
        log.Printf("Warning: Failed to initialize storage directories: %v", err)
    } else {
        log.Println("✅ Storage directories initialized")
    }
}

func main() {
    // Set Gin mode
    ginMode := os.Getenv("GIN_MODE")
    if ginMode == "" {
        ginMode = gin.DebugMode
    }
    gin.SetMode(ginMode)

    // Connect to database
    database.ConnectDatabase()
    
    // TAMBAHKAN FILE MODELS KE AUTO MIGRATION
    // Auto migrate models - tambahkan File dan ProductFile models
    if err := database.DB.AutoMigrate(
        &models.User{}, 
        &models.Product{}, 
        &models.File{}, 
        &models.ProductFile{},
    ); err != nil {
        log.Fatal("Failed to migrate database:", err)
    }
    log.Println("✅ Database migration completed")

    // TAMBAHKAN CLEANUP SCHEDULER UNTUK TEMP FILES
    // Start cleanup scheduler untuk temporary files
    go func() {
        ticker := time.NewTicker(24 * time.Hour) // Cleanup setiap 24 jam
        defer ticker.Stop()
        
        for {
            select {
            case <-ticker.C:
                if err := utils.CleanupTempFiles(); err != nil {
                    log.Printf("Cleanup temp files failed: %v", err)
                } else {
                    log.Println("✅ Temp files cleanup completed")
                }
            }
        }
    }()

    // Setup Gin router
    router := gin.New()
    
    // Setup global middlewares
    routes.SetupMiddlewares(router)
    
    // Setup routes
    routes.SetupRoutes(router)

    // Get port from environment
    port := os.Getenv("PORT")
    if port == "" {
        port = "8080"
    }

    // Create HTTP server dengan increased limits untuk file uploads
    srv := &http.Server{
        Addr:           ":" + port,
        Handler:        router,
        ReadTimeout:    30 * time.Second,  // Increased untuk file uploads
        WriteTimeout:   30 * time.Second,  // Increased untuk file serving
        IdleTimeout:    120 * time.Second,
        MaxHeaderBytes: 32 << 20, // 32 MB untuk large file uploads
    }

    // Start server in goroutine
    go func() {
        log.Printf("🚀 Server starting on port %s", port)
        log.Printf("📍 API endpoints available at http://localhost:%s/api/v1", port)
        log.Printf("📝 Product endpoints ready for CRUD operations")
        log.Printf("📁 File upload endpoints ready") // TAMBAHKAN LOG UNTUK FILE UPLOAD
        
        if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
            log.Fatalf("Failed to start server: %v", err)
        }
    }()

    // Wait for interrupt signal
    quit := make(chan os.Signal, 1)
    signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
    <-quit
    
    log.Println("⚠️  Shutting down server...")

    // Graceful shutdown
    ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
    defer cancel()
    
    if err := srv.Shutdown(ctx); err != nil {
        log.Fatal("Server forced to shutdown:", err)
    }

    // Close database
    database.CloseDatabase()
    
    log.Println("✅ Server exited properly")
}
```

Perubahan pada main.go:

- **Storage initialization** pada init function
- **File dan ProductFile models** ditambahkan ke auto migration
- **Cleanup scheduler** untuk temporary files
- **Increased server timeouts** untuk handle file uploads
- **Larger MaxHeaderBytes** untuk support large file uploads
- **Additional startup logs** untuk file upload endpoints

## Step 10 - Uji Coba Upload Operations {#step-10}

Sekarang mari kita test semua file upload operations yang sudah kita implementasikan. Pastikan aplikasi sudah berjalan dengan benar.

Jalankan aplikasi:

```bash
go run main.go
```

Output yang diharapkan:

```
2024/03/15 10:00:00 ✅ Storage directories initialized
2024/03/15 10:00:00 ✅ Database connected successfully
2024/03/15 10:00:00 ✅ Database migration completed
2024/03/15 10:00:00 🚀 Server starting on port 8080
2024/03/15 10:00:00 📍 API endpoints available at http://localhost:8080/api/v1
2024/03/15 10:00:00 📝 Product endpoints ready for CRUD operations
2024/03/15 10:00:00 📁 File upload endpoints ready
```

### Uji Coba Single File Upload {#uji-coba-1}

Mari kita test upload single file pertama:

1. Method: **POST**
2. URL: `http://localhost:8080/api/v1/files/upload`
3. Headers:
   - `Authorization: Bearer <your_jwt_token>`
4. Body: 
   - Type: **form-data**
   - Key: `file` (File type) - Pilih file image (JPG/PNG)
   - Key: `is_public` (Text) - Value: `true`

Expected response (201 Created):

```json
{
    "message": "File uploaded successfully",
    "file": {
        "id": 1,
        "original_name": "sample-image.jpg",
        "filename": "sample-image_1710486000_12345678.jpg",
        "file_size": 245760,
        "file_size_formatted": "240.0 KB",
        "mime_type": "image/jpeg",
        "file_type": "image",
        "extension": "jpg",
        "user_id": 1,
        "width": 1920,
        "height": 1080,
        "is_public": true,
        "is_processed": true,
        "url": "http://localhost:8080/api/v1/files/serve/sample-image_1710486000_12345678.jpg",
        "thumbnail_url": "http://localhost:8080/api/v1/files/thumbnail/sample-image_1710486000_12345678.jpg",
        "created_at": "2024-03-15T10:00:00Z",
        "updated_at": "2024-03-15T10:00:00Z"
    }
}
```

Test upload document juga:

- Upload file PDF atau DOC dengan `is_public: false`

### Uji Coba Multiple Files Upload {#uji-coba-2}

Test upload multiple files sekaligus:

1. Method: **POST**
2. URL: `http://localhost:8080/api/v1/files/upload/multiple`
3. Headers:
   - `Authorization: Bearer <your_jwt_token>`
4. Body:
   - Type: **form-data**
   - Key: `files` (File type) - Pilih multiple files (images dan documents)
   - Key: `is_public` (Text) - Value: `false`

Expected response (201 Created atau 207 Partial Content):

```json
{
    "message": "Processed 3 files",
    "success_count": 2,
    "failed_count": 1,
    "success_files": [
        {
            "id": 2,
            "original_name": "product-image-1.png",
            "filename": "product-image-1_1710486300_87654321.png",
            "file_size": 512000,
            "file_size_formatted": "500.0 KB",
            "mime_type": "image/png",
            "file_type": "image",
            "extension": "png",
            "user_id": 1,
            "width": 800,
            "height": 600,
            "is_public": false,
            "is_processed": true,
            "url": "http://localhost:8080/api/v1/files/serve/product-image-1_1710486300_87654321.png",
            "thumbnail_url": "http://localhost:8080/api/v1/files/thumbnail/product-image-1_1710486300_87654321.png",
            "created_at": "2024-03-15T10:05:00Z",
            "updated_at": "2024-03-15T10:05:00Z"
        },
        {
            "id": 3,
            "original_name": "manual.pdf",
            "filename": "manual_1710486300_11223344.pdf",
            "file_size": 1048576,
            "file_size_formatted": "1.0 MB",
            "mime_type": "application/pdf",
            "file_type": "document",
            "extension": "pdf",
            "user_id": 1,
            "is_public": false,
            "is_processed": true,
            "url": "http://localhost:8080/api/v1/files/serve/manual_1710486300_11223344.pdf",
            "created_at": "2024-03-15T10:05:00Z",
            "updated_at": "2024-03-15T10:05:00Z"
        }
    ],
    "failed_files": [
        {
            "original_name": "invalid-file.exe",
            "error": "file type .exe is not allowed"
        }
    ]
}
```

### Uji Coba Image Upload dengan Processing {#uji-coba-3}

Test image upload dengan automatic processing:

Upload image yang besar (>2MB) dan perhatikan bahwa sistem akan:

- Auto-resize jika terlalu besar
- Generate thumbnail
- Compress dengan quality setting
- Set width dan height metadata

Test juga dengan berbagai format image:

- JPG, PNG, GIF, WebP

### Uji Coba File Management {#uji-coba-4}

**1. Get My Files dengan Pagination**

- Method: **GET**
- URL: `http://localhost:8080/api/v1/files/my?page=1&page_size=10&search=product&category=image`
- Headers: `Authorization: Bearer <your_jwt_token>`

**2. Get Single File**

- Method: **GET**
- URL: `http://localhost:8080/api/v1/files/1`
- Headers: `Authorization: Bearer <your_jwt_token>`

**3. Delete File**

- Method: **DELETE**
- URL: `http://localhost:8080/api/v1/files/3`
- Headers: `Authorization: Bearer <your_jwt_token>`

Expected response:

```json
{
    "message": "File deleted successfully"
}
```

**4. Attach File to Product**

Pertama, pastikan Anda memiliki product dari tutorial Part 2. Kemudian:

- Method: **POST**
- URL: `http://localhost:8080/api/v1/files/attach`
- Headers: 
  - `Authorization: Bearer <your_jwt_token>`
  - `Content-Type: application/json`
- Body:

```json
{
    "product_id": 1,
    "file_id": 2,
    "is_primary": true
}
```

**5. Get Product Files**

- Method: **GET**
- URL: `http://localhost:8080/api/v1/products/1/files`
- Headers: `Authorization: Bearer <your_jwt_token>`

Expected response:

```json
{
    "files": [
        {
            "id": 2,
            "original_name": "product-image-1.png",
            "filename": "product-image-1_1710486300_87654321.png",
            "file_size": 512000,
            "file_size_formatted": "500.0 KB",
            "mime_type": "image/png",
            "file_type": "image",
            "extension": "png",
            "user_id": 1,
            "width": 800,
            "height": 600,
            "is_public": false,
            "is_processed": true,
            "url": "http://localhost:8080/api/v1/files/serve/product-image-1_1710486300_87654321.png",
            "thumbnail_url": "http://localhost:8080/api/v1/files/thumbnail/product-image-1_1710486300_87654321.png",
            "created_at": "2024-03-15T10:05:00Z",
            "updated_at": "2024-03-15T10:05:00Z"
        }
    ]
}
```

**6. File Serving Test**

Test file serving dengan mengakses URL dari response:

- Original file: `http://localhost:8080/api/v1/files/serve/product-image-1_1710486300_87654321.png`
- Thumbnail: `http://localhost:8080/api/v1/files/thumbnail/product-image-1_1710486300_87654321.png`

File ini bisa diakses di browser atau menggunakan GET request di Postman.

### Uji Coba Security Validations {#uji-coba-5}

**1. Test File Size Limit**
Upload file yang lebih besar dari `MAX_FILE_SIZE` (default 10MB):

Expected response (400 Bad Request):

```json
{
    "error": "Upload failed",
    "message": "file size 15.2 MB exceeds maximum allowed size 10.0 MB"
}
```

**2. Test Invalid File Types**
Upload file dengan extension yang tidak diizinkan (.exe, .bat, .sh):

Expected response (400 Bad Request):

```json
{
    "error": "Upload failed",
    "message": "file type .exe is not allowed"
}
```

**3. Test Too Many Files**
Upload lebih dari `MAX_FILES_PER_REQUEST` (default 5) files:

Expected response (400 Bad Request):

```json
{
    "error": "Upload failed",
    "message": "too many files: maximum 5 files allowed"
}
```

**4. Test Access Control**

- Upload private file (is_public: false)
- Logout atau gunakan token user lain
- Try to access file URL

Expected: 403 Forbidden untuk private files

**5. Test File Ownership**

- Upload file dengan user A
- Login dengan user B
- Try to delete file dari user A

Expected: 403 Forbidden

**Testing dengan CURL Commands:**

Untuk testing yang lebih comprehensive, Anda juga bisa menggunakan CURL:

```bash
# Upload single file
curl -X POST \
  http://localhost:8080/api/v1/files/upload \
  -H 'Authorization: Bearer YOUR_JWT_TOKEN' \
  -F 'file=@/path/to/your/image.jpg' \
  -F 'is_public=true'

# Upload multiple files
curl -X POST \
  http://localhost:8080/api/v1/files/upload/multiple \
  -H 'Authorization: Bearer YOUR_JWT_TOKEN' \
  -F 'files=@/path/to/image1.jpg' \
  -F 'files=@/path/to/image2.png' \
  -F 'files=@/path/to/document.pdf' \
  -F 'is_public=false'

# Get file (with range support untuk large files)
curl -X GET \
  http://localhost:8080/api/v1/files/serve/filename.jpg \
  -H 'Range: bytes=0-1023'
```

**Performance Testing:**

Untuk testing performance dengan large files:

1. **Large File Upload** - Test dengan file 8-10MB
2. **Concurrent Uploads** - Test multiple users upload simultaneously
3. **Streaming Download** - Test download large files dengan Range requests
4. **Thumbnail Generation** - Test dengan high-resolution images

**Error Scenarios Testing:**

1. **Disk Space Full** - Simulate ketika storage penuh
2. **Network Interruption** - Test upload dengan connection yang terputus
3. **Corrupt Files** - Upload file yang corrupt
4. **Concurrent Access** - Multiple users access same file simultaneously

## Penutup {#penutup}

Selamat! Anda telah berhasil menyelesaikan implementasi sistem file upload yang comprehensive untuk REST API menggunakan Go dan Gin framework. Mari kita review pencapaian besar dari Part 3 ini:

1. **Comprehensive File Upload System** - Kita telah mengimplementasikan sistem upload yang mendukung single dan multiple file uploads dengan validation yang ketat. Sistem ini mencakup file type validation, size limits, dan security measures yang melindungi dari common vulnerabilities seperti unrestricted file upload attacks.

2. **Advanced Image Processing** - Implementation automatic image processing dengan resize, compression, dan thumbnail generation memberikan user experience yang optimal. Sistem secara otomatis mengoptimalkan images untuk web usage sambil mempertahankan quality yang acceptable.

3. **Secure File Storage** - Organized file storage dengan directory structure berdasarkan date dan type, unique filename generation untuk mencegah conflicts, dan proper access controls memastikan files tersimpan dengan aman dan terorganisir.

4. **Database Integration dengan Relationships** - File metadata tracking di database dengan many-to-many relationship ke products mendemonstrasikan real-world application. Product-file associations memungkinkan complex business logic seperti product galleries dan file attachments.

5. **Streaming File Serving** - Implementation HTTP Range support untuk file serving memungkinkan efficient download large files dan streaming media. Security measures seperti access control dan proper headers melindungi dari unauthorized access.

6. **Production-Ready Architecture** - Repository pattern, dependency injection, proper error handling, dan comprehensive logging membuat sistem siap untuk production deployment. Cleanup mechanisms untuk temporary files dan performance optimizations menunjukkan enterprise-grade considerations.

7. **RESTful API Design** - Consistent endpoint design dengan proper HTTP methods dan status codes memudahkan integration dengan frontend applications. Response formats yang standardized dan pagination support memberikan excellent developer experience.

**Key Technical Achievements:**

- **Security First Approach** - Filename sanitization, MIME type validation, file size limits, dan access controls
- **Performance Optimization** - Image compression, thumbnail generation, HTTP Range support, dan efficient database queries
- **Scalability Considerations** - Organized storage structure, cleanup mechanisms, dan pagination support
- **Error Resilience** - Comprehensive error handling, transaction support, dan graceful degradation
- **Developer Experience** - Clear API documentation, consistent response formats, dan helpful error messages

**Architecture Patterns Implemented:**

- **Repository Pattern** - Clean separation antara business logic dan data access
- **Dependency Injection** - Loose coupling dan better testability
- **Middleware Pattern** - Cross-cutting concerns seperti authentication dan file serving
- **Event-Driven Processing** - Automatic image processing dengan hooks dan background tasks

**Next Steps dan Enhancements:**

Dengan fondasi solid yang telah dibangun dalam tutorial Part 1, 2, dan 3, berikut beberapa enhancements yang bisa Anda tambahkan:

**File Management Enhancements:**

- **Cloud Storage Integration** - Add support untuk AWS S3, Google Cloud Storage, atau Azure Blob
- **CDN Integration** - Implement CDN untuk faster file serving globally
- **Advanced Image Processing** - Watermarking, format conversion, dan multiple size variants
- **Video/Audio Support** - Extend untuk handle media files dengan transcoding
- **File Versioning** - Track file versions dan allow rollback
- **Bulk Operations** - Batch upload, download, dan management operations

**Security Enhancements:**

- **Virus Scanning** - Integrate dengan antivirus untuk scan uploaded files
- **Advanced Access Control** - Role-based permissions dan sharing mechanisms
- **Digital Signatures** - File integrity verification dengan digital signatures
- **Audit Trail** - Detailed logging untuk file operations dan access

**Performance Optimizations:**

- **Caching Layer** - Redis caching untuk file metadata dan thumbnails
- **Async Processing** - Background jobs untuk heavy processing tasks
- **Database Optimization** - Indexes, partitioning, dan query optimization
- **Compression** - File compression untuk storage optimization

**Business Features:**

- **File Sharing** - Public/private sharing dengan expiration dates
- **File Analytics** - Track download counts, popular files, storage usage
- **Backup and Recovery** - Automated backup dengan disaster recovery
- **Integration APIs** - Webhooks untuk file events, third-party integrations

**Monitoring dan Observability:**

- **Metrics Collection** - File upload/download metrics, error rates, performance metrics
- **Health Checks** - Storage health, database connectivity, processing queues
- **Alerting** - Storage space alerts, error rate thresholds, performance degradation
- **Logging Enhancements** - Structured logging dengan correlation IDs

Anda sekarang memiliki REST API yang truly production-ready dengan authentication, CRUD operations, dan comprehensive file upload system. Sistem ini mengikuti industry best practices dan siap untuk scale sesuai kebutuhan business. Clean architecture, proper security measures, dan performance optimizations memberikan foundation yang solid untuk aplikasi enterprise.

File upload adalah komponen critical dalam modern web applications, dan dengan implementation yang telah kita bangun, Anda siap untuk handle berbagai use cases dari simple document sharing hingga complex media management systems. Kombinasi Go's performance, Gin's simplicity, dan architectural patterns yang proper membuat sistem ini efficient dan maintainable.

Terima kasih telah mengikuti tutorial series ini sampai Part 3! Anda telah membangun sistem yang comprehensive dan ready untuk real-world applications. Happy coding dengan Go dan Gin! 🚀📁