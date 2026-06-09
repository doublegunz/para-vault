# Building a Simple Rule-Based Chatbot in Laravel Without AI

The word "chatbot" has quietly become a synonym for "AI", and that assumption stops a lot of developers before they even start. They imagine an OpenAI bill, vector databases, and prompt engineering, decide it is out of scope for a weekend project, and walk away. Meanwhile the chatbots that actually run most support widgets, FAQ helpers, and order-status menus are not intelligent at all. They are plain `if/then` logic: look at the words the user typed, find a keyword you recognize, and send back a canned answer. If you cannot build that deterministic core by hand, you cannot reason about the fancy AI version either, because the AI version is just this same loop with a smarter matching step. In this tutorial you will build a working chatbot in Laravel with zero AI, zero external chatbot packages, and zero magic, so every part of the logic is visible and testable.

## Overview {#overview}

A rule-based chatbot does its job in five small steps that never change: it normalizes the raw text the user typed, scans that text for known keywords, decides which intent the keywords belong to, maps that intent to a prepared answer, and falls back to a polite "I did not understand" when nothing matches. Everything in this tutorial is one of those five steps made concrete in Laravel. We will model the rules as a PHP enum, put the matching loop in a small service class, persist the conversation in the database so the chat survives a page refresh, and cover the whole thing with Pest tests so you can prove the bot behaves.

### What You'll Build

- A web chat page at `/chat` where you type a message and the bot replies instantly.
- A reusable `ChatbotService` that turns any message into a reply using keyword matching and a fallback.
- An `Intent` enum that acts as the bot's rule table, one case per topic the bot understands.
- A `messages` table that stores every line of the conversation so history persists across refreshes.
- A Pest test suite that verifies the matching logic, the fallback, validation, and persistence.

### What You'll Learn

- How to normalize user input so "HELLO!!!" and "  hello " are treated as the same message.
- How keyword matching and intent classification actually work under the hood.
- How to model a set of rules cleanly with a backed PHP enum.
- How to handle the "no match" case with a sensible fallback message.
- How to persist a back-and-forth conversation with Eloquent.
- How to test deterministic chatbot logic without mocking anything.

### What You'll Need

- PHP 8.3 or newer.
- Composer and the Laravel installer.
- Laravel 13.
- Basic familiarity with Blade views and Eloquent models.

## Step 1: Create the Laravel Project {#step-1-create-the-laravel-project}

Every step in this tutorial builds on the previous one, so we start from a clean Laravel 13 project with SQLite and Pest already wired up. SQLite keeps the setup friction low because there is no database server to configure; the whole conversation lives in a single file.

Create the project and move into it:

```bash
laravel new chatbot-demo --no-interaction --database=sqlite --pest --no-boost
cd chatbot-demo
```

The `--database=sqlite` flag points the project at a local SQLite file and the `--pest` flag installs Pest as the test runner instead of plain PHPUnit. The installer creates the `chatbot-demo` directory, installs dependencies, and runs the initial migrations for you.

Confirm the project is healthy by running the default test suite:

```bash
php artisan test
```

You should see the two example tests that ship with a fresh project pass:

```
   PASS  Tests\Unit\ExampleTest
  ✓ that true is true

   PASS  Tests\Feature\ExampleTest
  ✓ the application returns a successful response                        0.11s

  Tests:    2 passed (2 assertions)
  Duration: 0.17s
```

A green baseline means the framework is installed correctly and we can start adding our own pieces.

## Step 2: Define the Chatbot's Intents with a PHP Enum {#step-2-define-the-chatbots-intents-with-a-php-enum}

Before the bot can match anything, we need to decide what it is allowed to understand. In chatbot language, each topic the bot recognizes is called an "intent": the user's greeting is one intent, a question about price is another, and so on. We will represent every intent as a case in a backed PHP enum, and attach two things to each case: the keywords that trigger it, and the reply it should send. Keeping the rules in an enum gives us one obvious place to read or extend the bot's knowledge, and the compiler keeps us honest because every case must define both methods.

