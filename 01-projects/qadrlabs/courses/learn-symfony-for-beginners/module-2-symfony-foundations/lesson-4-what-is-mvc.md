## 1. Before You Begin

In the previous lesson, we built two pages with real routes and templates. The entry controller holds a hardcoded array, passes it to Twig, and Twig displays it as HTML. For a small example, that is fine. But as Catatku grows, packing data preparation, business logic, and response building into a single method becomes unmanageable fast.

MVC is not a Symfony-specific concept. It is a widely adopted pattern that separates an application into three responsibilities so that changes to one part do not cause problems in another. Symfony is built around this pattern, and understanding it now will make every lesson that follows feel intentional rather than arbitrary.

This lesson is mostly conceptual. You will not add any new visible features. Instead, you will understand why the folders inside `src/` are named the way they are, and how a request travels through Symfony from the incoming URL all the way to the HTML that appears in the browser.

### What You'll Build

By the end of this lesson, you will have a clear mental model of the MVC pattern and how Symfony implements it with Controllers, Entities (Models), and Twig Templates (Views). The code structure will not change visually yet, but the concepts established here set the foundation for every lesson that follows.

### What You'll Learn

- ✅ What MVC stands for and why applications are built around it
- ✅ The specific role of each part: Entity (Model), Twig Template (View), and Controller
- ✅ How a request flows through Symfony from a URL to an HTML response
- ✅ How Symfony's folder structure maps directly to MVC responsibilities

### What You'll Need

- The `catatku` project open in VS Code with the development server running
- The `EntryController` and Twig template from Lesson 3

---

## 2. What is MVC?

MVC stands for Model, View, Controller. It is a way of separating an application into three parts, each with a single, well-defined responsibility. When responsibilities are separate, you can change one part without breaking the others.

The three parts are:

```text
┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│   Entity     │    │    Twig     │    │ Controller  │
│   (Model)    │    │   (View)    │    │             │
│              │    │             │    │             │
│ Talks to the │    │ Displays    │    │ Receives    │
│ database via │    │ data to the │    │ requests &  │
│ Doctrine     │    │ user as HTML│    │ coordinates │
└──────────────┘    └─────────────┘    └─────────────┘
```

**Entity (Model)** is responsible for data. In Symfony, entities are PHP classes that represent database tables. Each instance of an entity represents a row. Entities contain properties, getters, and setters. They do not contain any HTML or presentation logic.

**Twig Template (View)** is responsible for presentation. It receives data provided by the controller and renders it as HTML. Templates contain no PHP business logic. They only decide how data looks, not what it is or where it comes from.

**Controller** is responsible for application flow. It receives the incoming HTTP request, asks the Entity or Repository for data, and passes that data to the appropriate template. The controller coordinates but does not own data or presentation.

### The Restaurant Kitchen Analogy

Think of MVC like a restaurant:

**Entity** is the kitchen. The kitchen stores raw ingredients (data) and prepares them. It has no idea what the dining room looks like.

**Twig Template** is the plate and the table. This is how the prepared food is presented to the guest. The dining room does not prepare food. It only presents it.

**Controller** is the waiter. The waiter takes the customer's order (the HTTP request), fetches the food from the kitchen (queries the entity/repository), and serves it at the table (renders the template). The waiter coordinates between kitchen and dining room but does neither job themselves.

---

## 3. MVC in Symfony's Folder Structure

Symfony's directory layout is a direct expression of the MVC pattern. Once you understand MVC, the folder names stop feeling arbitrary.

### Step 1: Understand the Current Structure

Open your project in VS Code and look at the `src/` directory:

```text
src/
├── Controller/     ← C in MVC
├── Entity/         ← M in MVC
└── Repository/     ← supports M (handles queries)
```

And in the project root:

```text
templates/          ← V in MVC
```

Right now, `EntryController` holds a hardcoded array instead of querying a real entity. That is a temporary shortcut. Starting in Lesson 5, the controller will ask the `EntryRepository` for data, which queries the `Entry` entity, which maps to the database. The controller itself will only coordinate: ask for data, pass it to the template.

### Step 2: Verify Routes Are Registered

Before confirming how MVC fits together, let us verify the current routes are working. This time, add the `--show-controllers` option so the table also shows which controller method handles each route:

