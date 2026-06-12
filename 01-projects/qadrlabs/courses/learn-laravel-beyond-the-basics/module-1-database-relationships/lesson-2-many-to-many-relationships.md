## 1. Before You Begin

One-to-many covers parent-child relationships where one side clearly owns the other. But some relationships are symmetrical: an entry can have many tags, and a tag can belong to many entries. Neither side "owns" the other. This is a many-to-many relationship, and it requires a third table (a pivot table) to store the connections between the two models.

This lesson teaches `belongsToMany`, pivot tables, and the `attach`, `detach`, `sync` methods for managing many-to-many relationships. You will add a tagging system to Catatku so users can categorize their journal entries with labels like "personal", "travel", or "work". By the end of the lesson you will be able to create entries with tags, edit those tags through checkboxes, and display them as colored badges.

### What You'll Build

You will create a Tag model, a pivot table, and integrate tag selection into the entry creation and editing forms. Tags will display as colored badges on each entry.

### What You'll Learn

- ✅ `belongsToMany()` on both models
- ✅ Pivot table migration and naming convention
- ✅ `attach()`, `detach()`, `sync()`, `toggle()`
- ✅ Querying many-to-many relationships
- ✅ Displaying tags in Blade views
- ✅ Tag selection with checkboxes in forms

### What You'll Need

- Lesson 1 completed with comments working

---

## 2. Create the Tag Model and Pivot Table

A many-to-many relationship requires three database tables: the two main tables (`entries` and `tags`) and a pivot table (`entry_tag`) that stores which entries have which tags. Each row in the pivot table represents one connection between an entry and a tag, so a single entry tagged with three labels will produce three rows in the pivot table.

### Step 1: Generate the Tag Model and Migration

Run the following command to create both the model and its migration file.

```bash
php artisan make:model Tag -m
```

This creates `app/Models/Tag.php` (the Eloquent model class) and a migration file in `database/migrations/` (the schema definition). The `-m` flag is the shortcut that asks Artisan to generate a migration alongside the model, saving you from running two separate commands.

### Step 2: Define the Tags Table Migration

Open the newly created migration file and replace the `up()` method with the following schema.

```php
public function up(): void
{
    Schema::create('tags', function (Blueprint $table) {
        $table->id();
        $table->string('name')->unique();
        $table->string('slug')->unique();
        $table->timestamps();
    });
}
```

Here is what each column does. `$table->id()` creates the auto-incrementing primary key named `id`. `$table->string('name')->unique()` creates a VARCHAR column for the display name (for example, "Personal" or "Travel") and adds a unique index so you cannot create two tags with the same name. `$table->string('slug')->unique()` stores the URL-friendly version of the name (like "personal" or "travel"), also unique, which you will later use in URLs like `/tags/personal`. `$table->timestamps()` adds `created_at` and `updated_at` columns that Eloquent manages automatically.

### Step 3: Create the Pivot Table Migration

The pivot table connects entries to tags. Generate a separate migration for it.

```bash
php artisan make:migration create_entry_tag_table
```

Open the new migration file and define the pivot table schema.

```php
public function up(): void
{
    Schema::create('entry_tag', function (Blueprint $table) {
        $table->id();
        $table->foreignId('entry_id')->constrained()->cascadeOnDelete();
        $table->foreignId('tag_id')->constrained()->cascadeOnDelete();
        $table->timestamps();
    });
}

public function down(): void
{
    Schema::dropIfExists('entry_tag');
}
```

The pivot table name follows Laravel's convention: the two model names in alphabetical order, both singular, separated by an underscore. "Entry" comes before "Tag" alphabetically, so the table is named `entry_tag`. Let us examine each column. The `id()` gives every pivot row a primary key (some developers skip this on pivot tables, but having it makes debugging easier). The `foreignId('entry_id')->constrained()->cascadeOnDelete()` creates the `entry_id` column with a foreign key pointing to `entries.id`, and `cascadeOnDelete()` ensures that deleting an entry automatically removes all its pivot rows. The `foreignId('tag_id')->constrained()->cascadeOnDelete()` does the same for the tag side. `timestamps()` lets you track when each tag was added to an entry. The `down()` method drops the whole pivot table if you roll back.

