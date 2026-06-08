---
title: "Symfony Framework 8"
slug: "symfony-framework-8-revolusi-modern-dalam-pengembangan-aplikasi-web-php"
category: "Symfony"
date: "2025-11-27"
status: "published"
---

## Overview {#overview}

Symfony Framework 8 merupakan rilis mayor yang sangat ditunggu-tunggu oleh komunitas pengembang PHP. Dirilis pada November 2025, Symfony 8 membawa transformasi signifikan dalam cara kita membangun aplikasi web modern. Artikel ini akan mengeksplorasi secara mendalam semua aspek revolusioner dari Symfony Framework 8, mulai dari fitur-fitur canggih, peningkatan performa yang dramatis, hingga integrasi dengan teknologi terbaru seperti PHP 8.4, Docker, dan FrankenPHP.

Artikel ini dirancang untuk memberikan pemahaman komprehensif tentang Symfony 8, ideal untuk pengembang yang ingin meningkatkan keterampilan mereka atau mempertimbangkan migrasi dari versi sebelumnya. Kami akan membahas tidak hanya fitur-fitur baru tetapi juga bagaimana memanfaatkannya secara optimal dalam proyek production.

## Daftar Isi

1. [Overview](#overview)
2. [Pengenalan Symfony Framework 8](#pengenalan-symfony-framework-8)
3. [Fitur-Fitur Utama](#fitur-fitur-utama)
4. [Integrasi PHP 8.4](#integrasi-php-84)
5. [Peningkatan Performa](#peningkatan-performa)
6. [Security dan Autentikasi](#security-dan-autentikasi)
7. [Pengembangan API](#pengembangan-api)
8. [Database dan Doctrine ORM](#database-dan-doctrine-orm)
9. [Testing dan Quality Assurance](#testing-dan-quality-assurance)
10. [Docker dan Containerization](#docker-dan-containerization)
11. [Migrasi dari Symfony 7](#migrasi-dari-symfony-7)
12. [Best Practices dan Patterns](#best-practices-dan-patterns)
13. [Penutup](#penutup)

## Pengenalan Symfony Framework 8 {#pengenalan-symfony-framework-8}

### Latar Belakang dan Konteks Rilis

Symfony Framework telah menjadi salah satu framework PHP paling terkenal dan dipercaya di dunia industri selama lebih dari 15 tahun. Setiap rilis major membawa inovasi yang signifikan, dan Symfony 8 tidak terkecuali. Dengan strategi rilis yang time-based, Symfony merilis versi major baru setiap dua tahun, memastikan ekosistem tetap modern dan relevan.

Symfony 8.0 dirancang khusus untuk memanfaatkan sepenuhnya fitur-fitur baru yang tersedia di PHP 8.4. Framework ini bukan hanya pembaruan incrementalnya predecessor, melainkan reimagining dari cara kita mengembangkan aplikasi PHP modern.

### Persyaratan Sistem

Sebelum memulai dengan Symfony 8, penting untuk memahami persyaratan sistemnya:

- **PHP minimum:** 8.4.0 atau lebih tinggi
- **Composer:** versi terbaru untuk manajemen dependencies
- **Database:** MySQL 5.7+, PostgreSQL 10+, atau database relasional lainnya
- **Web Server:** Apache 2.4+ atau Nginx 1.6+
- **Extension PHP:** ext-ctype, ext-iconv, dan extension spesifik untuk database yang digunakan

### Strategi Versioning dan Support

Penting untuk memahami siklus hidup Symfony 8:

- **Status:** Maintained (active support)
- **End of Support (bugs):** July 2026
- **End of Support (security):** July 2026
- **LTS Status:** Bukan LTS release (LTS akan menjadi Symfony 8.4)
- **Upgrade Frequency:** Diperlukan upgrade sebelum July 2026

Ini berarti bahwa meskipun Symfony 8.0 membawa fitur-fitur cutting-edge, developer harus merencanakan upgrade ke versi minor berikutnya secara teratur untuk tetap mendapatkan dukungan security dan bug fixes.

---

## Fitur-Fitur Utama {#fitur-fitur-utama}

### Property Hooks - Logika Custom pada Properties

Salah satu fitur paling revolutionary dalam Symfony 8 adalah dukungan penuh terhadap PHP 8.4 Property Hooks. Fitur ini memungkinkan Anda untuk mendefinisikan logika custom ketika membaca atau menulis sebuah property, tanpa perlu membuat method getter dan setter yang terpisah.

**Contoh tanpa Property Hooks (cara lama):**

```php
class User
{
    private string $email;
    
    public function getEmail(): string
    {
        return $this->email;
    }
    
    public function setEmail(string $email): void
    {
        if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
            throw new InvalidArgumentException('Invalid email format');
        }
        $this->email = $email;
    }
}
```

**Contoh dengan Property Hooks (cara modern):**

```php
class User
{
    public string $email {
        set(string $value) {
            if (!filter_var($value, FILTER_VALIDATE_EMAIL)) {
                throw new InvalidArgumentException('Invalid email format');
            }
            $this->email = $value;
        }
        get => $this->email;
    }
}
```

Keuntungan dari pendekatan ini adalah lebih ringkas, lebih mudah dibaca, dan mengurangi boilerplate code secara signifikan. Dalam Symfony 8, Property Hooks diintegrasikan dengan sempurna ke dalam Doctrine ORM, serializer, dan form handling.

### Lazy Objects - Optimisasi Memori Revolusioner

Lazy Objects adalah fitur PHP 8.4 yang diintegrasikan ke dalam Symfony 8 untuk mengurangi penggunaan memori hingga 50%. Konsep ini memungkinkan object untuk tidak di-instantiate sepenuhnya sampai property-nya benar-benar diakses.

**Bagaimana Lazy Objects Bekerja:**

```php
// Doctrine Entity relationship
class Post
{
    #[ORM\ManyToOne]
    private User $author;
    
    // Author hanya akan dimuat ketika diakses
    public function getAuthor(): User
    {
        return $this->author; // Lazy load terjadi di sini
    }
}
```

Dalam Symfony 8, ketika Anda memiliki relasi many-to-one atau one-to-one dengan eager loading, Doctrine secara otomatis menggunakan Lazy Objects. Ini berarti:

- Mengurangi memory footprint hingga 50%
- Query lebih efisien - hanya load data yang dibutuhkan
- Performance improvement otomatis tanpa mengubah kode

### Improved Attribute Handling

Attributes dalam PHP 8+ telah menjadi cara modern untuk mendefinisikan metadata di code. Symfony 8 mengoptimalkan handling attributes di berbagai bagian framework:

```php
class Article
{
    #[Route('/articles/{id}', name: 'article_show')]
    #[IsGranted('ROLE_USER')]
    #[ORM\Entity]
    #[Serializer\Groups(['public'])]
    public function show(int $id): Response
    {
        // Controller action
    }
}
```

Symfony 8 mengoptimalkan reflection dan attribute parsing, sehingga overhead dari attribute reading berkurang drastis.

### Generator Commands dan Developer Tooling

Symfony 8 dilengkapi dengan generator commands yang powerful untuk scaffolding:

```bash
# Generate complete CRUD resource
php bin/console make:crud Article

# Generate API resource dengan REST endpoints
php bin/console make:api Article

# Generate form handling
php bin/console make:form ArticleType

# Generate event listener
php bin/console make:listener ArticlePublishedListener
```

Fitur baru dalam generator:

- Scaffold API resource lengkap dalam beberapa detik
- Auto-generate validation rules
- Create migration files otomatis
- Generate test stubs
- Full GraphQL type generation

### Enhanced Form Component

Component form di Symfony 8 mendapat peningkatan signifikan:

```php
class ArticleFormType extends AbstractType
{
    public function buildForm(FormBuilderInterface $builder, array $options): void
    {
        $builder
            ->add('title', TextType::class, [
                'constraints' => [
                    new NotBlank(),
                    new Length(['min' => 5, 'max' => 200]),
                ]
            ])
            ->add('content', TextareaType::class)
            ->add('category', EntityType::class, [
                'class' => Category::class,
                'choice_label' => 'name',
            ]);
    }
}
```

Peningkatan dalam form handling termasuk validasi yang lebih intelligent dan error messages yang lebih descriptive.

---

## Integrasi PHP 8.4 {#integrasi-php-84}

### Property Hooks Deep Dive

Property Hooks menjadi game-changer dalam Symfony 8. Mari kita explore lebih dalam implementasinya:

```php
class Product
{
    public int $price {
        set(int $value) {
            if ($value < 0) {
                throw new DomainException('Price cannot be negative');
            }
            $this->price = $value;
        }
        get => $this->price;
    }
    
    public float $discountedPrice {
        get => $this->price * 0.9;
    }
}

$product = new Product();
$product->price = 100; // Set hook validates automatically
echo $product->discountedPrice; // Get hook computes value
```

Dalam konteks Doctrine dan Symfony:

```php
#[ORM\Entity]
class User
{
    #[ORM\Column]
    private string $firstName;
    
    #[ORM\Column]
    private string $lastName;
    
    #[ORM\Column]
    public string $fullName {
        get => $this->firstName . ' ' . $this->lastName;
        set(string $value) {
            [$first, $last] = explode(' ', $value, 2);
            $this->firstName = $first;
            $this->lastName = $last;
        }
    }
}
```

### Fifo Channels

PHP 8.4 memperkenalkan FIFO (First-In-First-Out) channels untuk concurrent processing. Symfony 8 memanfaatkan ini untuk messaging yang lebih efisien:

```php
// Dalam Symfony Messenger dengan dukungan channels
$message = new SendEmailMessage(
    email: 'user@example.com',
    subject: 'Welcome',
    priority: 'high'
);

$this->messageBus->dispatch($message);
```

### Typed Class Constants

PHP 8.4 memperkenalkan typed class constants yang dimanfaatkan Symfony 8:

```php
class UserRoles
{
    const int ADMIN = 1;
    const int USER = 2;
    const int GUEST = 3;
    
    const string ADMIN_LABEL = 'Administrator';
    const string USER_LABEL = 'Regular User';
}
```

---

## Peningkatan Performa {#peningkatan-performa}

### Container Compilation Optimization

Symfony 8 mengoptimalkan kompilasi service container, menghasilkan bootstrap time yang 15% lebih cepat:

```php
// Konfigurasi untuk optimasi container
// config/services.yaml
services:
    App\Service\UserService:
        shared: true
        lazy: true  # Lazy load ketika dibutuhkan
        
    App\Service\EmailService:
        autowire: true
        autoconfigure: true
```

### Cache System Revolution - 70% Performance Boost

Sistem cache di Symfony 8 mengalami revolutionary changes dengan implementasi MsgPack marshaller:

```php
use Symfony\Component\Cache\Adapter\RedisTagAwareAdapter;
use Symfony\Component\Cache\Marshaller\MsgPackMarshaller;

$cache = new RedisTagAwareAdapter(
    $redisConnection,
    namespace: 'app_v8',
    marshaller: new MsgPackMarshaller() // 40% less serialization overhead
);

// Tag-based cache invalidation
$cache->invalidateTags(['user:123', 'product:456']);

// Get cached item
$item = $cache->getItem('user_profile_123');
if (!$item->isHit()) {
    $item->set($this->getUserProfile(123));
    $cache->save($item);
}
```

Peningkatan cache performance mencakup:

- **MsgPack Serialization:** 40% lebih cepat dari JSON serialization
- **Tag-aware Caching:** Invalidate multiple related cache entries sekaligus
- **Atomic Operations:** Mengurangi race conditions dalam cache
- **Memory Efficiency:** Mengurangi memory footprint cache storage

### FrankenPHP Integration - 4x Faster Response Times

FrankenPHP adalah PHP app server yang written in Go yang mendukung worker mode. Symfony 8 mengintegrasikan FrankenPHP dengan sempurna:

```php
// public/index.php - Worker-compatible entry point
<?php

ignore_user_abort(true);

// Boot aplikasi sekali
require __DIR__.'/vendor/autoload.php';
$kernel = new \App\Kernel($_ENV['APP_ENV'] ?? 'dev', $_ENV['APP_DEBUG'] ?? false);
$kernel->boot();

// Handler untuk setiap request
$handler = static function () use ($kernel) {
    try {
        return $kernel->handle($_GET, $_POST, $_COOKIE, $_FILES, $_SERVER);
    } catch (\Throwable $exception) {
        // Error handling
        return response_error($exception);
    }
};

// Gunakan handler untuk request
frankenphp_handle_request($handler);
```

**Docker setup untuk FrankenPHP:**

```dockerfile
FROM dunglas/frankenphp:latest

WORKDIR /app

COPY . .

RUN composer install --no-dev --optimize-autoloader

ENV APP_RUNTIME=Runtime\\FrankenPhpSymfony\\Runtime
```

**docker-compose.yml:**

```yaml
services:
  app:
    build: .
    environment:
      - FRANKENPHP_CONFIG=worker ./public/index.php
      - APP_ENV=prod
      - APP_DEBUG=0
    ports:
      - "8000:80"
    volumes:
      - .:/app
```

Performance improvements dengan FrankenPHP:

- **4x faster response times** dalam worker mode
- **Automatic HTTP/2 dan HTTP/3** support
- **Built-in SSL certificate** management
- **Persistent application** state

### Doctrine ORM 3.4+ Integration

Symfony 8 dioptimalkan untuk bekerja dengan Doctrine ORM 3.4+ yang membawa peningkatan performance:

```php
// Lazy loading yang dioptimalkan
$users = $userRepository->findAll(); // Queries hanya untuk Users

foreach ($users as $user) {
    // Posts tidak di-load sampai di-akses
    echo count($user->getPosts()); // Query terjadi di sini (lazy load)
}
```

---

## Security dan Autentikasi {#security-dan-autentikasi}

### OAuth2 dan OpenID Connect Native Support

Symfony 8 memiliki dukungan native untuk OAuth2 dan OpenID Connect:

```yaml
# config/packages/security.yaml
security:
    providers:
        oidc_provider:
            oidc:
                server: 'https://identity-server.example.com'
                client_id: '%env(OIDC_CLIENT_ID)%'
                client_secret: '%env(OIDC_CLIENT_SECRET)%'
                
    firewalls:
        api:
            pattern: ^/api
            oauth2: true
            openid_connect: true
            
    access_control:
        - { path: ^/api, roles: IS_AUTHENTICATED_FULLY }
```

### JWT Authentication Simplified

JWT authentication di Symfony 8 jauh lebih sederhana:

```php
// config/packages/lexik_jwt_authentication.yaml
lexik_jwt_authentication:
    secret_key: '%env(resolve:JWT_SECRET_KEY)%'
    public_key: '%env(resolve:JWT_PUBLIC_KEY)%'
    pass_phrase: '%env(JWT_PASSPHRASE)%'
    
    token_extractors:
        authorization_header:
            enabled: true
        cookie:
            enabled: true
            name: BEARER
```

**Dalam Controller:**

```php
#[Route('/api/user', name: 'api_user', methods: ['GET'])]
#[IsGranted('IS_AUTHENTICATED_FULLY')]
public function getUser(#[CurrentUser] User $user): JsonResponse
{
    return $this->json([
        'id' => $user->getId(),
        'email' => $user->getEmail(),
        'roles' => $user->getRoles(),
    ]);
}
```

### Modernized Security Framework

Symfony 8 menghadirkan framework security yang lebih modern:

```php
class User implements UserInterface
{
    private ?string $password = null;
    private array $roles = ['ROLE_USER'];
    
    public function getPassword(): ?string
    {
        return $this->password;
    }
    
    public function setPassword(string $password): static
    {
        $this->password = $password;
        return $this;
    }
    
    public function getRoles(): array
    {
        return $this->roles;
    }
}

// Login process
$encodedPassword = $passwordHasher->hashPassword(
    $user,
    'plainTextPassword'
);
$user->setPassword($encodedPassword);
$entityManager->flush();
```

### Voter System untuk Authorization Granular

Symfony 8 memperkuat voter system untuk authorization yang lebih granular:

```php
#[AsVoter]
final class ArticleVoter extends Voter
{
    private const EDIT = 'EDIT';
    private const DELETE = 'DELETE';
    private const PUBLISH = 'PUBLISH';
    
    protected function supports(string $attribute, mixed $subject): bool
    {
        return in_array($attribute, [self::EDIT, self::DELETE, self::PUBLISH])
            && $subject instanceof Article;
    }
    
    protected function voteOnAttribute(
        string $attribute,
        mixed $subject,
        TokenInterface $token
    ): bool {
        $user = $token->getUser();
        
        return match($attribute) {
            self::EDIT => $this->canEdit($subject, $user),
            self::DELETE => $this->canDelete($subject, $user),
            self::PUBLISH => $this->canPublish($subject, $user),
            default => false,
        };
    }
    
    private function canEdit(Article $article, User $user): bool
    {
        return $article->getAuthor() === $user;
    }
    
    private function canDelete(Article $article, User $user): bool
    {
        return $article->getAuthor() === $user || in_array('ROLE_ADMIN', $user->getRoles());
    }
    
    private function canPublish(Article $article, User $user): bool
    {
        return in_array('ROLE_EDITOR', $user->getRoles());
    }
}

// Dalam Controller
#[Route('/articles/{id}/edit', name: 'article_edit')]
#[IsGranted('EDIT', subject: 'article')]
public function edit(Article $article): Response
{
    // Hanya author yang bisa edit artikel mereka
}
```

---

## Pengembangan API {#pengembangan-api}

### REST API dengan API Platform

Symfony 8 terintegrasi sempurna dengan API Platform untuk membuat REST API:

```php
use ApiPlatform\Metadata\ApiResource;
use ApiPlatform\Metadata\Get;
use ApiPlatform\Metadata\GetCollection;
use ApiPlatform\Metadata\Post;
use ApiPlatform\Metadata\Put;
use ApiPlatform\Metadata\Delete;

#[ApiResource(
    operations: [
        new Get(),
        new GetCollection(),
        new Post(),
        new Put(),
        new Delete(),
    ],
    paginationEnabled: true,
    paginationItemsPerPage: 20,
)]
#[ORM\Entity]
class Article
{
    #[ORM\Id]
    #[ORM\GeneratedValue]
    #[ORM\Column]
    private ?int $id = null;
    
    #[ORM\Column(length: 255)]
    #[Assert\NotBlank]
    #[Assert\Length(min: 5, max: 255)]
    private string $title = '';
    
    #[ORM\Column(type: 'text')]
    #[Assert\NotBlank]
    private string $content = '';
    
    #[ORM\Column]
    private \DateTimeImmutable $createdAt;
    
    #[ORM\ManyToOne]
    private User $author;
    
    // Getters dan setters...
}
```

**Hasil dari API Platform:**

```json
GET /api/articles HTTP/1.1

{
  "@context": "/api/contexts/Article",
  "@id": "/api/articles",
  "@type": "hydra:Collection",
  "hydra:member": [
    {
      "@id": "/api/articles/1",
      "@type": "Article",
      "id": 1,
      "title": "Hello World",
      "content": "...",
      "createdAt": "2025-11-27T09:11:00+00:00"
    }
  ],
  "hydra:totalItems": 1,
  "hydra:view": {
    "@id": "/api/articles?page=1",
    "@type": "hydra:PartialCollectionView",
    "hydra:first": "/api/articles?page=1",
    "hydra:last": "/api/articles?page=1",
    "hydra:next": "/api/articles?page=2"
  }
}
```

### GraphQL Support

Symfony 8 juga mendukung GraphQL melalui Overblog GraphQL Bundle:

```php
use Overblog\GraphQLBundle\Annotation as GQL;

#[GQL\Type]
class ArticleType
{
    #[GQL\Field(type: "ID!")]
    public function id(Article $article): int
    {
        return $article->getId();
    }
    
    #[GQL\Field(type: "String!")]
    public function title(Article $article): string
    {
        return $article->getTitle();
    }
    
    #[GQL\Field(type: "String!")]
    public function content(Article $article): string
    {
        return $article->getContent();
    }
}

#[GQL\Type(name: "Query")]
class QueryType
{
    #[GQL\Field(type: "[Article!]!")]
    public function articles(ArticleRepository $repository): array
    {
        return $repository->findAll();
    }
}
```

**GraphQL Query Example:**

```graphql
query {
  articles {
    id
    title
    content
  }
}
```

---

## Database dan Doctrine ORM {#database-dan-doctrine-orm}

### Entity Design dengan Property Hooks

Dengan Property Hooks, desain Entity menjadi lebih clean:

```php
#[ORM\Entity(repositoryClass: UserRepository::class)]
class User
{
    #[ORM\Id]
    #[ORM\GeneratedValue]
    #[ORM\Column]
    private int $id;
    
    #[ORM\Column(length: 255)]
    public string $email {
        set(string $value) {
            if (!filter_var($value, FILTER_VALIDATE_EMAIL)) {
                throw new InvalidArgumentException('Invalid email');
            }
            $this->email = strtolower($value);
        }
        get => $this->email;
    }
    
    #[ORM\Column(length: 255)]
    private string $firstName = '';
    
    #[ORM\Column(length: 255)]
    private string $lastName = '';
    
    public string $fullName {
        get => $this->firstName . ' ' . $this->lastName;
        set(string $value) {
            [$first, $last] = explode(' ', $value, 2);
            $this->firstName = $first;
            $this->lastName = $last;
        }
    }
    
    #[ORM\Column]
    private bool $isActive = true;
    
    #[ORM\OneToMany(mappedBy: 'author', targetEntity: Article::class)]
    private Collection $articles;
    
    public function __construct()
    {
        $this->articles = new ArrayCollection();
    }
}
```

### Relationship Management

Doctrine 3.4+ dengan Symfony 8 menyediakan relationship management yang superior:

```php
// Many-to-Many Relationship
#[ORM\Entity]
class Article
{
    #[ORM\ManyToMany(targetEntity: Category::class)]
    #[ORM\JoinTable(name: 'article_category')]
    private Collection $categories;
    
    public function addCategory(Category $category): self
    {
        if (!$this->categories->contains($category)) {
            $this->categories->add($category);
        }
        return $this;
    }
    
    public function removeCategory(Category $category): self
    {
        $this->categories->removeElement($category);
        return $this;
    }
    
    public function getCategories(): Collection
    {
        return $this->categories;
    }
}

// Polymorphic Relationship dengan Doctrine Inheritance
#[ORM\Entity]
#[ORM\InheritanceType('SINGLE_TABLE')]
#[ORM\DiscriminatorColumn(name: 'type', type: 'string')]
#[ORM\DiscriminatorMap(['article' => Article::class, 'video' => Video::class])]
abstract class Media
{
    #[ORM\Id]
    #[ORM\GeneratedValue]
    #[ORM\Column]
    protected int $id;
    
    #[ORM\Column]
    protected string $title;
}

#[ORM\Entity]
class Article extends Media
{
    #[ORM\Column(type: 'text')]
    private string $content;
}

#[ORM\Entity]
class Video extends Media
{
    #[ORM\Column]
    private string $url;
}
```

### Migrations dan Schema Management

```bash
# Generate migration otomatis
php bin/console make:migration

# Migrasi ke database
php bin/console doctrine:migrations:migrate

# Rollback migration
php bin/console doctrine:migrations:migrate prev

# Lihat status migrations
php bin/console doctrine:migrations:status
```

---

## Testing dan Quality Assurance {#testing-dan-quality-assurance}

### Unit Testing dengan PHPUnit

Symfony 8 menggunakan PHPUnit untuk testing dengan best practices modern:

```php
use PHPUnit\Framework\TestCase;
use PHPUnit\Framework\Attributes\DataProvider;
use PHPUnit\Framework\Attributes\Small;
use PHPUnit\Framework\Attributes\TestDox;

#[Small]
#[TestDox('User validation')]
final class UserValidationTest extends TestCase
{
    #[Test]
    #[TestDox('It should validate email format')]
    public function testEmailValidation(): void
    {
        $user = new User();
        
        $user->email = 'valid@example.com';
        $this->assertSame('valid@example.com', $user->email);
    }
    
    #[DataProvider('invalidEmailProvider')]
    #[Test]
    public function testInvalidEmail(string $email): void
    {
        $this->expectException(InvalidArgumentException::class);
        
        $user = new User();
        $user->email = $email;
    }
    
    public static function invalidEmailProvider(): array
    {
        return [
            ['invalid'],
            ['invalid@'],
            ['@example.com'],
            ['user@.com'],
        ];
    }
}
```

### Integration Testing

```php
use Symfony\Bundle\FrameworkBundle\Test\KernelTestCase;
use Symfony\Component\HttpFoundation\Response;

final class UserRepositoryTest extends KernelTestCase
{
    private UserRepository $userRepository;
    
    protected function setUp(): void
    {
        $kernel = self::bootKernel();
        $this->userRepository = $kernel->getContainer()
            ->get(UserRepository::class);
    }
    
    public function testFindByEmail(): void
    {
        $user = $this->userRepository->findByEmail('admin@example.com');
        
        $this->assertInstanceOf(User::class, $user);
        $this->assertSame('admin@example.com', $user->getEmail());
    }
}
```

### Functional Testing untuk Controllers dan APIs

```php
use Symfony\Bundle\FrameworkBundle\Test\WebTestCase;

final class ArticleControllerTest extends WebTestCase
{
    public function testCreateArticle(): void
    {
        $client = static::createClient();
        
        $client->request('POST', '/api/articles', [], [], [
            'CONTENT_TYPE' => 'application/json',
        ], json_encode([
            'title' => 'Test Article',
            'content' => 'This is a test article',
        ]));
        
        $this->assertResponseStatusCodeSame(201);
        
        $data = json_decode($client->getResponse()->getContent(), true);
        $this->assertSame('Test Article', $data['title']);
    }
    
    public function testGetArticles(): void
    {
        $client = static::createClient();
        $client->request('GET', '/api/articles');
        
        $this->assertResponseIsSuccessful();
        
        $data = json_decode($client->getResponse()->getContent(), true);
        $this->assertIsArray($data['hydra:member']);
    }
}
```

### Code Quality Tools

Symfony 8 terintegrasi dengan berbagai tools untuk quality assurance:

```bash
# PHPStan untuk static analysis
composer require --dev phpstan/phpstan
vendor/bin/phpstan analyse src/

# PHP CS Fixer untuk code style
composer require --dev friendsofphp/php-cs-fixer
vendor/bin/php-cs-fixer fix src/

# Psalm untuk type checking
composer require --dev vimeo/psalm
vendor/bin/psalm
```

---

## Docker dan Containerization {#docker-dan-containerization}

### Dockerfile Optimization untuk Symfony 8

```dockerfile
# Multi-stage build untuk optimasi size
FROM php:8.4-fpm-alpine AS base

RUN apk add --no-cache \
    zip \
    unzip \
    git \
    postgresql-client

WORKDIR /app

# Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/local/bin/composer

# Stage build untuk dependencies
FROM base AS vendor

COPY composer.json composer.lock ./
RUN composer install --no-dev --no-interaction --optimize-autoloader

# Production stage
FROM base AS production

RUN apk add --no-cache \
    postgresql \
    nginx

COPY --from=vendor /app/vendor ./vendor
COPY . .

RUN chmod +x bin/console

ENV APP_ENV=production
ENV APP_DEBUG=0

EXPOSE 80
CMD ["php-fpm"]
```

### Docker Compose untuk Development

```yaml
version: '3.8'

services:
  php:
    build:
      context: .
      dockerfile: Dockerfile.dev
    container_name: symfony_php
    working_dir: /app
    volumes:
      - .:/app
    environment:
      - DATABASE_URL=postgresql://user:password@postgres:5432/symfony
      - APP_ENV=dev
      - APP_DEBUG=1
    networks:
      - symfony
    depends_on:
      - postgres
      - redis

  nginx:
    image: nginx:alpine
    container_name: symfony_nginx
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - .:/app
      - ./docker/nginx/default.conf:/etc/nginx/conf.d/default.conf
    networks:
      - symfony
    depends_on:
      - php

  postgres:
    image: postgres:16-alpine
    container_name: symfony_postgres
    environment:
      - POSTGRES_DB=symfony
      - POSTGRES_USER=user
      - POSTGRES_PASSWORD=password
    volumes:
      - postgres_data:/var/lib/postgresql/data
    networks:
      - symfony

  redis:
    image: redis:7-alpine
    container_name: symfony_redis
    networks:
      - symfony

  adminer:
    image: adminer
    container_name: symfony_adminer
    ports:
      - "8080:8080"
    networks:
      - symfony
    depends_on:
      - postgres

volumes:
  postgres_data:

networks:
  symfony:
    driver: bridge
```

### FrankenPHP Docker Setup

```dockerfile
FROM dunglas/frankenphp:latest-alpine

WORKDIR /app

# Install additional dependencies
RUN apk add --no-cache \
    postgresql-client \
    curl

# Copy project
COPY . .

# Install dependencies
RUN composer install --no-dev --optimize-autoloader

# Set environment variables
ENV APP_ENV=production
ENV APP_DEBUG=0
ENV APP_RUNTIME=Runtime\\FrankenPhpSymfony\\Runtime

# Set permissions
RUN chown -R www-data:www-data /app

EXPOSE 80 443

CMD ["frankenphp", "run", "--listen", "0.0.0.0:80"]
```

---

## Migrasi dari Symfony 7 {#migrasi-dari-symfony-7}

### Pre-migration Checklist

Sebelum melakukan migrasi, pastikan:

1. **Backup database dan project**
   ```bash
   git tag pre-symfony8-migration
   git push origin pre-symfony8-migration
   ```

2. **Update ke PHP 8.4**
   ```bash
   php -v  # Pastikan PHP 8.4
   ```

3. **Update composer.json**

### Step-by-Step Migration

**Langkah 1: Update Symfony packages**

```bash
# Ubah composer.json untuk Symfony 8
# Semua symfony/* packages ke 8.0.*
# Jalankan update
composer update "symfony/*"
```

**Langkah 2: Update konfigurasi**

```yaml
# config/packages/framework.yaml
framework:
    version: '8.0'
    # Konfigurasi lainnya
```

**Langkah 3: Handle deprecated code**

```bash
# Jalankan deprecation analyzer
php bin/console debug:config | grep deprecated

# Gunakan rector untuk auto-fix
vendor/bin/rector process src/ --config rector.php
```

**Langkah 4: Update Environment Variables**

```bash
# .env
SYMFONY_VERSION=8.0
PHP_VERSION=8.4
DATABASE_URL=postgresql://user:password@localhost:5432/symfony_8
```

**Langkah 5: Clear cache**

```bash
# Linux/macOS/WSL
rm -rf var/cache/*

# Windows
rmdir /s /q var\cache\*

# Atau menggunakan command Symfony
php bin/console cache:clear
```

**Langkah 6: Run database migrations**

```bash
php bin/console doctrine:migrations:migrate
```

**Langkah 7: Testing**

```bash
# Run test suite
php bin/console test

# Atau dengan PHPUnit directly
vendor/bin/phpunit
```

### Breaking Changes yang Perlu Diperhatikan

1. **Configuration format deprecation:**
   - Fluent PHP config format dihapus
   - Gunakan YAML atau PHP array format

2. **Bundle changes:**
   - Beberapa bundle deprecated di Symfony 7 dihapus di Symfony 8
   - Check symfony/flex recipes untuk migration guides

3. **API changes:**
   - Beberapa method signature berubah
   - Interface implementations mungkin perlu diupdate

---

## Best Practices dan Patterns {#best-practices-dan-patterns}

### Service Container dan Dependency Injection

```php
// config/services.yaml
services:
    App\Service\UserService:
        autowire: true
        autoconfigure: true
        calls:
            - method: setUserRepository
              arguments:
                - '@App\Repository\UserRepository'
    
    App\Service\EmailService:
        autowire: true
        lazy: true  # Lazy load ketika dibutuhkan
    
    App\Repository\UserRepository:
        factory: ['@doctrine.orm.entity_manager', 'getRepository']
        arguments:
            - 'App\Entity\User'

    # Binding parameter otomatis
    App\Controller\:
        resource: '../src/Controller/'
        tags: ['controller.service_arguments']
        bind:
            $projectDir: '%kernel.project_dir%'
```

### Event-Driven Architecture

```php
// Entity events
#[ORM\Entity]
#[ORM\EntityListeners([ArticleListener::class])]
class Article
{
    #[ORM\PostPersist]
    #[ORM\PostUpdate]
    public function updated(): void
    {
        // Trigger custom logic
    }
}

// Event listeners
#[AsEventListener(event: 'article.created')]
final class OnArticleCreatedListener
{
    public function __invoke(ArticleCreatedEvent $event): void
    {
        // Handle article creation
    }
}

// Dispatch events
$event = new ArticleCreatedEvent($article);
$this->dispatcher->dispatch($event);
```

### Repository Pattern

```php
#[AsEntityRepository(Article::class)]
final class ArticleRepository extends ServiceEntityRepository
{
    public function __construct(ManagerRegistry $registry)
    {
        parent::__construct($registry, Article::class);
    }
    
    public function findPublishedArticles(): array
    {
        return $this->createQueryBuilder('a')
            ->where('a.isPublished = true')
            ->andWhere('a.publishedAt <= :now')
            ->setParameter('now', new \DateTimeImmutable())
            ->orderBy('a.publishedAt', 'DESC')
            ->getQuery()
            ->getResult();
    }
    
    public function findByAuthorAndCategory(User $author, Category $category): array
    {
        return $this->createQueryBuilder('a')
            ->join('a.categories', 'c')
            ->where('a.author = :author')
            ->andWhere('c = :category')
            ->setParameters([
                'author' => $author,
                'category' => $category,
            ])
            ->orderBy('a.createdAt', 'DESC')
            ->getQuery()
            ->getResult();
    }
}
```

### Form Handling Pattern

```php
#[Route('/articles/{id}/edit', name: 'article_edit', methods: ['GET', 'POST'])]
#[IsGranted('EDIT', subject: 'article')]
public function edit(
    Request $request,
    Article $article,
    EntityManagerInterface $em
): Response {
    $form = $this->createForm(ArticleFormType::class, $article);
    $form->handleRequest($request);
    
    if ($form->isSubmitted() && $form->isValid()) {
        $em->flush();
        
        $this->addFlash('success', 'Article updated successfully!');
        
        return $this->redirectToRoute('article_show', ['id' => $article->getId()]);
    }
    
    return $this->render('article/edit.html.twig', [
        'form' => $form,
        'article' => $article,
    ]);
}
```

### Console Command Pattern

```php
#[AsCommand(
    name: 'app:articles:publish',
    description: 'Publish pending articles',
)]
final class PublishArticlesCommand extends Command
{
    public function __construct(
        private readonly ArticleRepository $articleRepository,
        private readonly EntityManagerInterface $em,
    ) {
        parent::__construct();
    }
    
    protected function configure(): void
    {
        $this
            ->addArgument('limit', InputArgument::OPTIONAL, 'Number of articles to publish', 10)
            ->addOption('force', 'f', InputOption::VALUE_NONE, 'Force publish')
            ->setHelp('This command publishes pending articles...');
    }
    
    protected function execute(InputInterface $input, OutputInterface $output): int
    {
        $io = new SymfonyStyle($input, $output);
        $limit = (int) $input->getArgument('limit');
        
        $articles = $this->articleRepository->findPendingArticles($limit);
        
        if (empty($articles)) {
            $io->info('No pending articles found.');
            return Command::SUCCESS;
        }
        
        $progressBar = $io->createProgressBar(count($articles));
        
        foreach ($articles as $article) {
            $article->publish();
            $progressBar->advance();
        }
        
        $this->em->flush();
        $progressBar->finish();
        
        $io->success(sprintf('Published %d articles.', count($articles)));
        
        return Command::SUCCESS;
    }
}
```

---

## Penutup {#penutup}

Symfony Framework 8 merupakan lompatan signifikan dalam evolusi framework PHP terkemuka ini. Dengan mengintegrasikan fitur-fitur terbaru dari PHP 8.4, Symfony 8 menawarkan pengalaman pengembangan yang modern, performa yang luar biasa meningkat, dan tooling yang sangat produktif.

### Key Takeaways:

1. **Fitur-Fitur Modern:** Property Hooks, Lazy Objects, dan optimisasi Attributes membuat kode lebih clean dan maintainable.

2. **Performa Revolusioner:** Dengan kombinasi PHP 8.4 Lazy Objects, cache system yang dioptimalkan, dan integrasi FrankenPHP, Symfony 8 menawarkan peningkatan performa hingga 70% dalam beberapa kasus.

3. **Developer Experience:** Generator commands yang powerful, tooling yang ditingkatkan, dan dokumentasi yang komprehensif membuat pengembangan menjadi lebih cepat dan menyenangkan.

4. **Security First:** Dukungan native untuk OAuth2, OpenID Connect, dan JWT authentication memberikan fondasi keamanan yang kuat untuk aplikasi modern.

5. **API-First Approach:** Integrasi sempurna dengan API Platform dan dukungan GraphQL membuat Symfony 8 ideal untuk membangun microservices dan aplikasi headless.

6. **Containerization Ready:** Dukungan Docker yang superior dan integrasi FrankenPHP memudahkan deployment aplikasi Symfony 8 di lingkungan modern.

Bagi developer yang serius dengan pengembangan aplikasi web PHP production-grade, Symfony 8 adalah pilihan yang sangat solid dan merekomendasikan untuk dipertimbangkan dalam roadmap project Anda. Meskipun bukan LTS release, dukungan hingga July 2026 memberikan cukup waktu untuk upgrade ke LTS ketika Symfony 8.4 dirilis.

Langkah selanjutnya adalah memulai dengan dokumentasi resmi Symfony 8, bereksperimen dengan fitur-fitur baru, dan gradually mengintegrasikan Symfony 8 ke dalam project atau membuat project baru yang memanfaatkan semua kecanggihan yang ditawarkan framework ini.

---

## Referensi

1. Symfony Official Documentation (2025). "Symfony 8.0 Release". https://symfony.com/doc/8.0
2. Massive Art (2025). "Symfony 8: An overview of the new features". https://www.massiveart.com/en/blog/symfony-8
3. FSCK.sh (2025). "Symfony 8.0: November Release Delivers Massive Performance Improvements". https://fsck.sh/en/blog/symfony-8-november-release-performance/
4. Symfony (2025). "Symfony 8.0.0-BETA2 released". https://symfony.com/blog/symfony-8-0-0-beta2-released
5. Symfony (2025). "Symfony releases, notifications and release checker". https://symfony.com/releases
6. Never Code Alone (2025). "Symfony 8 Features: Property Hooks, Lazy Objects". https://blog.nevercodealone.de/symfony-8-diese-neuen-features-machen-den-unterschied-fuer-eure-projekte/
7. PHP 8.4 Property Hooks (2024). "PHP 8.4 Property Hooks". https://ashallendesign.co.uk/blog/php-84-property-hooks
8. Symfony (2025). "How to Use the Serializer (Symfony Docs)". https://symfony.com/doc/current/serializer.html
9. Symfony (2024). "Console Commands (Symfony Docs)". https://symfony.com/doc/current/console.html
10. FrankenPHP (2025). "FrankenPHP's worker mode". https://frankenphp.dev/docs/worker/
11. Evozon (2025). "Mastering Docker for Symfony Development". https://www.evozon.com/mastering-docker-for-symfony-development/
12. Curity (2024). "Securing a Symfony API with JWTs". https://curity.io/resources/learn/symfony-api/
13. Symfony (2024). "Testing (Symfony Docs)". https://symfony.com/doc/current/testing.html
14. Loïc Faugeron (2025). "PHPUnit Best Practices (Ultimate Guide)". https://gnugat.github.io/2025/07/31/phpunit-best-practices.html
15. Symfony (2024). "How to use Access Token Authentication". https://symfony.com/doc/current/security/access_token.html
16. Accesto (2024). "Mastering the Symfony Upgrade: A Step-by-Step Guide". https://accesto.com/blog/mastering-the-symfony-upgrade/