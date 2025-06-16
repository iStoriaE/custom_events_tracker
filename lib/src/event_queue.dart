import 'dart:async';
import 'package:hive_ce_flutter/hive_flutter.dart';

import 'event_model.dart';

class EventQueue {
  static const String _boxName = 'event_queue_box';
  static Box<TrackedEvent>? _box;

  /// Call this once (in TrackerService.initialize) to set up Hive CE.
  static Future<void> initialize() async {
    // 1) Initialize Hive CE for Flutter
    await Hive.initFlutter();

    // 2) Register our adapter (only once)
    if (!Hive.isAdapterRegistered(TrackedEventAdapter().typeId)) {
      Hive.registerAdapter(TrackedEventAdapter());
    }

    // 3) Delete the old box if it exists (to handle schema changes)
    try {
      await Hive.deleteBoxFromDisk(_boxName);
    } catch (e) {
      // Ignore errors if box doesn't exist
    }

    // 4) Open (or create) the box for TrackedEvent
    _box = await Hive.openBox<TrackedEvent>(_boxName);
  }

  /// Enqueue a new event (key = event.id)
  static Future<void> enqueue(TrackedEvent event) async {
    if (_box == null) {
      throw StateError('EventQueue not initialized. Call initialize() first.');
    }
    await _box!.put(event.id, event);
  }

  /// Fetch all pending events, in insertion order
  static Future<List<TrackedEvent>> getAllEvents() async {
    if (_box == null) {
      throw StateError('EventQueue not initialized. Call initialize() first.');
    }
    return _box!.values.toList();
  }

  /// Remove a specific event by its ID
  static Future<void> removeById(String id) async {
    if (_box == null) {
      throw StateError('EventQueue not initialized. Call initialize() first.');
    }
    await _box!.delete(id);
  }
}