### Step 4: Run Both Migrations

Execute the migrations to create both new tables in the database.

```bash
php artisan migrate
```

You should see output confirming both the `tags` table and the `entry_tag` table were created. If either migration fails, check that your `entries` table already exists (from the beginner course) so the foreign key constraint can point to it.

---

## 3. Define the Relationships

Both models need `belongsToMany()` because the relationship is symmetrical. An entry can have many tags, and a tag can belong to many entries. Unlike one-to-many, there is no "parent" or "child" here, so both sides use the same relationship type.

### Step 1: Update the Entry Model

Open `app/Models/Entry.php` and add the `tags()` relationship method inside the class body.

```php
<?php

// ... others lines of code

use Illuminate\Database\Eloquent\Relations\BelongsToMany;


#[Fillable(['title', 'content'])]
class Entry extends Model
{
    // ... other methods and properties

    public function tags(): BelongsToMany
    {
        return $this->belongsToMany(Tag::class)->withTimestamps();
    }
}
```

Examining this code closely: the `use` statement imports `BelongsToMany` so you can type-hint the return. The method is named `tags` because that becomes the property and method name you will use elsewhere: `$entry->tags` (collection) or `$entry->tags()` (query builder). Inside, `$this->belongsToMany(Tag::class)` tells Eloquent this entry can have many tags through a pivot table. Laravel automatically finds the pivot table using the naming convention (`entry_tag`), so you do not need to specify it. The `withTimestamps()` chained call tells Laravel that the pivot table has `created_at` and `updated_at` columns and to keep them updated; without this, those columns on the pivot table would remain NULL even though they exist.

### Step 2: Define the Tag Model

Open `app/Models/Tag.php` and replace its content with the following.

```php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;

#[Fillable(['name', 'slug'])]
class Tag extends Model
{
    public function entries(): BelongsToMany
    {
        return $this->belongsToMany(Entry::class)->withTimestamps();
    }
}
```

The Tag model mirrors the Entry relationship because many-to-many is symmetrical. The `#[Fillable(['name', 'slug'])]` attribute lists `name` and `slug` as mass-assignable fields so you can create tags with `Tag::create(['name' => 'Personal', 'slug' => 'personal'])`. The `entries()` method defines the inverse side of the relationship so you can call `$tag->entries` to get all entries that use this tag. Both calls ultimately query the same `entry_tag` pivot table but start from different directions.

---

## 4. Seed Some Tags

Before building the UI, let us create some tags to work with. Seeding means populating the database with initial data, and you can do it interactively through Tinker without writing a full seeder class.

### Step 1: Create Tags in Tinker

Launch Tinker from your terminal.

```bash
php artisan tinker
```

Once inside Tinker, run the following commands to insert five tags into the database.

```php
use App\Models\Tag;

Tag::create(['name' => 'Personal', 'slug' => 'personal']);

Tag::create(['name' => 'Travel', 'slug' => 'travel']);

Tag::create(['name' => 'Work', 'slug' => 'work']);

Tag::create(['name' => 'Ideas', 'slug' => 'ideas']);

Tag::create(['name' => 'Gratitude', 'slug' => 'gratitude']);
```

Each `Tag::create(...)` call inserts a row into the `tags` table. The `use` statement at the top lets you write `Tag::create` instead of the full class path. Type `exit` to leave Tinker. You now have five tags in the database, which is enough variety to test the tagging feature.

---

## 5. Managing Tags on Entries

The four key methods for managing many-to-many relationships are `attach`, `detach`, `sync`, and `toggle`. Each serves a different purpose, and you will use `sync` the most because it matches form behavior perfectly: it replaces the entire set of associations in one call.

### Step 1: Update the Entry Controller

Open your `EntryController.php` and update the `create`, `store`, `edit`, and `update` methods to handle tags.

In the `create` method, pass all tags to the view so the form can render checkboxes for each one.

```php
use App\Models\Tag;

public function create()
{
    $tags = Tag::orderBy('name')->get();

    return view('entries.create', compact('tags'));
}
```