```bash
php bin/console debug:router --show-controllers
```

Output:

```text
 -------------------------- -------- ----------------------------------- ------------------------------------------------------------- 
  Name                       Method   Path                                Controller                                                   
 -------------------------- -------- ----------------------------------- ------------------------------------------------------------- 
  _preview_error             ANY      /_error/{code}.{_format}            error_controller::preview()                                  
  _wdt_stylesheet            ANY      /_wdt/styles                        web_profiler.controller.profiler::toolbarStylesheetAction()  
  _wdt                       ANY      /_wdt/{token}                       web_profiler.controller.profiler::toolbarAction()            
  _profiler_home             ANY      /_profiler/                         web_profiler.controller.profiler::homeAction()               
  _profiler_search           ANY      /_profiler/search                   web_profiler.controller.profiler::searchAction()             
  _profiler_search_bar       ANY      /_profiler/search_bar               web_profiler.controller.profiler::searchBarAction()          
  _profiler_phpinfo          ANY      /_profiler/phpinfo                  web_profiler.controller.profiler::phpinfoAction()            
  _profiler_xdebug           ANY      /_profiler/xdebug                   web_profiler.controller.profiler::xdebugAction()             
  _profiler_font             ANY      /_profiler/font/{fontName}.woff2    web_profiler.controller.profiler::fontAction()               
  _profiler_search_results   ANY      /_profiler/{token}/search/results   web_profiler.controller.profiler::searchResultsAction()      
  _profiler_open_file        ANY      /_profiler/open                     web_profiler.controller.profiler::openAction()               
  _profiler                  ANY      /_profiler/{token}                  web_profiler.controller.profiler::panelAction()              
  _profiler_router           ANY      /_profiler/{token}/router           web_profiler.controller.router::panelAction()                
  _profiler_exception        ANY      /_profiler/{token}/exception        web_profiler.controller.exception_panel::body()              
  _profiler_exception_css    ANY      /_profiler/{token}/exception.css    web_profiler.controller.exception_panel::stylesheet()        
  entry_index                ANY      /entries                            App\Controller\EntryController::index()                      
  home                       ANY      /                                   App\Controller\HomeController::index()                       
 -------------------------- -------- ----------------------------------- ------------------------------------------------------------- 
```

You should see your routes listed: `home` pointing to `HomeController::index` and `entry_index` pointing to `EntryController::index`. If either is missing, check the file location and the `#[Route]` attribute for typos. Symfony scans `src/Controller/` automatically, so any controller placed there with a valid `#[Route]` attribute will appear in this list.

Open `http://localhost:8080/entries` to confirm the entries listing still loads. The page looks the same as Lesson 3, but now you understand the architectural reasoning behind why the code is organized the way it is.

---

## 4. The Complete MVC Flow in Symfony

Let us trace the exact path a request takes through Symfony, from the moment a user types a URL to the moment they see HTML on screen:

```text
Browser: GET /entries
              │
              ▼
        Symfony Router reads #[Route('/entries')]
        on EntryController::index()
              │
              ▼
        EntryController::index()
        $entries = $repository->findBy(...);   ← from Entity/Repository (Lesson 6)
        return $this->render('entry/index.html.twig', ...)
              │
              ▼
        templates/entry/index.html.twig
        {% for entry in entries %} ...
              │
              ▼
        HTML sent to the browser
```

Currently, the controller uses a hardcoded array instead of a repository call. In Lesson 5, you will create the database and entities. In Lesson 6, you will update the controller to replace `$entries = [...]` with `$entries = $entryRepository->findBy(...)`. The rest of the flow, from `render()` to Twig to HTML, stays exactly the same.

This is one of MVC's key advantages: you can change how data is fetched (from an array to a database, or from one database to another) without touching the template at all. The template only cares that `entries` is a collection of things it can loop over.

---

## 5. Fix the Errors in Your Code

**Error 1: Putting presentation logic in the controller.**

A common beginner mistake is generating HTML directly inside a controller method instead of using a template.

```php
// Wrong: HTML in the controller violates the V in MVC
public function index(): Response
{
    $html = '<ul>';
    foreach ($entries as $entry) {
        $html .= '<li>' . $entry['title'] . '</li>';
    }
    $html .= '</ul>';
    return new Response($html);
}

// Correct: the controller renders a template
public function index(): Response
{
    $entries = [...];
    return $this->render('entry/index.html.twig', [
        'entries' => $entries,
    ]);
}
```

