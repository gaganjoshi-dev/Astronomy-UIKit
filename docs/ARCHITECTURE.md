# Architecture

This document describes how the Astronomy app is structured, how components communicate, and which patterns are used.

## High-level overview

```
┌──────────────────────────────────────────────────────────────────┐
│                        APPLICATION LAYER                          │
│  AppDelegate ──► AppDependencies ──► AppCoordinator              │
│                         │                    │                      │
│                   CoreDataStack      SceneDelegate                │
└─────────────────────────┼────────────────────┼──────────────────────┘
                          │                    │
┌─────────────────────────▼────────────────────▼──────────────────────┐
│                         PRESENTATION LAYER                          │
│  AstronomyListViewController    AstronomyDetailsViewController      │
│           │                              │                          │
│  AstronomyListViewModel         AstronomyDetailsViewModel           │
│       (@MainActor)                  (@MainActor)                    │
└─────────────────────────┬───────────────────────────────────────────┘
                          │
┌─────────────────────────▼───────────────────────────────────────────┐
│                          DOMAIN LAYER                               │
│  Astronomy (struct)   AstronomyConstants   AstronomyDateHelper      │
└─────────────────────────┬───────────────────────────────────────────┘
                          │
┌─────────────────────────▼───────────────────────────────────────────┐
│                           DATA LAYER                                  │
│  AstronomyRepository (actor)                                        │
│       ├── AstronomyService          (NASA APOD API)                 │
│       └── AstronomyPersistenceStore (actor / Core Data)             │
│  ImageLoader (actor)                                                │
└─────────────────────────────────────────────────────────────────────┘
```

## Layer responsibilities

### Application layer (`App/`)

| Type | File | Role |
|------|------|------|
| Composition root | `AppDependencies` | Creates `CoreDataStack`, network service, persistence store, and repository |
| Navigation | `AppCoordinator` | Builds root `UINavigationController`, applies bar styling, starts the list screen |
| Persistence bootstrap | `CoreDataStack` | Owns `NSPersistentContainer`, loads the SQLite store |
| Entry point | `AppDelegate` | `@main`, scene session configuration, holds `dependencies` and `appCoordinator` |
| Window lifecycle | `SceneDelegate` | Creates the window via `appCoordinator.start(in:)` |

`AppDelegate` intentionally does **not** own Core Data or UI wiring directly.

### Presentation layer

| Screen | ViewController | ViewModel |
|--------|----------------|-----------|
| Feed | `AstronomyListViewController` | `AstronomyListViewModel` |
| Detail | `AstronomyDetailsViewController` | `AstronomyDetailsViewModel` |

**Pattern:** MVVM with delegate callbacks from ViewModel → ViewController.

- ViewModels are `@MainActor` — all UI state mutations happen on the main thread.
- ViewControllers own UIKit views and forward user actions to ViewModels.
- The list screen uses `UITableViewDiffableDataSource` keyed by `Astronomy.date`.

### Domain layer

- **`Astronomy`** — Codable struct matching the NASA APOD JSON schema.
- **`AstronomyDateHelper`** — Pure functions for pagination date-range math.
- **`AstronomyConstants`** — Tunable feed parameters (`pageSize`, `historyDays`, etc.).

### Data layer

- **`AstronomyRepository`** — Network-first coordinator; falls back to Core Data on failure. See [Data layer](DATA_LAYER.md).
- **`AstronomyService`** — HTTP client for the NASA APOD endpoint.
- **`AstronomyPersistenceStore`** — Thread-safe Core Data reads/writes via `actor`.
- **`ImageLoader`** — In-memory cache + in-flight download deduplication.

## Dependency injection

All services are created in **`AppDependencies`**:

```swift
AppDependencies
  ├── CoreDataStack
  ├── AstronomyService          (AstronomyNetworkServiceProtocol)
  ├── AstronomyPersistenceStore (uses CoreDataStack.container)
  └── AstronomyRepository       (lazy)
```

`AppCoordinator` receives `AppDependencies` and passes `astronomyRepository` into `AstronomyListViewController`.

For tests, inject mocks via `AstronomyRepositoryProtocol`:

```swift
let viewModel = AstronomyListViewModel(repository: mockRepository)
```

## Concurrency model

| Component | Isolation | Why |
|-----------|-----------|-----|
| `AstronomyListViewModel` | `@MainActor` | Owns UI-bound feed state |
| `AstronomyDetailsViewModel` | `@MainActor` | Owns detail screen state |
| `AstronomyRepository` | `actor` | Serializes page-load coordination |
| `AstronomyPersistenceStore` | `actor` | Safe Core Data background context access |
| `ImageLoader` | `actor` | Cache + deduplicated downloads |

Network and persistence work use `async/await`. ViewModels use `Task` for image loading and never call `DispatchQueue.main.async` manually.

## Navigation

`AppCoordinator` is responsible for:

1. Creating `AstronomyListViewController` with the repository
2. Wrapping it in a styled `UINavigationController`
3. Assigning it as the window root view controller

Detail navigation is handled by the list ViewController pushing `AstronomyDetailsViewController` on row selection. This can be moved into the coordinator later if the app grows.

## Protocol boundaries (testability)

| Protocol | Implemented by | Used by |
|----------|----------------|---------|
| `AstronomyNetworkServiceProtocol` | `AstronomyService` | `AstronomyRepository` |
| `AstronomyRepositoryProtocol` | `AstronomyRepository`, test mocks | `AstronomyListViewModel` |

## UIScene lifecycle

The app uses the modern scene-based UIKit lifecycle (iOS 13+):

```
App launch
  → AppDelegate.application(_:didFinishLaunchingWithOptions:)
  → AppDelegate.application(_:configurationForConnecting:options:)
  → SceneDelegate.scene(_:willConnectTo:options:)
  → AppCoordinator.start(in: windowScene)
```

Configured in `Info.plist` via `UIApplicationSceneManifest`.

## Logging

All logging goes through `AppLogger` (`os.Logger`) with categories:

| Category | Used for |
|----------|----------|
| `App` | Launch, Core Data, scene |
| `Network` | APOD HTTP requests |
| `Repository` | Network vs cache decisions |
| `Persistence` | Core Data save/fetch |
| `Feed` | Pagination, refresh |
| `Images` | Image loading (reserved) |

See [Development guide — Logging](DEVELOPMENT.md#logging).

## Known design trade-offs

| Decision | Rationale | Limitation |
|----------|-----------|------------|
| `UIImage?` on `Astronomy` | Simple thumbnail binding in cells | Couples domain model to UIKit |
| Metadata-only Core Data cache | Fast to implement | Thumbnails not available offline after relaunch |
| Delegate-based MVVM | Works well with UIKit | More boilerplate than `@Observable` |
| `DEMO_KEY` fallback | Zero-config clone & run | Heavily rate-limited |