This method fetches all tags alphabetically so the form checkboxes appear in predictable order. The `orderBy('name')` clause sorts by the name column ascending (the default), and `get()` executes the query. The view receives the tags collection as `$tags`.

In the `store` method, sync the selected tags after creating the entry.

```php
public function store(Request $request)
{
    $validated = $request->validate([
        'title' => 'required|string|max:255',
        'content' => 'required|string',
        'tags' => 'nullable|array',
        'tags.*' => 'exists:tags,id',
    ]);

    $entry = $request->user()->entries()->create([
        'title' => $validated['title'],
        'content' => $validated['content'],
    ]);

    $entry->tags()->sync($validated['tags'] ?? []);

    return redirect()->route('entries.index')->with('success', 'Entry created!');
}
```

Breaking this down carefully: the validation rule `'tags' => 'nullable|array'` allows the tags field to be an array of IDs or absent entirely (users can create entries without tags). The `'tags.*' => 'exists:tags,id'` rule applies to every element of the array using the `*` wildcard, and `exists:tags,id` verifies that each submitted ID really exists as a row in the `tags` table, preventing invalid data or malicious submissions. After validation, `$request->user()->entries()->create(...)` creates a new entry owned by the authenticated user, automatically setting `user_id`. The critical line is `$entry->tags()->sync($validated['tags'] ?? [])`: the `sync()` method replaces all existing tag associations with the submitted ones. If the user unchecks a tag, `sync()` removes it from the pivot table. If they check a new one, `sync()` adds it. The `?? []` null coalescing operator uses an empty array as fallback when the user submitted no tags at all.

In the `edit` method, pass the entry and all tags so the form can pre-check existing selections. Keep the authorization check from the basic course.

```php
public function edit(Entry $entry)
{
    if ($entry->user_id !== auth()->id()) {
        abort(403);
    }

    $tags = Tag::orderBy('name')->get();

    return view('entries.edit', compact('entry', 'tags'));
}
```

The edit method preserves the authorization guard from the basic course and adds the `$tags` variable so the form can render checkboxes.

In the `update` method, sync tags after updating the entry fields. Keep the authorization check and the original redirect target.

```php
public function update(Request $request, Entry $entry)
{
    if ($entry->user_id !== auth()->id()) {
        abort(403);
    }

    $validated = $request->validate([
        'title' => 'required|string|max:255',
        'content' => 'required|string',
        'tags' => 'nullable|array',
        'tags.*' => 'exists:tags,id',
    ]);

    $entry->update([
        'title' => $validated['title'],
        'content' => $validated['content'],
    ]);

    $entry->tags()->sync($validated['tags'] ?? []);

    return redirect()->route('entries.show', $entry)->with('success', 'Entry updated!');
}
```

The update method follows the same pattern as store: validate, update the entry fields, then sync the tags. Using `sync()` for both create and update means the same logic handles both cases cleanly. If the user started with tags Personal and Travel and submits the form with Personal and Work checked, `sync()` calculates the diff and updates only what changed.

### Step 2: Add Tag Checkboxes to the Form

Open `resources/views/entries/create.blade.php` (or your entry form view) and add a tag selection section below the content textarea.

```blade
{{-- Tag selection --}}
<div style="margin-bottom: 16px;">
    <label style="display: block; font-weight: bold; margin-bottom: 6px; color: #1e293b;">Tags</label>
    <div style="display: flex; flex-wrap: wrap; gap: 10px;">
        @foreach ($tags as $tag)
            <label style="display: flex; align-items: center; gap: 4px; cursor: pointer;">
                <input
                    type="checkbox"
                    name="tags[]"
                    value="{{ $tag->id }}"
                    @checked(is_array(old('tags')) && in_array($tag->id, old('tags')))
                >
                {{ $tag->name }}
            </label>
        @endforeach
    </div>
</div>
```

