# Astronomy

A UIKit app for browsing [NASA Astronomy Picture of the Day (APOD)](https://apod.nasa.gov/apod/astropix.html). It loads up to **100 days** of history in a paginated, Facebook-style feed with network-first loading and Core Data offline fallback.

## Features

- Infinite scroll feed (15-day pages)
- Image and video APOD support
- HD image upgrade on the detail screen
- Offline mode with cached metadata
- Pull-to-refresh
- Structured logging (`os.Logger`)

## Requirements

| Requirement | Version |
|-------------|---------|
| Xcode | 15+ |
| iOS deployment target | 15.0+ |
| NASA API key | Free at [api.nasa.gov](https://api.nasa.gov/) |

## Quick start

```bash
git clone <your-repo-url>
cd Astronomy
cp Config/Secrets.xcconfig.example Config/Secrets.xcconfig
# Edit Config/Secrets.xcconfig and set NASA_API_KEY
open Astronomy.xcodeproj
```

Run with **⌘R** on any iOS simulator.

Without `Secrets.xcconfig`, the app uses `DEMO_KEY` (rate-limited).

## Documentation

| Document | Description |
|----------|-------------|
| [Architecture](docs/ARCHITECTURE.md) | Layers, components, concurrency, navigation |
| [Data layer](docs/DATA_LAYER.md) | NASA API, repository, Core Data, pagination |
| [Development guide](docs/DEVELOPMENT.md) | Testing, logging, configuration, troubleshooting |

## Project structure

```
Astronomy/
├── App/                    # Composition root & navigation
│   ├── AppCoordinator.swift
│   ├── AppDependencies.swift
│   └── CoreDataStack.swift
├── AppDelegate.swift
├── SceneDelegate.swift
├── Model/                  # Domain models & date helpers
├── Services/               # Network, repository, persistence, images
├── View Model/             # List & detail ViewModels
├── View/                   # UIKit view controllers & cells
├── Utilities/              # Logging, API configuration
└── Extensions/

Config/                     # Build configuration & API keys
docs/                       # Project documentation
AstronomyTests/             # Unit tests
```

## Tech stack

- **UI:** UIKit (programmatic), `UITableViewDiffableDataSource`
- **Architecture:** MVVM + Repository + Coordinator
- **Concurrency:** Swift `actor`, `async/await`, `@MainActor`
- **Persistence:** Core Data
- **Networking:** `URLSession`
- **Lifecycle:** `UIScene` + `SceneDelegate`

## Testing

```bash
xcodebuild test \
  -scheme Astronomy \
  -destination 'platform=iOS Simulator,name=iPhone 16'
```

Or press **⌘U** in Xcode. See [Development guide](docs/DEVELOPMENT.md#testing) for details.

## Configuration

| Constant | Default | Location |
|----------|---------|----------|
| `historyDays` | 100 | `AstronomyConstants` |
| `pageSize` | 15 | `AstronomyConstants` |
| `prefetchThreshold` | 5 | `AstronomyConstants` |
| `NASA_API_KEY` | `DEMO_KEY` | `Config/Secrets.xcconfig` |

## License

Copyright © 2024–2026 **Gagan Joshi**. All Rights Reserved.

This source code is proprietary and may not be copied, distributed, or modified without written permission. See [LICENSE](LICENSE) for full terms.

This app uses the [NASA APOD API](https://api.nasa.gov). NASA imagery and data are subject to [NASA's media usage guidelines](https://www.nasa.gov/nasa-brand-center/images-and-media/) and are separate from this project's source code.