Generating HTML inside a controller violates the separation of concerns. Presentation belongs in templates. When you need to change the design later, you should only need to open the `.html.twig` file, not the controller. Keeping HTML out of controllers also makes controllers much easier to test.

**Error 2: Querying the database inside a Twig template.**

Twig templates should only display data, not fetch it from the database. Fetching in the template is impossible with Twig's restricted syntax anyway, but this conceptual mistake leads to putting too much logic in templates.

```twig
{# Wrong: templates should not decide what data to load #}
{% set entries = getAllEntries() %}
{% for entry in entries %}
    ...
{% endfor %}

{# Correct: templates receive data already prepared by the controller #}
{% for entry in entries %}
    {{ entry.title }}
{% endfor %}
```

Controllers prepare data. Templates display it. This division means that the same template could theoretically display data from two different sources (the database in production, a hardcoded array in a test) without any changes. The template does not care where its data came from.

---

## 6. Exercises

**Exercise 1:** In your own words (without looking at the lesson), explain what would happen if you ran `php bin/console debug:router` right now and the `entry_index` route was missing. What would you check first? Write down your debugging steps.

**Exercise 2:** Draw or write out the MVC flow for the following scenario: a user visits `http://localhost:8080/entries`. Describe each step from browser request to HTML response using the three parts of MVC (Controller, Entity/Repository will be a placeholder for now, Template).

**Exercise 3:** Looking at your current `EntryController`, which part of the code is playing the "Model" role right now (even though it is not a real entity yet)? Which part is the "View" role? Which part is the "Controller" role? Write a one-sentence answer for each.

---

## 7. Solutions

**Solution for Exercise 1:**

If `entry_index` was missing from `debug:router`, the first check would be whether the file `src/Controller/EntryController.php` exists and is saved. The second check would be whether the `#[Route]` attribute is correctly placed directly above the `index()` method with valid syntax. The third check would be whether the namespace at the top of the file is `App\Controller` and the class name matches the filename exactly. Symfony discovers routes automatically by scanning `src/Controller/`, so any file placed there with a valid `#[Route]` attribute will be picked up without any additional registration.

**Solution for Exercise 2:**

1. The browser sends `GET /entries` to `http://localhost:8080`.
2. PHP's built-in server forwards the request to Symfony's entry point at `public/index.php`.
3. Symfony's Router reads the `#[Route('/entries', name: 'entry_index')]` attribute on `EntryController::index()` and identifies it as the matching route.
4. The Controller (`EntryController::index()`) runs. Right now, it creates a hardcoded `$entries` array. In Lesson 6, this will be replaced by a repository query.
5. The controller calls `$this->render('entry/index.html.twig', ['entries' => $entries])`, passing the data to the View.
6. Twig's `{% for entry in entries %}` loop iterates over the array and generates one card element per entry.
7. The rendered HTML is returned as a `Response` object and sent back to the browser, which displays the page.

**Solution for Exercise 3:**

In the current `EntryController`:

The **Model** role is being played by the hardcoded `$entries` array. It represents data about journal entries, even though it is not coming from a real database entity yet. In Lesson 6, this role will be properly fulfilled by the `Entry` Doctrine entity and the `EntryRepository`.

The **View** role is played by the file `templates/entry/index.html.twig`. It receives the `$entries` data and renders it as HTML for the browser.

The **Controller** role is played by the `index()` method itself. It coordinates the flow: it creates (or will later fetch) the data and calls `render()` to pass it to the appropriate template.

---

## Next Up - Lesson 5

In this lesson, you learned the MVC pattern and how Symfony implements it through its folder structure: `src/Controller/` for flow coordination, `src/Entity/` for data, and `templates/` for presentation. You traced the full request lifecycle from a browser URL to the HTML response, and you understood why keeping these responsibilities separate makes the application easier to maintain and change.

In Lesson 5, you will connect Symfony to a real MySQL database using Doctrine ORM. You will create the `entry` and `user` tables using migration files, replacing the hardcoded array with a proper database-backed structure.