Create a new file at `app/Chatbot/Intent.php`:

```php
<?php

namespace App\Chatbot;

enum Intent: string
{
    case Greeting = 'greeting';
    case Goodbye = 'goodbye';
    case Thanks = 'thanks';
    case Help = 'help';
    case BusinessHours = 'business_hours';
    case Pricing = 'pricing';

    /**
     * The trigger words that make this intent match.
     */
    public function keywords(): array
    {
        return match ($this) {
            self::Greeting => ['hi', 'hello', 'hey', 'good morning', 'good evening'],
            self::Goodbye => ['bye', 'goodbye', 'see you', 'see ya'],
            self::Thanks => ['thanks', 'thank you', 'thank'],
            self::Help => ['help', 'support', 'assist'],
            self::BusinessHours => ['hours', 'open', 'opening', 'closing', 'time'],
            self::Pricing => ['price', 'pricing', 'cost', 'how much', 'fee'],
        };
    }

    /**
     * The canned answer the bot sends when this intent wins.
     */
    public function reply(): string
    {
        return match ($this) {
            self::Greeting => 'Hello! I am the QadrLabs assistant. How can I help you today?',
            self::Goodbye => 'Goodbye! Have a great day.',
            self::Thanks => 'You are welcome. Anything else I can help with?',
            self::Help => 'Sure, I can help. You can ask me about our pricing or our business hours.',
            self::BusinessHours => 'We are open Monday to Friday, from 9 AM to 5 PM.',
            self::Pricing => 'Our plans start at $9 per month. Ask me for "pricing" anytime to see this again.',
        };
    }
}
```

The `keywords()` method returns the list of words or phrases that should trigger each intent, and the `reply()` method returns the prepared answer. Because both methods use a `match` expression on `$this`, adding a new topic to the bot is a matter of adding one case and one line to each method. Notice that there is no `Fallback` case here; the "I did not understand" path is not a real intent, so we will handle it separately in the service that does the matching.

## Step 3: Build the Matching Engine {#step-3-build-the-matching-engine}

This is the heart of the chatbot and the part most worth understanding. The matching engine takes the raw string the user typed and returns a reply. It does three jobs in order: it cleans up the input so small differences in casing and punctuation do not break matching, it walks through every intent looking for a keyword that appears in the message, and it returns a fallback reply if no intent matched. There is no machine learning here, just string handling and a loop, and that is exactly the point.

Create a new file at `app/Chatbot/ChatbotService.php`:

```php
<?php

namespace App\Chatbot;

class ChatbotService
{
    /**
     * The reply sent when no intent matches the user's message.
     */
    public const FALLBACK = 'Sorry, I did not understand that. Try asking about our pricing, business hours, or type "help".';

    /**
     * Take a raw user message and return the bot's reply.
     */
    public function respondTo(string $message): string
    {
        $normalized = $this->normalize($message);

        foreach (Intent::cases() as $intent) {
            if ($this->matches($normalized, $intent)) {
                return $intent->reply();
            }
        }

        return self::FALLBACK;
    }

    /**
     * Lowercase the text, strip punctuation, and collapse extra spaces so
     * that "Hello!!!" and "  hello " are treated as the same input.
     */
    private function normalize(string $message): string
    {
        $lower = strtolower($message);
        $clean = preg_replace('/[^a-z0-9\s]/', ' ', $lower);
        $collapsed = preg_replace('/\s+/', ' ', $clean);

        return trim($collapsed);
    }

    /**
     * Decide whether the normalized message contains any keyword of the intent.
     */
    private function matches(string $normalized, Intent $intent): bool
    {
        foreach ($intent->keywords() as $keyword) {
            if (str_contains($normalized, $keyword)) {
                return true;
            }
        }

        return false;
    }
}
```

