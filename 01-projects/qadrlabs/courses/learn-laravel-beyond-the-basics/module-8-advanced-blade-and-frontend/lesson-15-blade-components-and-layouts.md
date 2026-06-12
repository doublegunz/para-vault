## 1. Before You Begin

Take a look at your Blade views for Catatku. You likely see repeating patterns: the same button styling in multiple places, similar alert boxes with slightly different colors, the same entry card repeated across several pages. Copying and pasting HTML creates maintenance headaches: when the design changes, you hunt through every file to update every copy. Blade components solve this by packaging reusable chunks of UI into named components with their own parameters.

This lesson teaches you to create Blade components, pass data to them through attributes, and use slots for flexible content. You have already used components in email templates (`<x-mail::button>` in Lesson 8). Now you will apply the same idea to regular views. By the end, Catatku's templates will be cleaner, duplication will be gone, and design changes will require editing one file instead of ten.

### What You'll Build

You will create a Button component, an Alert component, and an EntryCard component. You will use slots for flexible content and attribute passing for customization. You will refactor existing views to use these components.

### What You'll Learn

- ✅ Creating components with `make:component`
- ✅ Anonymous components (view-only) vs class-based components
- ✅ Passing data via attributes and the constructor
- ✅ Default and named slots
- ✅ `$attributes` for pass-through HTML attributes

### What You'll Need

- Lesson 14 completed

---

## 2. Anonymous Components

The simplest component is a Blade file in `resources/views/components/`. No PHP class is needed. These are called anonymous components because they have no backing class, just a template file. They are perfect for UI elements that do not need computed logic.

### Step 1: Create a Button Component

Create the file `resources/views/components/button.blade.php` with the following content.

```
@props([
    'type' => 'button',
    'variant' => 'primary',
])

@php
    $classes = match($variant) {
        'primary' => 'background: #2563eb; color: white;',
        'danger' => 'background: #dc2626; color: white;',
        'secondary' => 'background: #e5e7eb; color: #1f2937;',
        default => 'background: #2563eb; color: white;',
    };
@endphp

<button
    type="{{ $type }}"
    {{ $attributes->merge(['style' => "padding: 8px 20px; border: none; border-radius: 6px; cursor: pointer; font-weight: bold; {$classes}"]) }}
>
    {{ $slot }}
</button>
```

Let us walk through this component thoughtfully because there are several Blade-specific features at work here. The `@props([...])` directive declares the accepted props and their default values, similar to a function signature. This component accepts two props: `type`, which defaults to `"button"` (so regular buttons do not accidentally submit forms), and `variant`, which defaults to `"primary"`. Props are automatically extracted from the attribute list passed by the caller, so writing `<x-button variant="danger">` puts `"danger"` into the `$variant` variable inside the component.

The `@php ... @endphp` block performs inline PHP logic to map the variant name to inline CSS using a PHP 8 `match` expression. The `match` expression is cleaner than if/elseif chains and requires exhaustive matching via a `default` clause. The `<button>` tag uses `{{ $attributes->merge([...]) }}`, which is a Blade helper that takes any HTML attributes not consumed by the declared props (like `onclick`, `disabled`, or `class`) and merges them with the base style. This pass-through mechanism is what makes components flexible: callers can add any HTML attribute and it flows through to the rendered element. Finally, `{{ $slot }}` renders whatever content the caller places between the opening and closing tags.

### Step 2: Use the Button Component

Open `resources/views/entries/create.blade.php`. At the bottom of the form in the Buttons section, replace the raw `<button type="submit">` element with the component.

```
<x-button type="submit" variant="primary">
    Save Entry
</x-button>
```

The syntax `<x-button>` is how Blade references components. The `x-` prefix tells Blade this is a component, not a native HTML element. The `type` and `variant` attributes map to the declared props. Everything between the opening and closing tags becomes the `$slot` content. Refresh the page in the browser to confirm the button renders with the expected styling.

After the change, the full `create.blade.php` looks like this:

