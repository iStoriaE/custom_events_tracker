# Custom Events Tracker

A simple and extensible event tracking library for Flutter/Dart apps that logs events and sends them to your backend API.

Easily log user interactions and system events, then send them to your backend API for analytics, monitoring, or auditing.  
Perfect for integrating with tools like **Metabase** for powerful data visualization and insight.

![Metabase](https://www.metabase.com/docs/latest/images/metabase-product-screenshot.png)

## Features

- 📱 Track custom events with attributes from your mobile apps
- 🔄 Offline support with automatic syncing when connectivity returns
- 🔒 API key authentication for secure event reporting
- 📊 Structured event data format for consistent analytics
- 📱 Platform detection (iOS/Android)
- ⏱️ Proper timezone handling for accurate event timing

## Installation

Add this package to your Flutter project by adding the following to your `pubspec.yaml`:

```yaml
dependencies:
  custom_events_tracker: <latest_release>
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
    userId: 123, // user's ID in your system
  );
  
  runApp(MyApp());
}
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

| Field | Description |
|-------|-------------|
| `id` | Unique UUID for each event |
| `type` | The event type (specified by you) |
| `attributes` | Custom attributes map (specified by you) |
| `source` | Always "mobile" |
| `platform` | "android" or "ios" |
| `userId` | The user ID provided during initialization |
| `userTime` | ISO 8601 timestamp with timezone information |
| `userTimezone` | The user's timezone |
| `env` | Environment from initialization |

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
- [intl](https://pub.dev/packages/intl) for date formatting

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