The `respondTo()` method drives the whole flow. It normalizes the message once, then loops over `Intent::cases()`, which returns every case in the order you declared them. The first intent whose keywords appear in the message wins, and the loop returns its reply immediately. If the loop finishes without a match, the method returns the `FALLBACK` constant.

The `normalize()` method is small but important. It lowercases the text so "Hello" matches the keyword "hello", replaces anything that is not a letter, digit, or space with a space so "cost?" becomes "cost", and finally collapses repeated spaces into single ones. Without this step the bot would feel brittle, refusing to recognize a greeting just because the user added an exclamation mark.

The `matches()` method uses `str_contains()` to check whether any keyword appears anywhere inside the message. That means a keyword like "price" will match "what is the price" as well as "pricing options", which is usually what you want for a friendly bot.

## Step 4: Test the Logic in Tinker {#step-4-test-the-logic-in-tinker}

The chatbot logic is now complete even though there is no web page yet, and that separation is a feature. Because the matching engine is a plain PHP class with no dependency on HTTP or the database, we can exercise it directly in Tinker, Laravel's interactive REPL. This is the fastest way to confirm the logic works and to get a feel for how the bot reacts to different phrasings.

Start Tinker:

```bash
php artisan tinker
```

Now create an instance of the service and send it a few messages:

```
> $bot = new App\Chatbot\ChatbotService();
= App\Chatbot\ChatbotService {#6379}

> $bot->respondTo('Hello there!');
= "Hello! I am the QadrLabs assistant. How can I help you today?"

> $bot->respondTo('How much does it cost?');
= "Our plans start at $9 per month. Ask me for "pricing" anytime to see this again."

> $bot->respondTo('I want a refund');
= "Sorry, I did not understand that. Try asking about our pricing, business hours, or type "help"."
```

The first message matched the `Greeting` intent through the keyword "hello", the second matched `Pricing` through both "how much" and "cost", and the third matched nothing, so the engine returned the fallback. You have a working chatbot brain at this point, fully testable, before writing a single line of view or controller code. Type `exit` to leave Tinker.

## Step 5: Persist the Conversation {#step-5-persist-the-conversation}

A real chat needs memory. If we generate a reply and then forget it, the page would be blank again on the next refresh and the user would lose the whole conversation. To keep things simple and persistent, we will store each line of the chat as a row in a `messages` table, tagging every row with who said it, the user or the bot.

Create the model and a migration for it:

```bash
php artisan make:model Message
php artisan make:migration create_messages_table
```

Open the new migration in `database/migrations` and define the table. We only need a `sender` column to record who spoke and a `body` column for the text:

```php
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('messages', function (Blueprint $table) {
            $table->id();
            $table->string('sender'); // "user" or "bot"
            $table->text('body');
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('messages');
    }
};
```

The `sender` column is a simple string that will hold either `"user"` or `"bot"`, and the `body` column uses `text` so long messages are not truncated. The `timestamps()` call gives us `created_at` and `updated_at`, which is handy for ordering messages chronologically.

Now open `app/Models/Message.php` and tell Eloquent which fields are mass assignable so we can create rows with an array:

```php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Model;

#[Fillable(['sender', 'body'])]
class Message extends Model
{
    //
}
```

The `#[Fillable(['sender', 'body'])]` attribute is the Laravel 13 way to declare mass-assignable columns directly on the class, replacing the older `protected $fillable` property. It lets us call `Message::create(['sender' => 'user', 'body' => 'hi'])` without Laravel rejecting the fields.

Run the migration to create the table:

```bash
php artisan migrate
```

You should see the new migration run successfully:

```
   INFO  Running migrations.

  2026_06_08_235853_create_messages_table ........................ 9.89ms DONE
```

You can sanity check the model in Tinker before moving on:

```
> App\Models\Message::create(['sender' => 'user', 'body' => 'hello']);
= App\Models\Message {#...}

> App\Models\Message::count();
= 1
```