```blade
<x-layout title="Write Entry — Catatku">

    <div class="mb-6">
        <a href="{{ route('entries.index') }}" class="text-sm text-gray-400 hover:text-gray-700">
            ← Back to list
        </a>
    </div>

    <h2 class="text-lg font-semibold text-gray-900 mb-4">Write New Entry</h2>

    <div class="bg-white rounded-xl border border-gray-200 p-6">
        <form method="POST" action="{{ route('entries.store') }}">
            @csrf

            <div class="mb-5">
                <label for="title" class="block text-sm font-medium text-gray-700 mb-1">
                    Title
                </label>
                <input type="text" id="title" name="title" value="{{ old('title') }}" placeholder="Entry title..."
                    class="w-full px-3 py-2 border rounded-lg text-sm focus:outline-none
                           focus:ring-2 focus:ring-gray-900 focus:border-transparent
                           {{ $errors->has('title') ? 'border-red-400 bg-red-50' : 'border-gray-300' }}" autofocus>
                @error('title')
                <p class="text-xs text-red-500 mt-1">{{ $message }}</p>
                @enderror
            </div>

            <div class="mb-6">
                <label for="content" class="block text-sm font-medium text-gray-700 mb-1">
                    Content
                </label>
                <textarea id="content" name="content" rows="12" placeholder="Write your entry here..."
                    class="w-full px-3 py-2 border rounded-lg text-sm focus:outline-none
                           focus:ring-2 focus:ring-gray-900 focus:border-transparent resize-y
                           {{ $errors->has('content') ? 'border-red-400 bg-red-50' : 'border-gray-300' }}">{{ old('content') }}</textarea>
                @error('content')
                <p class="text-xs text-red-500 mt-1">{{ $message }}</p>
                @enderror
            </div>

            <div class="flex items-center justify-between">
                <a href="{{ route('entries.index') }}" class="text-sm text-gray-500 hover:text-gray-900">
                    Cancel
                </a>
                <x-button type="submit" variant="primary">
                    Save Entry
                </x-button>
            </div>

        </form>
    </div>

</x-layout>
```

---

## 3. Components with Slots

Slots make components flexible. The `$slot` variable holds the primary content placed between the component's tags. You can also define named slots for multiple content regions. This is particularly useful for card-like components that need separate sections for a title, body, and footer.

### Step 1: Create an Alert Component

Create the file `resources/views/components/alert.blade.php` with the following content.

```
@props([
    'type' => 'info',
])

@php
    $colors = match($type) {
        'success' => 'background: #dcfce7; color: #166534; border-left: 4px solid #16a34a;',
        'error' => 'background: #fee2e2; color: #991b1b; border-left: 4px solid #dc2626;',
        'warning' => 'background: #fef3c7; color: #92400e; border-left: 4px solid #d97706;',
        default => 'background: #dbeafe; color: #1e3a8a; border-left: 4px solid #2563eb;',
    };
@endphp

<div {{ $attributes->merge(['style' => "padding: 12px 16px; border-radius: 6px; margin-bottom: 16px; {$colors}"]) }}>
    @if (isset($title))
        <strong style="display: block; margin-bottom: 4px;">{{ $title }}</strong>
    @endif
    {{ $slot }}
</div>
```

The alert component introduces a pattern for optional named slots. The `@if (isset($title))` check verifies whether the caller provided a `title` slot. If they did, we render it as a bold heading above the main content. If not, the alert renders with only the main body. This pattern lets the same component serve both simple one-line alerts and more detailed alerts with a visible title. The four color variants (success is green, error is red, warning is orange, info is the blue default) use a colored `border-left` accent that reinforces the semantic meaning of each alert type.

To pass a named slot, include an `<x-slot:title>` tag inside the component tags. Everything outside a named slot tag automatically fills the default `$slot`.

```blade
<x-alert type="success">
    <x-slot:title>Entry Created!</x-slot:title>
    Your new entry has been saved successfully.
</x-alert>
```

The `<x-slot:title>` tag fills the `$title` named slot inside the component. The `:title` part links to the variable name used in the `isset($title)` check inside the template.

When no `title` slot is passed, the component gracefully skips the heading and renders only the body text.

```blade
<x-alert type="error">
    Something went wrong. Please try again.
</x-alert>
```

Since no `<x-slot:title>` tag is present, `isset($title)` returns false and the heading element is omitted entirely. Named slots are always optional when guarded with `isset()`.

---

## 4. Class-Based Components

Some components need PHP logic: formatting data, making decisions, or computing values. Class-based components let you define a PHP class alongside the template, keeping complex logic out of the template itself.

### Step 1: Generate a Component

Run the following Artisan command to create a class-based component.

```bash
php artisan make:component EntryCard
```

This command creates one new file: `app/View/Components/EntryCard.php`, the PHP class containing the component's logic. You will see a success message confirming the class was created.

