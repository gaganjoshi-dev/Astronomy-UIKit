# Development Guide

Setup, testing, logging, and troubleshooting for local development.

## Prerequisites

1. macOS with Xcode 15+
2. iOS Simulator or physical device
3. NASA API key from [api.nasa.gov](https://api.nasa.gov/)

## Initial setup

### 1. Clone the repository

```bash
git clone <your-repo-url>
cd Astronomy
```

### 2. Configure the API key

```bash
cp Config/Secrets.xcconfig.example Config/Secrets.xcconfig
```

Open `Config/Secrets.xcconfig`:

```
NASA_API_KEY = your_actual_key_here
```

| File | Committed? | Purpose |
|------|------------|---------|
| `Config/Base.xcconfig` | Yes | Default `DEMO_KEY`, includes Secrets |
| `Config/Secrets.xcconfig.example` | Yes | Template |
| `Config/Secrets.xcconfig` | **No** (gitignored) | Your real key |

### 3. Open and run

```bash
open Astronomy.xcodeproj
```

Select the **Astronomy** scheme and an iOS simulator → **⌘R**.

## Build configuration

The Xcode project uses `Config/Base.xcconfig` at the project level. The Astronomy target injects the API key into Info.plist:

```
INFOPLIST_KEY_NASA_API_KEY = $(NASA_API_KEY)
```

Read at runtime via `APIConfiguration.nasaAPIKey`.

## Logging

Logging uses `os.Logger` through `AppLogger`:

```swift
AppLogger.network.info("APOD request: \(startDate) → \(endDate)")
AppLogger.feed.info("Appended \(count) item(s)")
AppLogger.repository.warning("Network failed, using cache")
```

### Categories

| Category | Filter in Console | Events |
|----------|-------------------|--------|
| `App` | `subsystem:com.gagan.Astronomy category:App` | Core Data load, scene connect |
| `Network` | `category:Network` | HTTP requests, decode results |
| `Repository` | `category:Repository` | Network vs cache path |
| `Persistence` | `category:Persistence` | Core Data save/fetch |
| `Feed` | `category:Feed` | Refresh, pagination |

### Viewing logs

1. Run the app (**⌘R**)
2. Open the debug console (**⌘⇧Y**)
3. Set filter to **All Output**
4. Optionally search for `Network`, `Feed`, or `Repository`

> `.debug` level messages (e.g. cache fetches) may be hidden unless debug logging is enabled for the subsystem in Console.app.

## Testing

### Run all tests in Xcode

Press **⌘U** with the **Astronomy** scheme selected.

### Run from terminal

```bash
xcodebuild test \
  -scheme Astronomy \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:AstronomyTests
```

### Test suites

| File | Tests |
|------|-------|
| `AstronomyTests.swift` | JSON decoding, date helper, repository offline fallback, cache pagination |
| `AstronomyListViewModelTests.swift` | Refresh, pagination guards, failed state, feed reset |

### Writing new tests

**ViewModel tests** — use `MockAstronomyRepository` (actor) conforming to `AstronomyRepositoryProtocol`:

```swift
let mock = MockAstronomyRepository()
mock.enqueue(AstronomyPageResult(items: [...], source: .network, hasMore: true, fallbackError: nil))
let viewModel = AstronomyListViewModel(repository: mock)
await viewModel.refresh()
```

**Repository tests** — use in-memory Core Data:

```swift
let stack = CoreDataStack(inMemory: true)
let persistence = AstronomyPersistenceStore(container: stack.container)
let repository = AstronomyRepository(networkService: mockNetwork, persistenceStore: persistence)
```

**Network tests** — implement `AstronomyNetworkServiceProtocol` with a stub that returns canned `[Astronomy]`.

## Tuning feed behavior

Edit `AstronomyConstants` in `Model/Astronomy.swift`:

```swift
enum AstronomyConstants {
    static let historyDays = 100      // max days of history
    static let pageSize = 15          // days per API request
    static let prefetchThreshold = 5    // rows from bottom before loading more
}
```

## Troubleshooting

### No data / rate limit errors

- `DEMO_KEY` allows ~30 requests/hour. Create `Secrets.xcconfig` with a real key.
- Check console for `APOD HTTP 429` or similar.

### No logs in console

- Ensure you **Run** (⌘R), not just Build.
- Set console filter to **All Output**, not Errors Only.
- Look for `Core Data store loaded` and `Scene connected` on launch.

### Empty feed offline on first launch

Expected — Core Data cache is empty until a successful network fetch populates it.

### UITableView inconsistencies

The feed uses `UITableViewDiffableDataSource` keyed by `date`. If you see visual glitches after data changes, verify each `Astronomy.date` is unique within the feed array.

### Core Data errors on launch

Check console for `Core Data store failed to load`. Common causes:
- Simulator storage full
- Model migration needed after schema changes

Reset simulator: **Device → Erase All Content and Settings**.

## Adding a new screen (checklist)

1. Create ViewModel (`@MainActor`) with protocol-injected dependencies
2. Create ViewController (programmatic UI)
3. Wire navigation in `AppCoordinator` or parent ViewController
4. Add ViewModel unit tests with mocks
5. Update [Architecture](ARCHITECTURE.md) if you introduce new layers

## Code style notes

- UIKit only — no SwiftUI in the main target
- Programmatic layout via `addAutolayoutSubview` / Auto Layout
- Prefer `async/await` over completion handlers
- Use `AppLogger` instead of `print()`
- Inject dependencies via initializers, not singletons (except `ImageLoader.shared` for now)