Walking through this view: the outer `<div>` wraps the whole section. The `<label>` at the top labels the group. The `@foreach` loop iterates over the tags collection you passed from the controller. Each iteration renders a `<label>` wrapping a checkbox so clicking the tag name toggles the checkbox. The critical attribute is `name="tags[]"`: the `[]` tells PHP to collect all checked boxes into an array under the `tags` key in the form submission. The `value="{{ $tag->id }}"` sets what gets submitted when checked. The `@checked(...)` Blade directive conditionally adds the `checked` attribute when its expression is truthy; here it checks whether `old('tags')` (the previously submitted values, used to repopulate after validation failure) is an array and contains this tag's ID.

For the edit form (`entries/edit.blade.php`), the `@checked` directive needs to account for both old input and existing tags.

```blade
@checked(
    (is_array(old('tags')) && in_array($tag->id, old('tags')))
    || (!old('tags') && $entry->tags->contains($tag->id))
)
```

This more complex condition handles two scenarios. The first part handles the case where the user just submitted the form and validation failed, so we want to restore their checkbox selections from old input. The second part handles the first page load when there is no old input, so we pre-check the tags that the entry currently has. The `||` combines them so the checkbox is checked if either condition is true.

---

## 6. Display Tags in the Entry Views

Tags should appear as colored badges on each entry in the feed and on the detail page so users can see at a glance how each entry is categorized.

### Step 1: Update the Index Controller Method

Open `EntryController.php` and update the `index` method to load tags alongside entries using eager loading.

```php
public function index()
{
    $entries = auth()->user()->entries()
        ->with('tags')
        ->withCount('comments')
        ->latest()
        ->get();

    return view('entries.index', compact('entries'));
}
```

The key addition here is `->with('tags')`, which eager loads all tags for each entry in a single query. Without it, displaying tags in a loop would trigger a new query for every entry (the N+1 problem that Lesson 4 covers in detail). `withCount('comments')` adds a `comments_count` attribute cheaply via a subquery. `latest()` orders by `created_at` descending so newest entries appear first. `get()` executes the full query and returns a Collection.

### Step 2: Display Tags in the View

Open `resources/views/components/entry-card.blade.php` and add the following block below the content snippet section and above the action buttons section.

```blade
{{-- Tags --}}
@if($entry->tags->isNotEmpty())
    <div style="margin-top: 8px; display: flex; flex-wrap: wrap; gap: 4px;">
        @foreach ($entry->tags as $tag)
            <span style="background: #dbeafe; color: #1e40af; padding: 2px 10px; border-radius: 12px; font-size: 0.75em; font-weight: 600;">
                {{ $tag->name }}
            </span>
        @endforeach
    </div>
@endif
```

Looking at this carefully: the `@if($entry->tags->isNotEmpty())` check prevents rendering an empty container when an entry has no tags, because `isNotEmpty()` returns false on empty collections. The `@foreach` loops through the tags collection that was eager loaded. Each tag becomes a `<span>` styled to look like a pill badge: light blue background, darker blue text, rounded corners, small padding, and semibold font weight.

---

## 7. Run and Test

Let us verify the complete tagging system works end to end.

### Step 1: Start the Server

Run the development server with the following command and keep it running throughout your testing.

```bash
php artisan serve
```

Keep this terminal open; the server runs as long as this command is active.

### Step 2: Create an Entry with Tags

Open `http://localhost:8000` in the browser and log in. Navigate to the create entry page. You should see the tag checkboxes arranged horizontally below the content textarea. Write a journal entry with a title like "Weekend in Bandung" and some content, then check both "Personal" and "Travel". Click submit. You should be redirected to the entries feed with a success message, and the entry should appear with two blue tag badges next to it.

### Step 3: Edit Tags

Click the edit button on the entry you just created. Notice that "Personal" and "Travel" checkboxes are already pre-checked because of the `@checked` directive logic. Uncheck "Travel" and check "Work" instead. Save. The entry should now show "Personal" and "Work" badges but no "Travel" badge. This proves that `sync()` correctly added the new tag and removed the old one.

### Step 4: Create an Entry Without Tags

Try creating a new entry without selecting any tags. After saving, the entry should appear in the feed without any tag badges, confirming that the `@if($entry->tags->isNotEmpty())` check works.

### Step 5: Verify in Tinker