If `resources/views/components/entry-card.blade.php` already exists from the beginner Catatku course, Laravel will print `ERROR  View already exists.` and skip creating the view file. This is expected behavior and does not prevent you from continuing. The existing view file stays in place, and you will replace its content entirely in Step 3. The important output to confirm is `Component [app/View/Components/EntryCard.php] created successfully.`

### Step 2: Define the Component Class

Open `app/View/Components/EntryCard.php` and replace its content with the following.

```php
<?php

namespace App\View\Components;

use App\Models\Entry;
use Illuminate\View\Component;
use Illuminate\View\View;

class EntryCard extends Component
{
    public function __construct(public Entry $entry) {}

    public function truncatedTitle(): string
    {
        return str($this->entry->title)->limit(50)->toString();
    }

    public function render(): View
    {
        return view('components.entry-card');
    }
}
```

Reading this class carefully: the constructor uses property promotion to accept and store an Entry model. Public properties and public methods on the component class are automatically available inside the Blade template, which is why we can call `{{ $truncatedTitle() }}` from the view without passing it explicitly. The `truncatedTitle()` method shows how to add computed logic: it uses Laravel's fluent string helper `str()` to limit the title to 50 characters, returning a plain string. The `render()` method tells Laravel which template to use; by convention it is the kebab-case version of the class name in the `components` directory.

### Step 3: Write the Template

Open `resources/views/components/entry-card.blade.php` and replace its content with the following. This template preserves all the action buttons from the existing file (Read, Edit, Delete) and adds the `$truncatedTitle()` method from the class.

```
<div style="border: 1px solid #e5e7eb; padding: 16px; margin-bottom: 12px; border-radius: 8px;">
    <div style="display: flex; align-items: flex-start; justify-content: space-between; gap: 12px; margin-bottom: 8px;">
        <a href="{{ route('entries.show', $entry) }}"
           style="color: #1e293b; text-decoration: none; font-weight: 600; line-height: 1.4;">
            {{ $truncatedTitle() }}
        </a>
        <span style="font-size: 0.75em; color: #9ca3af; white-space: nowrap; margin-top: 2px;">
            {{ $entry->created_at->format('d M Y') }}
        </span>
    </div>

    <p style="color: #6b7280; margin: 0 0 8px; font-size: 0.9em; line-height: 1.5;">
        {{ $entry->excerpt }}
    </p>

    <span style="color: #9ca3af; font-size: 0.8em;">
        {{ $entry->reading_time }} min read
    </span>

    @if($entry->tags->isNotEmpty())
        <div style="margin-top: 8px;">
            @foreach($entry->tags as $tag)
                <span style="background: #dbeafe; color: #1e40af; padding: 2px 8px; border-radius: 12px; font-size: 0.75em;">
                    {{ $tag->name }}
                </span>
            @endforeach
        </div>
    @endif

    <div style="display: flex; align-items: center; gap: 12px; padding-top: 12px; border-top: 1px solid #f3f4f6; margin-top: 12px;">
        <a href="{{ route('entries.show', $entry) }}" style="font-size: 0.75em; color: #2563eb;">
            Read
        </a>
        @can('update', $entry)
            <a href="{{ route('entries.edit', $entry) }}" style="font-size: 0.75em; color: #d97706; text-decoration: none;">
                Edit
            </a>
        @endcan
        @can('delete', $entry)
            <form method="POST" action="{{ route('entries.destroy', $entry) }}" style="display: inline;">
                @csrf
                @method('DELETE')
                <button type="submit" onclick="return confirm('Delete this entry?')"
                    style="font-size: 0.75em; color: #dc2626; background: none; border: none; cursor: pointer; padding: 0;">
                    Delete
                </button>
            </form>
        @endcan
    </div>
</div>
```

The template uses `$entry` (the public constructor-promoted property) and calls `$truncatedTitle()` (the public method from the class). Both are available in the template automatically. The `$entry->excerpt` and `$entry->reading_time` values come from the accessors defined in Lesson 3. The action buttons at the bottom are wrapped in `@can('update', $entry)` and `@can('delete', $entry)` directives from the Policy introduced in Lesson 5, so each button only renders for users who are authorized to perform that action.

### Step 4: Verify the Entry Card Usage

Open `resources/views/entries/index.blade.php`. If you completed the beginner Catatku course, the entry loop already uses the component and no change is needed here. This is what the loop looks like:

```blade
@foreach($entries as $entry)
    <x-entry-card :entry="$entry" />
@endforeach
```

The `:entry="$entry"` syntax (with the colon prefix) evaluates the PHP expression and passes the actual Entry object to the component constructor. Without the colon, the attribute value would be treated as a literal string `"$entry"` rather than the variable. The self-closing tag `<x-entry-card ... />` is used because we do not need any slot content; everything is driven by the prop.

---

## 5. Run and Test

With the three components in place, start the server and verify each one renders correctly. Pay attention to attribute pass-through behavior and named slot visibility, since those are the most common areas where subtle mistakes appear.

### Step 1: Visit the Entries Index

Start the server and load `/entries`. You should see the entry cards rendered by the component, looking identical to before the refactor. Try changing the border color in the component template from `#e5e7eb` to red, save the file, and refresh: every card on the page reflects the change immediately, proving that the single-source-of-truth approach works.

### Step 2: Test the Alert Component

Open `resources/views/components/layout.blade.php`. The layout already contains a flash success block using a raw HTML `<div>`. Replace that raw div with `<x-alert>`, and add a second block for the `error` session key that did not exist before.

```blade
@if (session('success'))
    <x-alert type="success">
        {{ session('success') }}
    </x-alert>
@endif

@if (session('error'))
    <x-alert type="error">
        {{ session('error') }}
    </x-alert>
@endif
```

The `success` block replaces the existing raw div. The `error` block is new: it was not in the layout before because only success messages were shown. Adding it means any controller that returns `redirect()->with('error', '...')` will now display a styled red alert automatically. Both flash values are consumed by Laravel on the next request and cleared from the session, so the alert disappears after one page load.

After the change, the full `layout.blade.php` looks like this:

```blade
<!DOCTYPE html>
<html lang="en">

<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{{ $title ?? 'Catatku' }}</title>
    <script src="https://unpkg.com/@tailwindcss/browser@4"></script>
</head>

<body class="bg-gray-50 min-h-screen">

    <nav class="bg-white border-b border-gray-200 sticky top-0 z-10">
        <div class="max-w-2xl mx-auto px-4 py-3 flex items-center justify-between">
            <a href="/entries" class="text-xl font-bold text-gray-900 hover:text-gray-700">
                Catatku 📓
            </a>
            <div class="flex items-center gap-4">
                @auth
                <span class="text-sm text-gray-500">{{ auth()->user()->name }}</span>
                <form method="POST" action="/logout">
                    @csrf
                    <button type="submit" class="text-sm text-gray-500 hover:text-gray-900 transition-colors">
                        Logout
                    </button>
                </form>
                @else
                <a href="/login" class="text-sm text-gray-600 hover:text-gray-900">Log In</a>
                <a href="/register"
                    class="text-sm bg-gray-900 text-white px-3 py-1.5 rounded-lg hover:bg-gray-700 transition-colors">
                    Register
                </a>
                @endauth
            </div>
        </div>
    </nav>

    <main class="max-w-2xl mx-auto px-4 py-8">

        @if (session('success'))
            <x-alert type="success">
                {{ session('success') }}
            </x-alert>
        @endif

        @if (session('error'))
            <x-alert type="error">
                {{ session('error') }}
            </x-alert>
        @endif

        {{ $slot }}
    </main>

</body>

</html>
```

Trigger a success message by creating an entry and confirm the green alert appears with the left-border accent. To test the error variant, temporarily add `return redirect()->with('error', 'Test error.');` to any controller method, trigger it, and observe the red alert before removing the test code.

### Step 3: Test the Button Component

Replace a raw `<button>` element in an existing form with `<x-button variant="primary">`. Confirm it renders with the blue primary style. Try `variant="danger"` on a delete button to see the red variant.

### Step 4: Attribute Pass-Through

Add extra attributes when using the button to verify the `$attributes->merge()` pass-through works.

```blade
<x-button variant="danger" onclick="return confirm('Are you sure?')" class="ml-2">
    Delete
</x-button>
```

The `onclick` and `class` attributes are not declared as props, so they flow through `$attributes->merge()` to the rendered `<button>` element. Click the button and confirm the JavaScript confirmation dialog appears, proving that arbitrary HTML attributes pass through correctly.

---

## 6. Fix the Errors in Your Code

These are the most common mistakes when creating and using Blade components.

**Error 1: Forgetting the colon prefix when passing a PHP variable as a prop.**

