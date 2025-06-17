# Custom Events Tracker

A simple and extensible event tracking library for Flutter/Dart apps that logs events and sends them to your backend API.

Version: 0.2.0

Easily log user interactions and system events, then send them to your backend API for analytics, monitoring, or auditing.  

Perfect for integrating with tools like **Metabase** for powerful data visualization and insight.

![Metabase](https://www.metabase.com/docs/latest/images/metabase-product-screenshot.png)

## Features

- 📱 Track custom events with attributes from your mobile apps
- 🔄 Offline support with automatic syncing when connectivity returns
- 🔒 API key authentication for secure event reporting
- 📊 Structured event data format for consistent analytics
- 📱 Platform detection (iOS/Android)
- ⏱️ Proper timezone handling with UTC offsets
- 🔄 Time-ordered UUIDv7 for better database performance

## Installation

Add this package to your Flutter project by adding the following to your `pubspec.yaml`:

```yaml
dependencies:
  custom_events_tracker: ^0.2.0
```

Then run:

```bash
flutter pub get
```

## Usage

### Initialization

Initialize the tracker service early in your app lifecycle (typically in `main.dart`):

```dart
import 'package:custom_events_tracker/custom_events_tracker.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await TrackerService().initialize(
    endpointUrl: 'https://your-api-endpoint.com/events',
    apiKey: 'your-api-key',
    env: 'development', // or 'production', 'staging', etc.
    userId: 123, // Optional: can be null or set later
  );
  
  runApp(MyApp());
}
```

### User Management

You can set or update the user ID at any time after initialization:

```dart
// Set user ID after login
TrackerService().setUserId(123);

// Remove user ID after logout
TrackerService().setUserId(null);
```

### Tracking Events

Track events anywhere in your app by calling the `trackEvent` method:

```dart
// Basic event with type only
TrackerService().trackEvent(
  type: 'button_click',
  attributes: {},
);

// Event with custom attributes
TrackerService().trackEvent(
  type: 'item_purchase',
  attributes: {
    'item_id': 'product_123',
    'price': 19.99,
    'currency': 'USD',
    'quantity': 2,
  },
);
```

### Manual Flush

You can manually flush pending events if needed:

```dart
await TrackerService().flushPendingEvents();
```

## Event Structure

Events are automatically structured with the following fields:

| Field | Type | Description | Example |
|-------|------|-------------|---------|
| `id` | String | Time-ordered UUIDv7 | "018884e8-5c13-7eef-9c21-986bb5c0e725" |
| `type` | String | Event type | "button_click" |
| `attributes` | Map&lt;String, dynamic&gt; | Custom attributes | `{"price": 19.99}` |
| `source` | String | Always "mobile" | "mobile" |
| `platform` | String | "android" or "ios" | "android" |
| `userId` | int? | Optional user ID | 123 or null |
| `userTime` | String | ISO 8601 timestamp | "2025-06-16T12:23:07+02:00" |
| `timezone_offset` | int | Hours from UTC | 2 or -5 |
| `env` | String | Environment | "production" |

### About UUIDv7

This package uses UUIDv7 (time-ordered UUID) for event IDs, which provides several benefits:
- Natural temporal ordering
- Improved database indexing performance
- Maintains uniqueness while being time-based
- Better for distributed systems

## How It Works

1. Events are created with a unique ID and timestamped when tracked
2. When online, events are immediately sent to your backend
3. When offline, events are stored in a local Hive CE database
4. When connectivity returns, queued events are automatically sent
5. Failed sends are automatically queued for retry

## Dependencies

This package uses:
- [Hive CE](https://pub.dev/packages/hive_ce) for offline storage
- [connectivity_plus](https://pub.dev/packages/connectivity_plus) for network detection
- [http](https://pub.dev/packages/http) for API requests
- [uuid](https://pub.dev/packages/uuid) for generating unique event IDs

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