Open a new terminal and launch Tinker to inspect the relationships from the command line.

```bash
php artisan tinker
```

Run the following commands one at a time to verify the relationship works from both directions.

```php
$entry = \App\Models\Entry::with('tags')->first();
$entry->tags->pluck('name');

$tag = \App\Models\Tag::where('slug', 'personal')->first();
$tag->entries->count();
```

The first block fetches the first entry with its tags eager loaded, then uses `pluck('name')` to extract just the tag names into a simple array for easy reading. The second block looks up the Personal tag by slug, then counts all entries associated with it, proving the relationship works from the tag side as well. Type `exit` to leave Tinker.

---

## 8. Fix the Errors in Your Code

These are the most common mistakes when working with many-to-many relationships. Understanding them now will save you from confusing database errors later.

**Error 1: Wrong pivot table name.**

This error occurs when you create the pivot table with a name that does not follow Laravel's alphabetical, singular convention. When the table name does not match what Eloquent expects, every query through the relationship will fail with a "table not found" error.

```php
// Wrong: table named in wrong order
Schema::create('tags_entries', function (Blueprint $table) {
    $table->id();
    $table->foreignId('entry_id')->constrained()->cascadeOnDelete();
    $table->foreignId('tag_id')->constrained()->cascadeOnDelete();
    $table->timestamps();
});

// Correct: alphabetical order, singular model names
Schema::create('entry_tag', function (Blueprint $table) {
    $table->id();
    $table->foreignId('entry_id')->constrained()->cascadeOnDelete();
    $table->foreignId('tag_id')->constrained()->cascadeOnDelete();
    $table->timestamps();
});
```

The wrong version names the table `tags_entries`, which reverses alphabetical order and uses plural names. Eloquent cannot find the pivot table automatically and the relationship fails. The correct version uses `entry_tag` because "Entry" comes before "Tag" alphabetically. If you must use a custom name, you can specify it as the second argument to `belongsToMany`: `$this->belongsToMany(Tag::class, 'my_custom_table')`.

---

**Error 2: Creating duplicate pivot entries with `attach()`.**

This error happens when you call `attach()` in a loop or call it twice for the same ID, creating duplicate rows in the pivot table. If you have a unique constraint on the pivot columns, this produces an SQL integrity constraint violation.

```php
// Wrong: attach called twice for the same tag
$entry->tags()->attach(1);
$entry->tags()->attach(1);

// Correct: use sync() to replace all associations at once
$entry->tags()->sync([1, 2, 3]);
```

The wrong version calls `attach(1)` twice, inserting duplicate pivot rows, which breaks uniqueness if enforced and corrupts the data if not. The correct version uses `sync()`, which handles the comparison internally: it adds IDs that are not yet present and removes IDs that were removed. If you want to add a tag without affecting others and without risking duplicates, use `syncWithoutDetaching([1])` instead.

---

**Error 3: Null timestamps on the pivot table.**

This error occurs when your pivot table has `created_at` and `updated_at` columns but you forget to add `withTimestamps()` to the relationship definition. Laravel does not know to populate those columns, so they remain NULL on every row.

```php
// Wrong: withTimestamps() is missing
public function tags(): BelongsToMany
{
    return $this->belongsToMany(Tag::class);
}

// Correct: withTimestamps() tells Laravel to manage the pivot timestamps
public function tags(): BelongsToMany
{
    return $this->belongsToMany(Tag::class)->withTimestamps();
}
```

Without `withTimestamps()`, every insert through `attach()` or `sync()` leaves `created_at` and `updated_at` as NULL even though the columns exist. Adding `withTimestamps()` makes Laravel populate them automatically. Add it to both sides of the relationship for consistency.

---

## 9. Exercises

**Exercise 1:** Create a "tag cloud" page at `/tags` that lists all tags with the number of entries for each. Use `Tag::withCount('entries')->orderBy('name')->get()` in the controller and display each tag with its count.

**Exercise 2:** Create a route `/tags/{slug}` that shows all entries with a specific tag. In the controller, find the tag by slug, then use `$tag->entries()->with('user')->latest()->paginate(10)` to get the entries.