This error occurs when you reference a PHP variable as a component attribute without the colon prefix. Without the colon, Blade treats the attribute value as a literal string rather than evaluating it as a PHP expression.

```blade
{{-- Wrong: passes the literal string "$entry" to the component --}}
<x-entry-card entry="$entry" />

{{-- Correct: evaluates the expression and passes the actual Entry object --}}
<x-entry-card :entry="$entry" />
```

The wrong version passes the string `"$entry"` to the component, so `$entry->title` inside the template throws a method call on string error. The correct version uses the colon prefix, which tells Blade to evaluate the PHP expression `$entry` and pass the resulting object. Any non-string value (variables, arrays, method calls, ternary expressions) must use the colon prefix.

---

**Error 2: Component file named with underscores instead of kebab-case.**

This error occurs when a component file is saved with underscores (snake_case) in the file name. Blade's component resolution converts the `<x-kebab-case-name>` tag to a file path using hyphens, not underscores.

```
Wrong:  resources/views/components/entry_card.blade.php
<x-entry-card /> resolves to entry-card.blade.php but finds no match

Correct: resources/views/components/entry-card.blade.php
<x-entry-card /> resolves correctly
```

Blade maps `<x-entry-card>` to `resources/views/components/entry-card.blade.php`. If your file is named `entry_card.blade.php` (with underscore), the resolution fails and Blade throws a component not found error. Rename the file to use hyphens to match the kebab-case convention. For class-based components, `make:component EntryCard` handles the naming automatically.

---

**Error 3: Checking a named slot variable with `if ($title)` instead of `isset($title)`.**

This error occurs when you use a direct `if ($title)` check for a named slot inside a component template. When the named slot is not passed by the caller, the variable is undefined rather than false or null, so a direct boolean check causes an "Undefined variable" error.

```blade
{{-- Wrong: $title is undefined when no title slot is passed, causing an error --}}
@if ($title)
    <strong>{{ $title }}</strong>
@endif

{{-- Correct: isset() safely returns false for undefined variables --}}
@if (isset($title))
    <strong>{{ $title }}</strong>
@endif
```

The wrong version assumes `$title` exists in the template scope. When the caller does not provide a `<x-slot:title>` block, the variable is never set and the `if ($title)` check throws a PHP notice or exception. The correct version uses `isset($title)`, which returns `false` for undefined variables without throwing an error. Always use `isset()` when checking for optional named slots.

---

## 7. Exercises

Try building these components independently using the patterns from this lesson. Focus on `@props` declarations, named slots, and `$attributes->merge()` for each one.

**Exercise 1:** Create a `<x-form-input>` component that accepts `name`, `label`, and `type` props. It should render a label element, an input element with `old($name)` for value pre-filling, and an `@error` block for validation messages.

**Exercise 2:** Create a `<x-card>` component with a `title` named slot, a `body` default slot, and an optional `footer` named slot. Use it to wrap the entry detail view in a consistent card layout.

**Exercise 3:** Make the Alert component auto-dismiss after 5 seconds using JavaScript. Accept an `auto-dismiss` prop that defaults to `false`, and conditionally include a small `<script>` tag inside the component that calls `setTimeout()` when the prop is true.

---

## 8. Solutions

Compare your components with the solutions below, paying attention to how optional named slots use `isset()` and how props with no default value enforce required attributes.

**Solution for Exercise 1:**

Create `resources/views/components/form-input.blade.php` with the following content.

```blade
@props(['name', 'label', 'type' => 'text'])

<div style="margin-bottom: 16px;">
    <label style="display: block; font-weight: bold; margin-bottom: 6px;">
        {{ $label }}
    </label>
    <input
        type="{{ $type }}"
        name="{{ $name }}"
        value="{{ old($name) }}"
        {{ $attributes->merge(['style' => 'width: 100%; padding: 8px; border: 1px solid #d1d5db; border-radius: 6px;']) }}
    >
    @error($name)
        <p style="color: #dc2626; font-size: 0.85em; margin-top: 4px;">{{ $message }}</p>
    @enderror
</div>
```

Use the component in any form with the following syntax.

```blade
<x-form-input name="title" label="Title" required />
<x-form-input name="email" label="Email" type="email" />
```