The row was inserted and counted, which confirms the table and the model agree with each other. Remove that test row with `App\Models\Message::truncate();` before you continue so the chat starts empty.

## Step 6: Wire Up the Controller and Routes {#step-6-wire-up-the-controller-and-routes}

With a brain and a memory in place, we need an entry point that connects an HTTP request to both. The controller has two jobs: show the chat page with the full history, and handle a new message by saving it, asking the service for a reply, and saving that reply too. Laravel's service container will hand us a `ChatbotService` automatically when we type-hint it, so we never have to construct it by hand.

Create the controller:

```bash
php artisan make:controller ChatController
```

Open `app/Http/Controllers/ChatController.php` and replace its contents:

```php
<?php

namespace App\Http\Controllers;

use App\Chatbot\ChatbotService;
use App\Models\Message;
use Illuminate\Http\Request;

class ChatController extends Controller
{
    /**
     * Show the chat page with the full conversation history.
     */
    public function index()
    {
        $messages = Message::orderBy('id')->get();

        return view('chat.index', ['messages' => $messages]);
    }

    /**
     * Store the user's message, generate the bot reply, then store that too.
     */
    public function store(Request $request, ChatbotService $bot)
    {
        $validated = $request->validate([
            'body' => ['required', 'string', 'max:500'],
        ]);

        Message::create([
            'sender' => 'user',
            'body' => $validated['body'],
        ]);

        Message::create([
            'sender' => 'bot',
            'body' => $bot->respondTo($validated['body']),
        ]);

        return redirect()->route('chat.index');
    }
}
```

The `index()` method loads every message ordered by id, oldest first, and hands them to the view. The `store()` method validates that a non-empty `body` was submitted, saves it as a `user` message, calls `$bot->respondTo()` to compute the reply, saves that as a `bot` message, and finally redirects back to the chat page. The redirect follows the post-redirect-get pattern, which means refreshing the page after sending will not resubmit the same message.

Now register the two routes in `routes/web.php`:

```php
<?php

use App\Http\Controllers\ChatController;
use Illuminate\Support\Facades\Route;

Route::get('/', function () {
    return view('welcome');
});

Route::get('/chat', [ChatController::class, 'index'])->name('chat.index');
Route::post('/chat', [ChatController::class, 'store'])->name('chat.store');
```

The `GET /chat` route renders the conversation and the `POST /chat` route handles a submitted message. Naming them `chat.index` and `chat.store` lets the controller and the Blade form refer to them by name instead of hardcoding URLs.

## Step 7: Build the Chat Interface {#step-7-build-the-chat-interface}

The last piece is the page the user actually sees. It is a single Blade view with a scrollable list of messages and a form at the bottom. We will style it with the Tailwind CDN so there is no build step to worry about, align the user's messages to the right and the bot's to the left like a familiar messaging app, and show a friendly placeholder when the conversation is empty.

Create the view at `resources/views/chat/index.blade.php`:

```blade
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <meta name="csrf-token" content="{{ csrf_token() }}">
    <title>Simple Chatbot</title>
    <script src="https://cdn.tailwindcss.com"></script>
</head>
<body class="bg-gray-100 text-gray-800 font-sans p-6">
    <div class="max-w-2xl mx-auto bg-white p-6 md:p-8 rounded-lg shadow-md">
        <h1 class="text-2xl font-bold mb-4">QadrLabs Assistant</h1>

        <div class="border border-gray-200 rounded-lg p-4 h-96 overflow-y-auto mb-4 space-y-3 bg-gray-50">
            @forelse ($messages as $message)
                @if ($message->sender === 'user')
                    <div class="flex justify-end">
                        <div class="bg-blue-600 text-white px-4 py-2 rounded-lg max-w-xs">
                            {{ $message->body }}
                        </div>
                    </div>
                @else
                    <div class="flex justify-start">
                        <div class="bg-gray-200 text-gray-800 px-4 py-2 rounded-lg max-w-xs">
                            {{ $message->body }}
                        </div>
                    </div>
                @endif
            @empty
                <p class="text-center text-gray-400 text-sm">No messages yet. Say hello to start.</p>
            @endforelse
        </div>

        <form method="POST" action="{{ route('chat.store') }}" class="flex gap-2">
            @csrf
            <input type="text" name="body" autocomplete="off" autofocus
                placeholder="Type a message..."
                class="flex-1 border border-gray-300 rounded-lg px-4 py-2 focus:outline-none focus:ring-2 focus:ring-blue-500">
            <button type="submit"
                class="bg-blue-600 text-white px-5 py-2 rounded-lg hover:bg-blue-700 transition">
                Send
            </button>
        </form>

        @error('body')
            <p class="text-red-600 text-sm mt-2">{{ $message }}</p>
        @enderror

        <div class="mt-8 mb-6 text-center text-sm text-gray-500">
            <a href="https://qadrlabs.com" class="text-blue-600 hover:text-blue-800 hover:underline transition"
                target="_blank">Tutorial Simple Chatbot in Laravel at qadrlabs.com</a>
        </div>
    </div>
</body>
</html>
```

The `@forelse` loop walks the messages collection and renders each one, using the `sender` value to decide whether the bubble sits on the right in blue for the user or on the left in gray for the bot. The `@empty` branch shows a hint when there is no history yet. The form posts to the named `chat.store` route and includes `@csrf`, which Laravel requires on every POST to protect against cross-site request forgery. The `@error('body')` block surfaces the validation message if the user tries to send an empty message. The footer at the bottom links back to qadrlabs.com.

## Step 8: Try It Out {#step-8-try-it-out}

Everything is connected, so let us watch the bot respond to real input. Start the development server:

```bash
php artisan serve
```

Open `http://127.0.0.1:8000/chat` in your browser. You will see the empty state first, then the conversation builds up as you send messages. Here is the full back-and-forth after sending three different kinds of message, shown as it is stored and rendered:

```
user  | Hello!
bot   | Hello! I am the QadrLabs assistant. How can I help you today?
user  | What are your business hours?
bot   | We are open Monday to Friday, from 9 AM to 5 PM.
user  | Can you process my order tomorrow?
bot   | Sorry, I did not understand that. Try asking about our pricing, business hours, or type "help".
```

The three messages exercise the three outcomes the engine can produce. "Hello!" matched the `Greeting` intent even with its trailing exclamation mark, because normalization stripped the punctuation before matching. "What are your business hours?" matched the `BusinessHours` intent through the keyword "hours". "Can you process my order tomorrow?" contained none of the bot's keywords, so the engine returned the fallback reply. Refresh the page and the whole conversation is still there, because every line was saved to the database.

## Step 9: Write Tests {#step-9-write-tests}

Manual clicking proves the bot works once; tests prove it keeps working as you add intents. Because the matching engine is a plain class, we can test it in isolation with fast unit tests, and because the controller flow is just HTTP plus the database, we can test it with Laravel's built-in request helpers. Together they pin down the behavior we care about: the right reply for each intent, case-insensitive matching, the fallback for unknown input, validation, and persistence of both sides of the conversation.

Create the unit test for the service at `tests/Unit/ChatbotServiceTest.php`:

```php
<?php

use App\Chatbot\ChatbotService;

beforeEach(function () {
    $this->bot = new ChatbotService();
});

it('greets back when the user says hello', function () {
    expect($this->bot->respondTo('Hello there'))
        ->toContain('QadrLabs assistant');
});

it('answers pricing questions', function () {
    expect($this->bot->respondTo('How much does it cost?'))
        ->toContain('$9 per month');
});

it('answers business hours questions', function () {
    expect($this->bot->respondTo('What are your opening hours?'))
        ->toContain('9 AM to 5 PM');
});

it('ignores case and punctuation when matching', function () {
    expect($this->bot->respondTo('HELLO!!!'))
        ->toContain('QadrLabs assistant');
});

it('falls back when nothing matches', function () {
    expect($this->bot->respondTo('I want a refund'))
        ->toBe(ChatbotService::FALLBACK);
});
```