**Exercise 3:** Add the ability to create new tags inline. Add a text input in the entry form where users can type a new tag name. In the controller, use `Tag::firstOrCreate(['name' => $name, 'slug' => Str::slug($name)])` before syncing.

---

## 10. Solutions

**Solution for Exercise 1:**

Create a `TagController` with an `index` method and a `show` method. In the `index` method, fetch all tags with their entry counts.

```php
public function index()
{
    $tags = Tag::withCount('entries')->orderBy('name')->get();

    return view('tags.index', compact('tags'));
}
```

The `withCount('entries')` method adds an `entries_count` attribute to each tag without loading all the entry records. It is a cheap subquery that only returns the count. In the view, loop through the tags and display each name alongside its count.

```blade
@foreach ($tags as $tag)
    <div>
        <span style="font-weight: bold;">{{ $tag->name }}</span>
        <span style="color: #888;">({{ $tag->entries_count }} entries)</span>
    </div>
@endforeach
```

Each `$tag->entries_count` reads the virtual attribute that `withCount` injected onto the model. No additional query runs when the view accesses it.

---

**Solution for Exercise 2:**

Register the route using the `{tag:slug}` syntax so Laravel resolves the Tag by its slug column instead of `id`.

```php
Route::get('/tags/{tag:slug}', [TagController::class, 'show'])->name('tags.show');
```

The `{tag:slug}` syntax tells Laravel to look up the Tag by its `slug` column, giving you friendly URLs like `/tags/travel` instead of `/tags/3`. In the TagController, add the show method.

```php
public function show(Tag $tag)
{
    $entries = $tag->entries()->with('user')->latest()->paginate(10);

    return view('tags.show', compact('tag', 'entries'));
}
```

The controller uses route model binding to receive the resolved `Tag` directly. It then queries `$tag->entries()` as a query builder (with parentheses) so it can chain `with('user')`, `latest()`, and `paginate(10)` before executing. The `with('user')` eager loads each entry's author to avoid N+1 queries in the view.

---

**Solution for Exercise 3:**

In the entry form, add a text input below the checkboxes where users can type a new tag name.

```blade
<div style="margin-top: 10px;">
    <label style="display: block; font-size: 0.85em; color: #555; margin-bottom: 4px;">
        Or add a new tag:
    </label>
    <input
        type="text"
        name="new_tag"
        placeholder="e.g. Fitness"
        style="padding: 6px 10px; border: 1px solid #d1d5db; border-radius: 6px; width: 200px;"
    >
</div>
```

In the `store` and `update` methods of `EntryController`, add the following block before calling `sync()`.

```php
use Illuminate\Support\Str;

$tagIds = $validated['tags'] ?? [];

if ($request->filled('new_tag')) {
    $newTag = Tag::firstOrCreate(
        ['slug' => Str::slug($request->input('new_tag'))],
        ['name' => trim($request->input('new_tag'))]
    );
    $tagIds[] = $newTag->id;
}

$entry->tags()->sync($tagIds);
```

`Tag::firstOrCreate()` accepts two arrays: the first is the search condition (find by slug), and the second is the extra data used only when creating a new record. `Str::slug()` converts the typed name into a URL-safe slug (for example, "My Ideas" becomes "my-ideas"). If a tag with that slug already exists, `firstOrCreate()` returns the existing record instead of inserting a duplicate. The new tag's ID is then appended to the `$tagIds` array before `sync()` runs, so the inline-created tag is included in the final association.

---

## Next Up - Lesson 3

In this lesson you built a complete many-to-many tagging system. You created a `tags` table and an `entry_tag` pivot table following Laravel's alphabetical, singular naming convention. You defined `belongsToMany()` on both the Entry and Tag models, used `sync()` to replace tag associations when a form is submitted, and validated submitted tag IDs with the `exists:tags,id` rule. You also learned the difference between `attach`, `detach`, `sync`, and `toggle`, and when to use each one.

In Lesson 3, you will learn scopes, accessors, and mutators: how to define reusable query filters directly on the Entry model, how to transform data on read with accessors, and how to clean input automatically on write with mutators.