The `name` and `label` props are required (no default value is provided in `@props`). The `type` prop defaults to `"text"`. The `old($name)` helper re-populates the input with the previously submitted value after a failed validation, preventing the user from re-typing all their input. The `@error($name)` directive displays the field-specific validation message below the input. The `$attributes->merge(...)` pass-through allows callers to add extra HTML attributes like `required`, `placeholder`, or `autocomplete` without changing the component definition. This component centralizes all form input rendering, so updating the global input style requires editing one file.

---

**Solution for Exercise 2:**

Create `resources/views/components/card.blade.php` with the following content.

```blade
@props([])

<div style="border: 1px solid #e5e7eb; border-radius: 8px; overflow: hidden; margin-bottom: 16px;">
    @if(isset($title))
        <div style="padding: 12px 16px; border-bottom: 1px solid #e5e7eb; font-weight: bold; font-size: 1.1em;">
            {{ $title }}
        </div>
    @endif

    <div style="padding: 16px;">
        {{ $slot }}
    </div>

    @if(isset($footer))
        <div style="padding: 10px 16px; border-top: 1px solid #e5e7eb; background: #f9fafb; font-size: 0.9em; color: #6b7280;">
            {{ $footer }}
        </div>
    @endif
</div>
```

Use the component in the entry detail view with the following syntax.

```blade
<x-card>
    <x-slot:title>{{ $entry->title }}</x-slot:title>

    <p>{{ $entry->content }}</p>

    <x-slot:footer>
        Published {{ $entry->created_at->diffForHumans() }}
    </x-slot:footer>
</x-card>
```

Both `$title` and `$footer` are optional named slots checked with `isset()`. When neither is provided, the card renders only the padded body section. When only the `title` slot is passed, the header appears but the footer is omitted. This three-region layout (header, body, footer) is a common UI pattern, and centralizing it in one component means you can restyle all cards across Catatku by editing a single file.

---

**Solution for Exercise 3:**

Open `resources/views/components/alert.blade.php` and add the `autoDismiss` prop along with the conditional script block.

```blade
@props([
    'type' => 'info',
    'autoDismiss' => false,
])

@php
    $colors = match($type) {
        'success' => 'background: #dcfce7; color: #166534; border-left: 4px solid #16a34a;',
        'error' => 'background: #fee2e2; color: #991b1b; border-left: 4px solid #dc2626;',
        'warning' => 'background: #fef3c7; color: #92400e; border-left: 4px solid #d97706;',
        default => 'background: #dbeafe; color: #1e3a8a; border-left: 4px solid #2563eb;',
    };
    $alertId = 'alert-' . uniqid();
@endphp

<div id="{{ $alertId }}" {{ $attributes->merge(['style' => "padding: 12px 16px; border-radius: 6px; margin-bottom: 16px; {$colors}"]) }}>
    @if(isset($title))
        <strong style="display: block; margin-bottom: 4px;">{{ $title }}</strong>
    @endif
    {{ $slot }}
</div>

@if($autoDismiss)
<script>
    setTimeout(function () {
        var el = document.getElementById('{{ $alertId }}');
        if (el) el.remove();
    }, 5000);
</script>
@endif
```

Use the auto-dismiss variant on any flash message alert.

```blade
<x-alert type="success" auto-dismiss>
    {{ session('success') }}
</x-alert>
```

Blade automatically converts the kebab-case attribute `auto-dismiss` to the camelCase variable `$autoDismiss` when matching against `@props`. A unique `$alertId` is generated using `uniqid()` so each alert on the page has a distinct DOM `id`, which prevents the script from accidentally removing the wrong element when multiple alerts are visible at once. The `<script>` block is rendered only when `$autoDismiss` is true, so alerts without the prop have zero JavaScript overhead.

---

## Next Up - Lesson 16

In this lesson you built three reusable Blade components for Catatku. The anonymous `<x-button>` component uses `@props` to declare a `type` and `variant`, a `match` expression to map variants to inline CSS, and `$attributes->merge()` to pass arbitrary HTML attributes through to the rendered element. The anonymous `<x-alert>` component introduces named slots with `isset($title)` for optional content regions. The class-based `<x-entry-card>` component pairs a PHP class (with a constructor-promoted `$entry` property and a `truncatedTitle()` method) with a Blade template that references both public properties and methods automatically. You refactored the entries index to use the component, confirming that a single template change updates every card on the page.

In Lesson 16, you will learn Vite and Tailwind CSS: how to modernize Catatku's frontend with a proper asset build pipeline using Vite and utility-first styling using Tailwind, replacing inline styles with class-based maintainable CSS.