---
title: "REST API CRUD Operations dengan Go dan Gin"
slug: "rest-api-crud-operations-dengan-go-dan-gin-part-2"
category: "Golang"
date: "2025-06-28"
status: "published"
---

Halo, selamat datang di Part 2 tutorial Go dan Gin! Pada bagian ini kita akan melanjutkan [pengembangan REST API](https://qadrlabs.com/member/post/rest-api-authentication-dengan-go-dan-gin-part-1) dengan menambahkan CRUD (Create, Read, Update, Delete) operations. Kita akan memanfaatkan sistem authentication yang sudah dibangun di Part 1 untuk melindungi endpoints dan memastikan setiap user hanya bisa mengakses dan memodifikasi data mereka sendiri.

CRUD operations adalah fondasi dari hampir semua aplikasi web modern. Dengan menguasai implementasi CRUD yang proper, Anda akan dapat membangun berbagai jenis aplikasi, dari simple task manager hingga complex enterprise systems. Tutorial ini akan mendemonstrasikan best practices dalam implementasi CRUD dengan Go dan Gin.

**Prasyarat**: Pastikan Anda sudah menyelesaikan Part 1 tutorial ini, karena Part 2 bergantung pada sistem authentication yang sudah dibangun sebelumnya.

## REST API CRUD Operations dengan Go dan Gin - Part 2 {#table-of-content}

- [Overview](#overview)
- [Persiapan](#persiapan)
- [Step 1 - Create Product Model](#step-1)
- [Step 2 - Create Product Repository](#step-2)
- [Step 3 - Create Product Controller](#step-3)
- [Step 4 - Update Routes](#step-4)
- [Step 5 - Create Pagination Utility](#step-5)
- [Step 6 - Update Main Application](#step-6)
- [Step 7 - Uji Coba CRUD Operations](#step-7)
- [Uji Coba Create Product](#uji-coba-1)
- [Uji Coba Get All Products](#uji-coba-2)
- [Uji Coba Get Product by ID](#uji-coba-3)
- [Uji Coba Update Product](#uji-coba-4)
- [Uji Coba Delete Product](#uji-coba-5)
- [Uji Coba Pagination dan Filtering](#uji-coba-6)
- [Penutup](#penutup)

## Overview {#overview}

Pada Part 2 ini, kita akan mengembangkan REST API lebih lanjut dengan menambahkan resource management untuk products. Fitur-fitur yang akan kita implementasikan meliputi:

1. **Product Model dengan Relationships** - Model product yang terhubung dengan user (one-to-many relationship)
2. **Repository Pattern** - Abstraksi database operations untuk better testability dan separation of concerns
3. **CRUD Endpoints** - Complete Create, Read, Update, dan Delete operations dengan proper authorization
4. **Pagination dan Filtering** - Implementasi pagination untuk handle large datasets dan filtering capabilities
5. **Soft Deletes** - Implementasi soft delete untuk menjaga data integrity
6. **Request Validation** - Comprehensive input validation untuk setiap operation
7. **Authorization Checks** - Memastikan users hanya bisa modify resources mereka sendiri

Tujuan dari Part 2 ini adalah untuk memberikan pemahaman mendalam tentang:
- Bagaimana mengimplementasikan CRUD operations yang secure dan efficient
- Best practices dalam handling relationships antar models
- Implementasi repository pattern untuk clean architecture
- Teknik pagination dan filtering untuk scalable APIs
- Authorization strategies untuk multi-tenant applications

Setelah menyelesaikan Part 2, Anda akan memiliki REST API yang fully functional dengan authentication dan complete resource management capabilities.

## Persiapan {#persiapan}

Sebelum memulai Part 2, pastikan Anda memiliki:

1. **Project dari Part 1** - Semua code dari Part 1 harus sudah berjalan dengan baik
2. **Database yang sudah setup** - MySQL database dengan table users yang sudah ter-migrate
3. **Postman Collection** - Idealnya Anda sudah memiliki collection dari Part 1 untuk easier testing
4. **Valid JWT Token** - Register/login user untuk mendapatkan token yang akan digunakan untuk testing

Struktur folder kita akan berkembang menjadi:
```
go-gin-auth-api/
├── config/
├── controllers/
├── database/
├── middlewares/
├── models/
├── repositories/    # NEW: untuk abstraksi database operations
├── utils/          # NEW: untuk utility functions
├── routes/
├── go.mod
├── go.sum
├── .env
└── main.go
```

Mari kita mulai.

## Step 1 - Create Product Model {#step-1}

Pertama, kita akan membuat model Product yang akan menjadi resource utama untuk CRUD operations. Model ini akan memiliki relationship dengan User model yang sudah kita buat di Part 1.

Buat file `models/product.go`:

```go
package models

import (
    "fmt"
    "strings"
    "time"

    "gorm.io/gorm"
)

// Product model untuk CRUD operations
type Product struct {
    ID          uint           `json:"id" gorm:"primaryKey"`
    Name        string         `json:"name" gorm:"not null;size:200"`
    Description string         `json:"description" gorm:"type:text"`
    Price       float64        `json:"price" gorm:"not null;check:price >= 0"`
    Stock       int            `json:"stock" gorm:"default:0;check:stock >= 0"`
    SKU         string         `json:"sku" gorm:"uniqueIndex;size:50"` // Stock Keeping Unit
    Category    string         `json:"category" gorm:"size:100;index"`
    IsActive    bool           `json:"is_active" gorm:"default:true;index"`
    UserID      uint           `json:"user_id" gorm:"not null;index"`
    User        User           `json:"user,omitempty" gorm:"foreignKey:UserID;constraint:OnDelete:CASCADE"`
    CreatedAt   time.Time      `json:"created_at"`
    UpdatedAt   time.Time      `json:"updated_at"`
    DeletedAt   gorm.DeletedAt `json:"deleted_at,omitempty" gorm:"index"`
}

// TableName menentukan nama table di database
func (Product) TableName() string {
    return "products"
}

// BeforeCreate hook untuk validasi dan setup sebelum create
func (p *Product) BeforeCreate(tx *gorm.DB) error {
    // Generate SKU jika tidak ada
    if p.SKU == "" {
        p.SKU = generateSKU(p.Name, p.Category)
    }
    
    // Ensure stock tidak negative
    if p.Stock < 0 {
        p.Stock = 0
    }
    
    return nil
}

// generateSKU membuat SKU otomatis berdasarkan name dan category
func generateSKU(name, category string) string {
    timestamp := time.Now().Unix()
    
    // Ambil 3 karakter pertama dari name dan category
    namePrefix := ""
    if len(name) >= 3 {
        namePrefix = name[:3]
    } else {
        namePrefix = name
    }
    
    categoryPrefix := ""
    if len(category) >= 2 {
        categoryPrefix = category[:2]
    } else {
        categoryPrefix = category
    }
    
    // Format: CAT-NAM-TIMESTAMP
    return fmt.Sprintf("%s-%s-%d", 
        strings.ToUpper(categoryPrefix),
        strings.ToUpper(namePrefix),
        timestamp)
}

// ProductResponse adalah struktur untuk API response
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
    CreatedAt   time.Time  `json:"created_at"`
    UpdatedAt   time.Time  `json:"updated_at"`
}

// ToResponse converts Product to ProductResponse
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
    
    return response
}
```

Model Product ini memiliki beberapa fitur penting:
- **Soft Deletes** - Menggunakan `gorm.DeletedAt` untuk menjaga history data
- **Constraints** - Database-level constraints untuk data integrity (price >= 0, stock >= 0)
- **Indexes** - Untuk optimize query performance pada fields yang sering di-filter
- **Auto SKU Generation** - Automatic SKU generation jika tidak disediakan
- **Relationship dengan User** - One-to-many relationship dengan cascade delete

## Step 2 - Create Product Repository {#step-2}

Repository pattern membantu kita memisahkan business logic dari database operations. Ini membuat code lebih testable dan maintainable.

Buat file `repositories/product_repository.go`:

```go
package repositories

import (
    "errors"
    "fmt"

    "github.com/username/go-gin-auth-api/models"
    "gorm.io/gorm"
)

// ProductRepository interface mendefinisikan contract untuk product operations
type ProductRepository interface {
    Create(product *models.Product) error
    GetByID(id uint) (*models.Product, error)
    GetByIDAndUser(id, userID uint) (*models.Product, error)
    GetAll(params QueryParams) (*PaginatedResult, error)
    GetAllByUser(userID uint, params QueryParams) (*PaginatedResult, error)
    Update(product *models.Product) error
    Delete(id uint) error
    SoftDelete(id uint) error
    CheckSKUExists(sku string, excludeID uint) (bool, error)
}

// productRepository adalah implementasi dari ProductRepository
type productRepository struct {
    db *gorm.DB
}

// NewProductRepository membuat instance baru dari ProductRepository
func NewProductRepository(db *gorm.DB) ProductRepository {
    return &productRepository{db: db}
}

// QueryParams untuk filtering dan pagination
type QueryParams struct {
    Page     int    `form:"page,default=1"`
    PageSize int    `form:"page_size,default=10"`
    Search   string `form:"search"`
    Category string `form:"category"`
    SortBy   string `form:"sort_by,default=created_at"`
    SortDesc bool   `form:"sort_desc,default=true"`
}

// PaginatedResult struktur untuk hasil pagination
type PaginatedResult struct {
    Data        interface{} `json:"data"`
    Total       int64       `json:"total"`
    Page        int         `json:"page"`
    PageSize    int         `json:"page_size"`
    TotalPages  int         `json:"total_pages"`
}

// Create menyimpan product baru ke database
func (r *productRepository) Create(product *models.Product) error {
    if err := r.db.Create(product).Error; err != nil {
        return fmt.Errorf("failed to create product: %w", err)
    }
    return nil
}

// GetByID mengambil product berdasarkan ID dengan user data
func (r *productRepository) GetByID(id uint) (*models.Product, error) {
    var product models.Product
    
    err := r.db.Preload("User").First(&product, id).Error
    if err != nil {
        if errors.Is(err, gorm.ErrRecordNotFound) {
            return nil, errors.New("product not found")
        }
        return nil, fmt.Errorf("failed to get product: %w", err)
    }
    
    return &product, nil
}

// GetByIDAndUser mengambil product berdasarkan ID dan User ID
func (r *productRepository) GetByIDAndUser(id, userID uint) (*models.Product, error) {
    var product models.Product
    
    err := r.db.Where("id = ? AND user_id = ?", id, userID).
        Preload("User").
        First(&product).Error
        
    if err != nil {
        if errors.Is(err, gorm.ErrRecordNotFound) {
            return nil, errors.New("product not found or access denied")
        }
        return nil, fmt.Errorf("failed to get product: %w", err)
    }
    
    return &product, nil
}

// GetAll mengambil semua products dengan pagination dan filtering
func (r *productRepository) GetAll(params QueryParams) (*PaginatedResult, error) {
    var products []models.Product
    var total int64
    
    // Base query
    query := r.db.Model(&models.Product{}).Preload("User")
    
    // Apply search filter
    if params.Search != "" {
        searchPattern := "%" + params.Search + "%"
        query = query.Where("name LIKE ? OR description LIKE ? OR sku LIKE ?", 
            searchPattern, searchPattern, searchPattern)
    }
    
    // Apply category filter
    if params.Category != "" {
        query = query.Where("category = ?", params.Category)
    }
    
    // Count total records
    if err := query.Count(&total).Error; err != nil {
        return nil, fmt.Errorf("failed to count products: %w", err)
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
    if err := query.Find(&products).Error; err != nil {
        return nil, fmt.Errorf("failed to get products: %w", err)
    }
    
    // Calculate total pages
    totalPages := int(total) / params.PageSize
    if int(total)%params.PageSize > 0 {
        totalPages++
    }
    
    return &PaginatedResult{
        Data:       products,
        Total:      total,
        Page:       params.Page,
        PageSize:   params.PageSize,
        TotalPages: totalPages,
    }, nil
}

// GetAllByUser mengambil products berdasarkan user dengan pagination
func (r *productRepository) GetAllByUser(userID uint, params QueryParams) (*PaginatedResult, error) {
    var products []models.Product
    var total int64
    
    // Base query dengan user filter
    query := r.db.Model(&models.Product{}).
        Where("user_id = ?", userID).
        Preload("User")
    
    // Apply search filter
    if params.Search != "" {
        searchPattern := "%" + params.Search + "%"
        query = query.Where("name LIKE ? OR description LIKE ? OR sku LIKE ?", 
            searchPattern, searchPattern, searchPattern)
    }
    
    // Apply category filter
    if params.Category != "" {
        query = query.Where("category = ?", params.Category)
    }
    
    // Count total records
    if err := query.Count(&total).Error; err != nil {
        return nil, fmt.Errorf("failed to count products: %w", err)
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
    if err := query.Find(&products).Error; err != nil {
        return nil, fmt.Errorf("failed to get products: %w", err)
    }
    
    // Calculate total pages
    totalPages := int(total) / params.PageSize
    if int(total)%params.PageSize > 0 {
        totalPages++
    }
    
    return &PaginatedResult{
        Data:       products,
        Total:      total,
        Page:       params.Page,
        PageSize:   params.PageSize,
        TotalPages: totalPages,
    }, nil
}

// Update mengupdate product yang sudah ada
func (r *productRepository) Update(product *models.Product) error {
    // Update hanya fields yang diperlukan
    if err := r.db.Model(product).Updates(product).Error; err != nil {
        return fmt.Errorf("failed to update product: %w", err)
    }
    return nil
}

// Delete menghapus product secara permanent (hard delete)
func (r *productRepository) Delete(id uint) error {
    if err := r.db.Unscoped().Delete(&models.Product{}, id).Error; err != nil {
        return fmt.Errorf("failed to delete product: %w", err)
    }
    return nil
}

// SoftDelete menghapus product secara soft delete
func (r *productRepository) SoftDelete(id uint) error {
    if err := r.db.Delete(&models.Product{}, id).Error; err != nil {
        return fmt.Errorf("failed to soft delete product: %w", err)
    }
    return nil
}

// CheckSKUExists mengecek apakah SKU sudah ada (exclude product dengan ID tertentu)
func (r *productRepository) CheckSKUExists(sku string, excludeID uint) (bool, error) {
    var count int64
    
    query := r.db.Model(&models.Product{}).Where("sku = ?", sku)
    if excludeID > 0 {
        query = query.Where("id != ?", excludeID)
    }
    
    if err := query.Count(&count).Error; err != nil {
        return false, fmt.Errorf("failed to check SKU: %w", err)
    }
    
    return count > 0, nil
}
```

Repository pattern ini memberikan beberapa keuntungan:
- **Abstraction** - Controller tidak perlu tahu detail implementasi database
- **Testability** - Mudah untuk mock repository dalam unit tests
- **Reusability** - Repository methods bisa digunakan di berbagai controllers
- **Consistency** - Semua database operations mengikuti pattern yang sama

## Step 3 - Create Product Controller {#step-3}

Sekarang kita buat controller yang akan handle HTTP requests untuk CRUD operations. Controller akan menggunakan repository untuk database operations.

Buat file `controllers/product_controller.go`:

```go
package controllers

import (
    "net/http"
    "strconv"
    "strings"

    "github.com/gin-gonic/gin"
    "github.com/username/go-gin-auth-api/middlewares"
    "github.com/username/go-gin-auth-api/models"
    "github.com/username/go-gin-auth-api/repositories"
)

// ProductController struct untuk dependency injection
type ProductController struct {
    repo repositories.ProductRepository
}

// NewProductController membuat instance baru ProductController
func NewProductController(repo repositories.ProductRepository) *ProductController {
    return &ProductController{repo: repo}
}

// CreateProductRequest struktur untuk validasi create product
type CreateProductRequest struct {
    Name        string  `json:"name" binding:"required,min=3,max=200"`
    Description string  `json:"description" binding:"max=1000"`
    Price       float64 `json:"price" binding:"required,min=0"`
    Stock       int     `json:"stock" binding:"min=0"`
    SKU         string  `json:"sku" binding:"max=50"`
    Category    string  `json:"category" binding:"required,max=100"`
}

// UpdateProductRequest struktur untuk validasi update product
type UpdateProductRequest struct {
    Name        string  `json:"name" binding:"omitempty,min=3,max=200"`
    Description string  `json:"description" binding:"max=1000"`
    Price       float64 `json:"price" binding:"omitempty,min=0"`
    Stock       int     `json:"stock" binding:"omitempty,min=0"`
    SKU         string  `json:"sku" binding:"omitempty,max=50"`
    Category    string  `json:"category" binding:"omitempty,max=100"`
    IsActive    *bool   `json:"is_active"`
}

// CreateProduct handler untuk membuat product baru
func (pc *ProductController) CreateProduct(c *gin.Context) {
    var req CreateProductRequest
    
    // Validasi request body
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
    
    // Normalize SKU
    req.SKU = strings.ToUpper(strings.TrimSpace(req.SKU))
    
    // Check if SKU already exists
    if req.SKU != "" {
        exists, err := pc.repo.CheckSKUExists(req.SKU, 0)
        if err != nil {
            c.JSON(http.StatusInternalServerError, gin.H{
                "error": "Database error",
                "message": "Failed to check SKU availability",
            })
            return
        }
        if exists {
            c.JSON(http.StatusConflict, gin.H{
                "error": "SKU already exists",
                "message": "A product with this SKU already exists",
            })
            return
        }
    }
    
    // Create product object
    product := &models.Product{
        Name:        strings.TrimSpace(req.Name),
        Description: strings.TrimSpace(req.Description),
        Price:       req.Price,
        Stock:       req.Stock,
        SKU:         req.SKU,
        Category:    strings.TrimSpace(req.Category),
        UserID:      userID,
        IsActive:    true,
    }
    
    // Save to database
    if err := pc.repo.Create(product); err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{
            "error": "Failed to create product",
            "message": "An error occurred while creating the product",
        })
        return
    }
    
    // Return success response
    c.JSON(http.StatusCreated, gin.H{
        "message": "Product created successfully",
        "product": product.ToResponse(),
    })
}

// GetAllProducts handler untuk mendapatkan semua products dengan pagination
func (pc *ProductController) GetAllProducts(c *gin.Context) {
    var params repositories.QueryParams
    
    // Bind query parameters
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
    
    // Get products from repository
    result, err := pc.repo.GetAll(params)
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{
            "error": "Failed to fetch products",
            "message": "An error occurred while fetching products",
        })
        return
    }
    
    // Convert products to response format
    products := result.Data.([]models.Product)
    productResponses := make([]models.ProductResponse, len(products))
    for i, product := range products {
        productResponses[i] = product.ToResponse()
    }
    
    // Update result with converted data
    result.Data = productResponses
    
    c.JSON(http.StatusOK, result)
}

// GetMyProducts handler untuk mendapatkan products milik user yang login
func (pc *ProductController) GetMyProducts(c *gin.Context) {
    var params repositories.QueryParams
    
    // Get user ID dari context
    userID, exists := middlewares.GetUserIDFromContext(c)
    if !exists {
        c.JSON(http.StatusUnauthorized, gin.H{
            "error": "Unauthorized",
            "message": "User ID not found",
        })
        return
    }
    
    // Bind query parameters
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
    
    // Get products from repository
    result, err := pc.repo.GetAllByUser(userID, params)
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{
            "error": "Failed to fetch products",
            "message": "An error occurred while fetching your products",
        })
        return
    }
    
    // Convert products to response format
    products := result.Data.([]models.Product)
    productResponses := make([]models.ProductResponse, len(products))
    for i, product := range products {
        productResponses[i] = product.ToResponse()
    }
    
    // Update result with converted data
    result.Data = productResponses
    
    c.JSON(http.StatusOK, result)
}

// GetProductByID handler untuk mendapatkan single product
func (pc *ProductController) GetProductByID(c *gin.Context) {
    // Parse product ID dari URL parameter
    id, err := strconv.ParseUint(c.Param("id"), 10, 32)
    if err != nil {
        c.JSON(http.StatusBadRequest, gin.H{
            "error": "Invalid product ID",
            "message": "Product ID must be a valid number",
        })
        return
    }
    
    // Get product from repository
    product, err := pc.repo.GetByID(uint(id))
    if err != nil {
        if err.Error() == "product not found" {
            c.JSON(http.StatusNotFound, gin.H{
                "error": "Product not found",
                "message": "The requested product does not exist",
            })
        } else {
            c.JSON(http.StatusInternalServerError, gin.H{
                "error": "Failed to fetch product",
                "message": "An error occurred while fetching the product",
            })
        }
        return
    }
    
    c.JSON(http.StatusOK, gin.H{
        "product": product.ToResponse(),
    })
}

// UpdateProduct handler untuk update product
func (pc *ProductController) UpdateProduct(c *gin.Context) {
    // Parse product ID
    id, err := strconv.ParseUint(c.Param("id"), 10, 32)
    if err != nil {
        c.JSON(http.StatusBadRequest, gin.H{
            "error": "Invalid product ID",
            "message": "Product ID must be a valid number",
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
    
    // Get existing product (with ownership check)
    product, err := pc.repo.GetByIDAndUser(uint(id), userID)
    if err != nil {
        if err.Error() == "product not found or access denied" {
            c.JSON(http.StatusNotFound, gin.H{
                "error": "Product not found",
                "message": "Product not found or you don't have permission to update it",
            })
        } else {
            c.JSON(http.StatusInternalServerError, gin.H{
                "error": "Failed to fetch product",
                "message": "An error occurred while fetching the product",
            })
        }
        return
    }
    
    // Bind and validate request
    var req UpdateProductRequest
    if err := c.ShouldBindJSON(&req); err != nil {
        c.JSON(http.StatusBadRequest, gin.H{
            "error": "Validation failed",
            "message": err.Error(),
        })
        return
    }
    
    // Update fields if provided
    if req.Name != "" {
        product.Name = strings.TrimSpace(req.Name)
    }
    if req.Description != "" {
        product.Description = strings.TrimSpace(req.Description)
    }
    if req.Price > 0 {
        product.Price = req.Price
    }
    if req.Stock >= 0 {
        product.Stock = req.Stock
    }
    if req.Category != "" {
        product.Category = strings.TrimSpace(req.Category)
    }
    if req.IsActive != nil {
        product.IsActive = *req.IsActive
    }
    
    // Handle SKU update
    if req.SKU != "" {
        newSKU := strings.ToUpper(strings.TrimSpace(req.SKU))
        
        // Check if new SKU is different and already exists
        if newSKU != product.SKU {
            exists, err := pc.repo.CheckSKUExists(newSKU, product.ID)
            if err != nil {
                c.JSON(http.StatusInternalServerError, gin.H{
                    "error": "Database error",
                    "message": "Failed to check SKU availability",
                })
                return
            }
            if exists {
                c.JSON(http.StatusConflict, gin.H{
                    "error": "SKU already exists",
                    "message": "A product with this SKU already exists",
                })
                return
            }
            product.SKU = newSKU
        }
    }
    
    // Update in database
    if err := pc.repo.Update(product); err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{
            "error": "Failed to update product",
            "message": "An error occurred while updating the product",
        })
        return
    }
    
    // Fetch updated product with user data
    updatedProduct, _ := pc.repo.GetByID(product.ID)
    
    c.JSON(http.StatusOK, gin.H{
        "message": "Product updated successfully",
        "product": updatedProduct.ToResponse(),
    })
}

// DeleteProduct handler untuk soft delete product
func (pc *ProductController) DeleteProduct(c *gin.Context) {
    // Parse product ID
    id, err := strconv.ParseUint(c.Param("id"), 10, 32)
    if err != nil {
        c.JSON(http.StatusBadRequest, gin.H{
            "error": "Invalid product ID",
            "message": "Product ID must be a valid number",
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
    
    // Check ownership
    _, err = pc.repo.GetByIDAndUser(uint(id), userID)
    if err != nil {
        if err.Error() == "product not found or access denied" {
            c.JSON(http.StatusNotFound, gin.H{
                "error": "Product not found",
                "message": "Product not found or you don't have permission to delete it",
            })
        } else {
            c.JSON(http.StatusInternalServerError, gin.H{
                "error": "Failed to fetch product",
                "message": "An error occurred while fetching the product",
            })
        }
        return
    }
    
    // Perform soft delete
    if err := pc.repo.SoftDelete(uint(id)); err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{
            "error": "Failed to delete product",
            "message": "An error occurred while deleting the product",
        })
        return
    }
    
    c.JSON(http.StatusOK, gin.H{
        "message": "Product deleted successfully",
    })
}

// GetProductCategories handler untuk mendapatkan list unique categories
func (pc *ProductController) GetProductCategories(c *gin.Context) {
    // Untuk simplicity, kita hardcode categories
    // Di production, ini bisa di-query dari database
    categories := []string{
        "Electronics",
        "Books",
        "Clothing",
        "Food & Beverage",
        "Home & Garden",
        "Sports & Outdoors",
        "Toys & Games",
        "Health & Beauty",
        "Automotive",
        "Other",
    }
    
    c.JSON(http.StatusOK, gin.H{
        "categories": categories,
    })
}
```

Controller ini mengimplementasikan:
- **Complete CRUD operations** dengan proper validation
- **Authorization checks** untuk memastikan user hanya bisa modify products mereka
- **Comprehensive error handling** dengan meaningful messages
- **Pagination support** untuk scalability
- **SKU uniqueness validation** untuk data integrity

## Step 4 - Update Routes {#step-4}

Sekarang kita perlu update routes untuk menambahkan endpoints CRUD. Update file `routes/routes.go`:

```go
package routes

import (
    "github.com/gin-gonic/gin"
    "github.com/username/go-gin-auth-api/controllers"
    "github.com/username/go-gin-auth-api/database" // tambahkan import untuk akses ke database connection
    "github.com/username/go-gin-auth-api/middlewares"
    "github.com/username/go-gin-auth-api/repositories" // tambahkan import untuk repositori pattern
)

// SetupRoutes mengkonfigurasi semua routes aplikasi
func SetupRoutes(router *gin.Engine) {
    // Initialize repositories
    productRepo := repositories.NewProductRepository(database.DB) // tambahkan baris kode ini
    
    // Initialize controllers dengan dependency injection
    productController := controllers.NewProductController(productRepo) // tambahkan baris kode ini
    
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
            
            // TAMBAHKAN ROUTE UNTUK CRUD OPERATION
            // Product routes - CRUD operations
            products := protected.Group("/products")
            {
                // Create
                products.POST("", productController.CreateProduct)
                
                // Read
                products.GET("", productController.GetAllProducts)      // Get all products
                products.GET("/my", productController.GetMyProducts)    // Get user's products
                products.GET("/:id", productController.GetProductByID)  // Get single product
                
                // Update
                products.PUT("/:id", productController.UpdateProduct)
                
                // Delete
                products.DELETE("/:id", productController.DeleteProduct)
                
                // Additional endpoints
                products.GET("/categories", productController.GetProductCategories)
            }
        }
        
        // TAMBAHKAN ROUTE PRODUCT YANG DAPAT DIAKSES TANPA LOGIN
        // Public product routes (tanpa authentication)
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

// SetupMiddlewares remains the same from Part 1
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

Pada baris kode diatas kita menambahkan:
1. IMPORT PACKAGES BARU:
   - "database" - untuk akses koneksi database
   - "repositories" - untuk repository pattern

2. DEPENDENCY INJECTION:
   - productRepo := repositories.NewProductRepository(database.DB)
   - productController := controllers.NewProductController(productRepo)

3. PROTECTED PRODUCT ROUTES (Perlu Authentication):
   - POST /api/v1/products (Create)
   - GET /api/v1/products (Read All)
   - GET /api/v1/products/my (Read My Products)
   - GET /api/v1/products/:id (Read By ID)
   - PUT /api/v1/products/:id (Update)
   - DELETE /api/v1/products/:id (Delete)
   - GET /api/v1/products/categories (Get Categories)

4. PUBLIC PRODUCT ROUTES (Tanpa Authentication):
   - GET /api/v1/products/public (Public Read All)
   - GET /api/v1/products/public/:id (Public Read By ID)

5. ARCHITECTURE PATTERNS:
   - Repository Pattern (separation of concerns)
   - Dependency Injection (loose coupling)
   - Controller pattern dengan DI

TOTAL ENDPOINTS:
- Tutorial 1: 5 endpoints (health, register, login, profile, refresh)
- Tutorial 2: 14 endpoints (5 lama + 9 baru untuk CRUD)


Route organization ini memberikan:
- **RESTful URL structure** yang konsisten
- **Clear separation** antara protected dan public endpoints
- **Dependency injection** untuk better testability
- **Logical grouping** untuk easier maintenance

## Step 5 - Create Pagination Utility {#step-5}

Mari kita buat utility untuk generate pagination metadata yang akan membantu frontend dalam rendering pagination controls.

Buat file `utils/pagination.go`:

```go
package utils

import (
    "math"
    "strconv"

    "github.com/gin-gonic/gin"
)

// PaginationParams struktur untuk parameter pagination
type PaginationParams struct {
    Page     int    `json:"page"`
    PageSize int    `json:"page_size"`
    Sort     string `json:"sort"`
    Order    string `json:"order"`
}

// GetPaginationParams extract pagination parameters dari query string
func GetPaginationParams(c *gin.Context) PaginationParams {
    page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
    pageSize, _ := strconv.Atoi(c.DefaultQuery("page_size", "10"))
    sort := c.DefaultQuery("sort", "created_at")
    order := c.DefaultQuery("order", "desc")
    
    // Validate values
    if page < 1 {
        page = 1
    }
    
    if pageSize < 1 {
        pageSize = 10
    } else if pageSize > 100 {
        pageSize = 100 // Maximum page size
    }
    
    // Validate sort order
    if order != "asc" && order != "desc" {
        order = "desc"
    }
    
    return PaginationParams{
        Page:     page,
        PageSize: pageSize,
        Sort:     sort,
        Order:    order,
    }
}

// PaginationMeta struktur untuk metadata pagination
type PaginationMeta struct {
    Page       int   `json:"page"`
    PageSize   int   `json:"page_size"`
    Total      int64 `json:"total"`
    TotalPages int   `json:"total_pages"`
    HasPrev    bool  `json:"has_prev"`
    HasNext    bool  `json:"has_next"`
}

// CreatePaginationMeta membuat metadata untuk response pagination
func CreatePaginationMeta(page, pageSize int, total int64) PaginationMeta {
    totalPages := int(math.Ceil(float64(total) / float64(pageSize)))
    
    return PaginationMeta{
        Page:       page,
        PageSize:   pageSize,
        Total:      total,
        TotalPages: totalPages,
        HasPrev:    page > 1,
        HasNext:    page < totalPages,
    }
}

// PaginatedResponse struktur untuk response dengan pagination
type PaginatedResponse struct {
    Data interface{}    `json:"data"`
    Meta PaginationMeta `json:"meta"`
}

// CreatePaginatedResponse membuat response dengan format pagination standard
func CreatePaginatedResponse(data interface{}, page, pageSize int, total int64) PaginatedResponse {
    return PaginatedResponse{
        Data: data,
        Meta: CreatePaginationMeta(page, pageSize, total),
    }
}
```

Juga buat file `utils/response.go` untuk standardize API responses:

```go
package utils

import "github.com/gin-gonic/gin"

// SuccessResponse struktur untuk success response
type SuccessResponse struct {
    Message string      `json:"message"`
    Data    interface{} `json:"data,omitempty"`
}

// ErrorResponse struktur untuk error response
type ErrorResponse struct {
    Error   string `json:"error"`
    Message string `json:"message"`
    Code    string `json:"code,omitempty"`
}

// SendSuccess mengirim success response
func SendSuccess(c *gin.Context, statusCode int, message string, data interface{}) {
    response := SuccessResponse{
        Message: message,
    }
    
    if data != nil {
        response.Data = data
    }
    
    c.JSON(statusCode, response)
}

// SendError mengirim error response
func SendError(c *gin.Context, statusCode int, error, message string) {
    c.JSON(statusCode, ErrorResponse{
        Error:   error,
        Message: message,
    })
}

// SendErrorWithCode mengirim error response dengan error code
func SendErrorWithCode(c *gin.Context, statusCode int, error, message, code string) {
    c.JSON(statusCode, ErrorResponse{
        Error:   error,
        Message: message,
        Code:    code,
    })
}
```

Utilities ini membantu:
- **Consistent response format** across all endpoints
- **Reusable pagination logic**
- **Better developer experience** dengan helper functions
- **Frontend-friendly** response structure

## Step 6 - Update Main Application {#step-6}

Update `main.go` untuk include Product model dalam auto migration:

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
    // Load .env file in development
    if os.Getenv("GO_ENV") != "production" {
        if err := godotenv.Load(); err != nil {
            log.Printf("Warning: .env file not found")
        }
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
    
    // Auto migrate models - tambahkan Product model
    if err := database.DB.AutoMigrate(&models.User{}, &models.Product{}); err != nil {
        log.Fatal("Failed to migrate database:", err)
    }
    log.Println("✅ Database migration completed")

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

    // Create HTTP server
    srv := &http.Server{
        Addr:           ":" + port,
        Handler:        router,
        ReadTimeout:    10 * time.Second,
        WriteTimeout:   10 * time.Second,
        IdleTimeout:    120 * time.Second,
        MaxHeaderBytes: 1 << 20, // 1 MB
    }

    // Start server in goroutine
    go func() {
        log.Printf("🚀 Server starting on port %s", port)
        log.Printf("📍 API endpoints available at http://localhost:%s/api/v1", port)
        log.Printf("📝 Product endpoints ready for CRUD operations", port)
        
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
- **Product model migration** - Menambahkan models.Product ke auto migration
- **Additional startup log** - Menambahkan informasi tentang product endpoints
- **MaxHeaderBytes** - Menambahkan limit untuk header size untuk security

## Step 7 - Uji Coba CRUD Operations {#step-7}

Sekarang mari kita test semua CRUD operations yang sudah kita implementasikan. Pastikan Anda sudah memiliki valid JWT token dari Part 1.

Jalankan aplikasi:
```bash
go run main.go
```

Output yang diharapkan:
```
2024/03/15 10:00:00 ✅ Database connected successfully
2024/03/15 10:00:00 ✅ Database migration completed
2024/03/15 10:00:00 🚀 Server starting on port 8080
2024/03/15 10:00:00 📍 API endpoints available at http://localhost:8080/api/v1
2024/03/15 10:00:00 📝 Product endpoints ready for CRUD operations
```

### Uji Coba Create Product {#uji-coba-1}

Mari kita create product pertama:

1. Method: **POST**
2. URL: `http://localhost:8080/api/v1/products`
3. Headers:
   - `Authorization: Bearer <your_jwt_token>`
   - `Content-Type: application/json`
4. Body:
```json
{
    "name": "MacBook Pro 16 inch",
    "description": "Powerful laptop for developers and creative professionals",
    "price": 25000000,
    "stock": 5,
    "category": "Electronics"
}
```

Expected response (201 Created):
```json
{
    "message": "Product created successfully",
    "product": {
        "id": 1,
        "name": "MacBook Pro 16 inch",
        "description": "Powerful laptop for developers and creative professionals",
        "price": 25000000,
        "stock": 5,
        "sku": "EL-MAC-1710486000",
        "category": "Electronics",
        "is_active": true,
        "user_id": 1,
        "created_at": "2024-03-15T10:00:00Z",
        "updated_at": "2024-03-15T10:00:00Z"
    }
}
```

Mari create beberapa products lagi untuk testing:
```json
{
    "name": "iPhone 15 Pro Max",
    "description": "Latest flagship smartphone from Apple",
    "price": 18000000,
    "stock": 10,
    "sku": "IPHONE-15PM",
    "category": "Electronics"
}
```

```json
{
    "name": "Clean Code Book",
    "description": "A Handbook of Agile Software Craftsmanship by Robert C. Martin",
    "price": 450000,
    "stock": 20,
    "category": "Books"
}
```

### Uji Coba Get All Products {#uji-coba-2}

Test endpoint untuk mendapatkan semua products dengan pagination:

1. Method: **GET**
2. URL: `http://localhost:8080/api/v1/products?page=1&page_size=10`
3. Headers:
   - `Authorization: Bearer <your_jwt_token>`

Expected response:
```json
{
    "data": [
        {
            "id": 3,
            "name": "Clean Code Book",
            "description": "A Handbook of Agile Software Craftsmanship by Robert C. Martin",
            "price": 450000,
            "stock": 20,
            "sku": "BO-CLE-1710486300",
            "category": "Books",
            "is_active": true,
            "user_id": 1,
            "owner": {
                "id": 1,
                "name": "John Doe",
                "email": "john.doe@example.com",
                "created_at": "2024-03-12T10:00:00Z"
            },
            "created_at": "2024-03-15T10:05:00Z",
            "updated_at": "2024-03-15T10:05:00Z"
        },
        // ... more products
    ],
    "total": 3,
    "page": 1,
    "page_size": 10,
    "total_pages": 1
}
```

Test dengan search filter:
- URL: `http://localhost:8080/api/v1/products?search=iPhone&page=1&page_size=10`

Test dengan category filter:
- URL: `http://localhost:8080/api/v1/products?category=Electronics&page=1&page_size=10`

### Uji Coba Get Product by ID {#uji-coba-3}

Test untuk mendapatkan single product:

1. Method: **GET**
2. URL: `http://localhost:8080/api/v1/products/1`
3. Headers:
   - `Authorization: Bearer <your_jwt_token>`

Expected response:
```json
{
    "product": {
        "id": 1,
        "name": "MacBook Pro 16 inch",
        "description": "Powerful laptop for developers and creative professionals",
        "price": 25000000,
        "stock": 5,
        "sku": "EL-MAC-1710486000",
        "category": "Electronics",
        "is_active": true,
        "user_id": 1,
        "owner": {
            "id": 1,
            "name": "John Doe",
            "email": "john.doe@example.com",
            "created_at": "2024-03-12T10:00:00Z"
        },
        "created_at": "2024-03-15T10:00:00Z",
        "updated_at": "2024-03-15T10:00:00Z"
    }
}
```

Test dengan invalid ID akan return 404:
```json
{
    "error": "Product not found",
    "message": "The requested product does not exist"
}
```

### Uji Coba Update Product {#uji-coba-4}

Test update product yang sudah ada:

1. Method: **PUT**
2. URL: `http://localhost:8080/api/v1/products/1`
3. Headers:
   - `Authorization: Bearer <your_jwt_token>`
   - `Content-Type: application/json`
4. Body:
```json
{
    "name": "MacBook Pro 16 inch M3 Max",
    "price": 28000000,
    "stock": 3,
    "is_active": true
}
```

Expected response:
```json
{
    "message": "Product updated successfully",
    "product": {
        "id": 1,
        "name": "MacBook Pro 16 inch M3 Max",
        "description": "Powerful laptop for developers and creative professionals",
        "price": 28000000,
        "stock": 3,
        "sku": "EL-MAC-1710486000",
        "category": "Electronics",
        "is_active": true,
        "user_id": 1,
        "owner": {
            "id": 1,
            "name": "John Doe",
            "email": "john.doe@example.com",
            "created_at": "2024-03-12T10:00:00Z"
        },
        "created_at": "2024-03-15T10:00:00Z",
        "updated_at": "2024-03-15T10:15:00Z"
    }
}
```

Jika Anda mencoba update product milik user lain, akan mendapat error 404:
```json
{
    "error": "Product not found",
    "message": "Product not found or you don't have permission to update it"
}
```

### Uji Coba Delete Product {#uji-coba-5}

Test soft delete product:

1. Method: **DELETE**
2. URL: `http://localhost:8080/api/v1/products/3`
3. Headers:
   - `Authorization: Bearer <your_jwt_token>`

Expected response:
```json
{
    "message": "Product deleted successfully"
}
```

Setelah delete, jika Anda GET product tersebut akan return 404. Product tidak benar-benar dihapus dari database, hanya di-mark sebagai deleted (soft delete).

### Uji Coba Pagination dan Filtering {#uji-coba-6}

Mari test fitur advanced pagination dan filtering:

**1. Get My Products Only**
- Method: **GET**
- URL: `http://localhost:8080/api/v1/products/my?page=1&page_size=5`
- Headers: `Authorization: Bearer <your_jwt_token>`

Endpoint ini hanya return products milik user yang login.

**2. Search with Pagination**
- URL: `http://localhost:8080/api/v1/products?search=Mac&page=1&page_size=10&sort_by=price&sort_desc=true`

Query parameters yang tersedia:
- `page`: Page number (default: 1)
- `page_size`: Items per page (default: 10, max: 100)
- `search`: Search in name, description, and SKU
- `category`: Filter by category
- `sort_by`: Field to sort by (default: created_at)
- `sort_desc`: Sort descending (default: true)

**3. Get Product Categories**
- Method: **GET**
- URL: `http://localhost:8080/api/v1/products/categories`
- Headers: `Authorization: Bearer <your_jwt_token>`

Response:
```json
{
    "categories": [
        "Electronics",
        "Books",
        "Clothing",
        "Food & Beverage",
        "Home & Garden",
        "Sports & Outdoors",
        "Toys & Games",
        "Health & Beauty",
        "Automotive",
        "Other"
    ]
}
```

**4. Public Endpoints (No Auth Required)**

Kita juga menyediakan public endpoints untuk view products tanpa authentication:

- Get all products: `GET /api/v1/products/public`
- Get single product: `GET /api/v1/products/public/:id`

Ini berguna untuk public-facing applications dimana visitors bisa browse products tanpa login.

## Penutup {#penutup}

Selamat! Anda telah berhasil menyelesaikan implementasi REST API lengkap dengan authentication dan CRUD operations menggunakan Go dan Gin framework. Mari kita review key takeaways dari Part 2 ini:

1. **Repository Pattern Implementation** - Kita telah mengimplementasikan repository pattern yang memisahkan database logic dari business logic. Pattern ini membuat code lebih testable, maintainable, dan mengikuti principle of separation of concerns. Setiap database operation di-encapsulate dalam repository methods yang dapat dengan mudah di-mock untuk testing.

2. **Complete CRUD Operations** - Implementasi CRUD yang comprehensive dengan proper validation, error handling, dan authorization checks. Setiap operation memastikan data integrity dan security, dengan features seperti SKU uniqueness validation dan ownership verification.

3. **Advanced Pagination dan Filtering** - System pagination yang robust dengan support untuk search, filtering, dan sorting membuat API siap untuk handle large datasets. Implementation ini mengikuti best practices untuk scalable APIs dan memberikan metadata yang lengkap untuk frontend integration.

4. **Soft Delete Implementation** - Menggunakan soft deletes menjaga data integrity dan memungkinkan recovery jika diperlukan. Ini adalah pattern penting untuk production applications dimana data history perlu dipertahankan.

5. **Authorization Strategy** - Setiap user hanya dapat modify resources mereka sendiri, implementing proper multi-tenant security. Pattern ini dapat dengan mudah di-extend untuk role-based access control (RBAC) di masa depan.

6. **RESTful API Design** - API endpoints mengikuti REST conventions dengan proper HTTP methods, status codes, dan response formats. Consistency ini memudahkan frontend developers dan third-party integrations.

7. **Error Handling dan User Experience** - Comprehensive error messages yang informatif membantu developers debug issues quickly. Distinction antara validation errors, not found errors, dan permission errors memberikan clarity tentang apa yang salah.

**Next Steps dan Enhancements:**

Dengan fondasi solid yang sudah dibangun dalam tutorial Part 1 dan Part 2, berikut beberapa enhancements yang bisa Anda tambahkan:

- **Image Upload** - Tambahkan functionality untuk upload product images menggunakan multipart form data
- **Advanced Search** - Implement full-text search menggunakan database features atau external search engines
- **Caching Layer** - Add Redis caching untuk improve performance pada frequently accessed data
- **Rate Limiting** - Implement rate limiting per user untuk prevent API abuse
- **API Versioning** - Expand API versioning strategy untuk backward compatibility
- **Webhooks** - Add webhook support untuk notify external systems tentang product changes
- **Batch Operations** - Implement bulk create/update/delete untuk efficiency
- **Export/Import** - Add CSV/Excel export dan import functionality
- **Audit Trail** - Track semua changes dengan detailed audit logs
- **GraphQL Layer** - Add GraphQL endpoint sebagai alternative ke REST

Anda sekarang memiliki REST API yang production-ready dengan clean architecture, proper security, dan scalable design. Code yang telah kita buat mengikuti Go best practices dan siap untuk di-deploy ke production environment. Dengan pemahaman mendalam tentang authentication dan CRUD operations, Anda siap untuk membangun berbagai jenis aplikasi yang memerlukan secure API backend.

Terima kasih telah mengikuti tutorial ini sampai selesai. Happy coding dengan Go dan Gin! 🚀