These five tests cover the engine directly. The `beforeEach` hook builds a fresh service for every test. The first three check that real questions land on the right intent, the fourth proves normalization works by shouting "HELLO!!!" and still getting the greeting, and the fifth confirms that unmatched input returns the exact `FALLBACK` constant rather than a wrong intent.

Now create the feature test for the HTTP flow at `tests/Feature/ChatTest.php`:

```php
<?php

use App\Models\Message;
use Illuminate\Foundation\Testing\RefreshDatabase;

uses(RefreshDatabase::class);

it('shows the chat page', function () {
    $this->get('/chat')
        ->assertOk()
        ->assertSee('QadrLabs Assistant');
});

it('stores both the user message and the bot reply', function () {
    $this->post('/chat', ['body' => 'hello'])
        ->assertRedirect('/chat');

    expect(Message::count())->toBe(2);

    expect(Message::where('sender', 'user')->first()->body)->toBe('hello');
    expect(Message::where('sender', 'bot')->first()->body)
        ->toContain('QadrLabs assistant');
});

it('requires a message body', function () {
    $this->post('/chat', ['body' => ''])
        ->assertSessionHasErrors('body');

    expect(Message::count())->toBe(0);
});

it('renders the stored conversation history', function () {
    Message::create(['sender' => 'user', 'body' => 'hi']);
    Message::create(['sender' => 'bot', 'body' => 'Hello from the bot']);

    $this->get('/chat')
        ->assertSee('hi')
        ->assertSee('Hello from the bot');
});
```

The `uses(RefreshDatabase::class)` line resets the database between tests so each one starts clean. The first test checks the page loads, the second posts a message and asserts that exactly two rows were written, one for the user and one for the bot with the greeting reply. The third confirms validation rejects an empty body and writes nothing, and the fourth seeds two rows and verifies they appear on the page.

Run the full suite:

```bash
php artisan test
```

All nine tests should pass:

```
   PASS  Tests\Unit\ChatbotServiceTest
  ✓ it greets back when the user says hello                              0.01s
  ✓ it answers pricing questions
  ✓ it answers business hours questions
  ✓ it ignores case and punctuation when matching
  ✓ it falls back when nothing matches

   PASS  Tests\Feature\ChatTest
  ✓ it shows the chat page                                               0.21s
  ✓ it stores both the user message and the bot reply                    0.04s
  ✓ it requires a message body                                           0.04s
  ✓ it renders the stored conversation history                           0.03s

  Tests:    9 passed (17 assertions)
  Duration: 0.42s
```

A green suite means the brain, the persistence, and the HTTP flow all behave the way the tutorial promised.

## How the Matching Engine Works {#how-the-matching-engine-works}

Now that the bot runs, it is worth slowing down on the part that does the thinking, because the same ideas scale all the way up to production assistants. The engine only ever does three things, and each one maps to a concept you will meet again in every chatbot, AI or not.

### Normalization

Normalization is the cleanup pass that happens before any matching. Users type messily: extra spaces, capital letters, exclamation marks, and trailing question marks. If you matched against the raw string, the keyword "hello" would fail to match "Hello!" because of the capital H and the punctuation. Our `normalize()` method lowercases the text, replaces every non-alphanumeric character with a space, and collapses repeated spaces, so a wide range of inputs funnels down to the same clean form. Real systems go further with stemming and spelling correction, but the goal is always the same: reduce noisy input to a predictable shape.

### Keyword Matching and First-Match-Wins

