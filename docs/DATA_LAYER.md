# Data Layer

How the app fetches, caches, and paginates NASA APOD data.

## NASA APOD API

**Endpoint:** `GET https://api.nasa.gov/planetary/apod`

**Client:** `AstronomyService`

### Request parameters

| Parameter | Description |
|-----------|-------------|
| `api_key` | NASA API key (from `Config/Secrets.xcconfig`) |
| `start_date` | Range start (`yyyy-MM-dd`) |
| `end_date` | Range end (`yyyy-MM-dd`) |

### Example

```
GET https://api.nasa.gov/planetary/apod?api_key=KEY&start_date=2024-06-05&end_date=2024-06-19
```

### Response

Returns either a **JSON array** of APOD objects or a **single object** for one-day requests. `AstronomyService` handles both and sorts results by date descending (newest first).

### Domain model (`Astronomy`)

| Field | JSON key | Notes |
|-------|----------|-------|
| `date` | `date` | Primary identifier (`yyyy-MM-dd`) |
| `title` | `title` | |
| `explanation` | `explanation` | Full description text |
| `url` | `url` | Low-res image or video URL |
| `hdurl` | `hdurl` | Optional HD image URL |
| `mediaType` | `media_type` | `"image"` or `"video"` |
| `copyright` | `copyright` | Optional |
| `serviceVersion` | `service_version` | |
| `image` | — | Transient `UIImage?`, not from API |

## Repository pattern

`AstronomyRepository` is the single entry point for feed data.

### Network-first strategy

```
loadPage()
  │
  ├─► Try NASA API for date range
  │     └─► Success: save to Core Data → return .network
  │
  └─► Catch error
        └─► Fetch from Core Data → return .offlineCache
```

### Page loading

Pagination is **day-based**, not item-based:

| Constant | Value | Meaning |
|----------|-------|---------|
| `pageSize` | 15 | Days requested per page |
| `historyDays` | 100 | Maximum scroll depth |
| `prefetchThreshold` | 5 | Rows from bottom that trigger next page |

**Page 1:** today → today − 14 days  
**Page 2:** today − 15 → today − 29 days  
…continues until 100 days are consumed.

Date math lives in `AstronomyDateHelper.pageRange(daysAlreadyLoaded:pageSize:maxHistoryDays:)`.

### `AstronomyPageResult`

| Field | Type | Purpose |
|-------|------|---------|
| `items` | `[Astronomy]` | APOD entries for this page |
| `source` | `.network` / `.offlineCache` | Where data came from |
| `hasMore` | `Bool` | Whether more history exists |
| `fallbackError` | `String?` | Original error when serving cache |

## Core Data

### Stack

`CoreDataStack` owns `NSPersistentContainer(name: "Astronomy")` and loads the SQLite store on disk. For tests:

```swift
CoreDataStack(inMemory: true)
```

### Entity: `AstronomyEntity`

| Attribute | Type | Notes |
|-----------|------|-------|
| `date` | String | Unique key |
| `title` | String | |
| `explanation` | String | |
| `url` | String | |
| `hdurl` | String? | |
| `mediaType` | String | |
| `copyright` | String? | |
| `serviceVersion` | String | |
| `lastFetched` | Date | Cache timestamp |

Images are **not** stored in Core Data.

### Persistence store (`AstronomyPersistenceStore`)

Actor-isolated Core Data access on background contexts.

**Save** — upsert by `date`:

```swift
try await persistenceStore.save(fetchedAstronomies)
```

Uses `NSPredicate(format: "date IN %@", dates)` to fetch only matching existing records.

**Fetch (paginated)** — newest first, optionally older than a cursor:

```swift
await persistenceStore.fetchAstronomies(before: oldestDate, limit: pageSize)
```

### Mapping

`AstronomyEntity+Domain.swift` provides:

- `entity.update(from: Astronomy)` — write API model to entity
- `entity.toDomain()` — read entity as `Astronomy` struct

## Image loading

`ImageLoader` (actor) handles thumbnail and HD image downloads.

```
image(for: urlString)
  ├─► NSCache hit? → return
  ├─► In-flight Task exists? → await it
  └─► URLSession.data → UIImage → cache → return
```

- Memory cache limit: 200 images
- Same loader used by list cells and detail HD upgrade
- Images are not persisted to disk (known limitation)

## Feed state machine

Managed by `AstronomyListViewModel`:

```
idle
  └─► refresh() → loading
        ├─► success → loaded (astronomies populated)
        └─► empty + error → failed(message)

loaded + scroll near bottom
  └─► isLoadingMore = true
        ├─► append items via diffable snapshot
        └─► isLoadingMore = false

refresh() during pagination
  └─► feedGeneration++ → stale in-flight pages discarded
```

### Stale request protection

`feedGeneration` increments on every `refresh()`. Pagination tasks capture the generation at start and bail if it no longer matches — preventing crashes and duplicate appends after pull-to-refresh.

## Offline behavior

| Scenario | Behavior |
|----------|----------|
| First launch offline, empty cache | Error alert with retry |
| Previously cached data | Banner: "Offline — showing saved data" |
| Scroll offline | Loads next page from Core Data (`date < oldest`) |
| Thumbnails offline | Placeholder icons (images not on disk) |

## API key flow

```
Config/Secrets.xcconfig
  → NASA_API_KEY build setting
    → INFOPLIST_KEY_NASA_API_KEY
      → Bundle.main Info.plist
        → APIConfiguration.nasaAPIKey
          → AstronomyService
```

Fallback chain: valid key in plist → `DEMO_KEY`.