Once the text is clean, the engine loops over the intents in declaration order and returns the first one whose keyword appears in the message. This "first-match-wins" rule is simple and fast, but it has a consequence worth knowing: order matters. A message like "hi, how much does pricing cost?" contains keywords for both `Greeting` ("hi") and `Pricing` ("cost"), and because `Greeting` is declared first, the bot replies with the greeting and never reaches the pricing answer. There is nothing wrong with that, but it means you should put your most specific or most important intents earlier in the enum, and keep broad greeting-style keywords from accidentally swallowing more useful matches.

### Keyword Containment Versus Regular Expressions

We used `str_contains()`, which checks whether a keyword appears anywhere inside the message. That is forgiving and easy to reason about, but it can over-match: the keyword "open" would also fire on the word "opener". For most FAQ bots that looseness is acceptable, and you can tighten it when you need to by switching the check to a regular expression with word boundaries, for example `preg_match('/\bopen\b/', $normalized)`. The architecture does not change; only the line inside `matches()` does, which is exactly why isolating that decision in one small method pays off.

### The Fallback

The fallback is what the bot says when no intent matched. It is not a failure case to hide; it is a feature. A good fallback gently steers the user back toward things the bot does understand, which is why ours suggests asking about pricing or business hours. Without a fallback, an unmatched message would either crash or return an empty reply, and the user would be stuck. Treating "I do not know" as a first-class response is one of the marks of a chatbot that feels helpful rather than broken.

## Rule-Based Versus AI Chatbots {#rule-based-versus-ai-chatbots}

It is easy to assume that a rule-based bot is just a toy on the way to a "real" AI bot, but they are different tools for different jobs, and the rule-based one is often the right call. A rule-based bot is deterministic: the same input always produces the same output, which makes it trivial to test, cheap to run, and impossible to make say something embarrassing. When your domain is small and well-defined, like a store with fixed hours and a handful of common questions, rules are not a compromise; they are the correct, predictable solution.

An AI or NLP-driven bot earns its complexity when the space of possible questions is large and you cannot enumerate the phrasings in advance. A language model can understand "what time do you shut on Saturdays" without you ever listing "shut" as a keyword, and it can hold a more natural conversation. The cost is that it is non-deterministic, harder to test, and capable of confidently inventing answers, so it usually needs guardrails. The useful insight is that the AI version still has the same skeleton you built here: it normalizes input, classifies intent, maps that intent to an action or answer, and falls back when it is unsure. You have not built a lesser version of a chatbot; you have built the core loop that every chatbot, however smart, is wrapped around.

## Conclusion {#conclusion}

You started with the belief that a chatbot requires AI and ended with a working, tested, database-backed chatbot that uses none. More importantly, you can now point at every line and explain why it is there, which is the understanding that makes the AI version approachable later. Here are the ideas worth keeping:

- **A chatbot is five steps, not magic.** Normalize the input, match keywords, classify the intent, map it to a reply, and fall back when nothing matches. Every bot, AI or not, is a variation on this loop.
- **Normalization is what makes matching feel smart.** Lowercasing, stripping punctuation, and collapsing whitespace let "HELLO!!!" and "hello" reach the same answer, which is most of what users perceive as the bot "understanding" them.
- **An enum is a clean home for rules.** Modeling intents as a backed PHP enum keeps the bot's keywords and replies in one readable place and makes adding a new topic a two-line change.
- **First-match-wins means order matters.** Because the engine returns the first intent it finds, declaring specific intents before broad ones prevents a greeting keyword from swallowing a more useful match.
- **The fallback is a feature, not an afterthought.** A helpful "I did not understand, try asking about X" keeps users moving and is the difference between a bot that feels broken and one that feels guided.
- **Deterministic logic is easy to test.** Because the matching engine is a plain class with no hidden state, a handful of Pest tests can fully pin down its behavior, and the same tests keep protecting you as the rule set grows.
