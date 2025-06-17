import 'dart:convert';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import 'event_model.dart';
import 'event_queue.dart';
import 'network_manager.dart';

class TrackerService {
  TrackerService._privateConstructor();
  static final TrackerService _instance = TrackerService._privateConstructor();
  factory TrackerService() => _instance;

  final _uuid = Uuid(); // Used for v7 time-based UUIDs
  bool _initialized = false;
  late String _endpoint;
  late String _apiKey;
  late String _env;
  int? _userId; // Changed to nullable
  late String _platform; // "android" or "ios"

  /// Initialize once (e.g. in main()):
  ///  • endpointUrl : your backend URL
  ///  • env         : "production", "staging", etc.
  ///  • userId      : current user's ID (int), optional
  Future<void> initialize({
    required String endpointUrl,
    required String apiKey,
    required String env,
    int? userId, // Made optional
  }) async {
    if (_initialized) return;

    _endpoint = endpointUrl;
    _apiKey = apiKey;
    _env = env;
    _userId = userId;

    // 1) Determine platform at runtime:
    if (Platform.isAndroid) {
      _platform = 'android';
    } else if (Platform.isIOS) {
      _platform = 'ios';
    } else {
      _platform = 'unknown';
    }

    // 2) Open Hive CE & register adapter
    await EventQueue.initialize();

    // 3) Start listening to connectivity changes
    NetworkManager().initialize();
    NetworkManager().networkStatusStream.listen((status) {
      if (status == NetworkStatus.online) {
        _flushPendingEventsToServer();
      }
    });

    _initialized = true;
  }

  /// Track an event with exactly:
  ///   • type       (String)
  ///   • attributes (Map&lt;String, dynamic&gt;)
  Future<void> trackEvent({
    required String type,
    required Map<String, dynamic> attributes,
  }) async {
    // Check if initialized first
    if (!_initialized) {
      if (kDebugMode) {
        print('TrackerService not initialized. Call initialize() first.');
      }
      return; // Exit early instead of crashing
    }

    try {
      // 1) Format datetime with timezone offset in ISO 8601 format
      // Get the current date and time in the local timezone
      // Example: If local time is 2023-07-15 10:30:00-04:00 (EDT),
      // then 'now' will be 2023-07-15 10:30:00.000 with timezone info preserved
      DateTime now = DateTime.now();
      // Format time as ISO 8601 string, example: "2023-10-15T14:30:45.123+02:00"
      // This captures date, time with milliseconds, and timezone offset
      // Format to ISO 8601 including timezone offset
      String userTime = DateFormat('yyyy-MM-ddTHH:mm:ss').format(now) + 
          (now.timeZoneOffset.isNegative
              ? '-${now.timeZoneOffset.inHours.abs().toString().padLeft(2, '0')}:${(now.timeZoneOffset.inMinutes.abs() % 60).toString().padLeft(2, '0')}'
              : '+${now.timeZoneOffset.inHours.toString().padLeft(2, '0')}:${(now.timeZoneOffset.inMinutes % 60).toString().padLeft(2, '0')}');
      
      // 2) Get timezone offset in hours
      final int timezoneOffset = now.timeZoneOffset.inHours;

      // 3) source constant is always "mobile"
      const String sourceConst = 'mobile';

      final event = TrackedEvent(
        id: _uuid.v7(), // Time-based UUID for better database performance
        type: type,
        attributes: attributes,
        source: sourceConst,
        platform: _platform,
        userId: _userId,
        userTime: userTime,
        timezoneOffset: timezoneOffset,
        env: _env,
      );

      // 4) Check connectivity:
      final connResult = await Connectivity().checkConnectivity();
      final isOnline =
          (connResult == ConnectivityResult.wifi ||
          connResult == ConnectivityResult.mobile);

      if (isOnline) {
        final success = await _sendEventToServer(event: event);
        if (!success) {
          await EventQueue.enqueue(event);
        }
      } else {
        await EventQueue.enqueue(event);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error in trackEvent: $e');
      }
    }
  }

  /// Internal: POST exactly these eight fields as form-data:
  ///   • type
  ///   • attributes (JSON string)
  ///   • user_id
  ///   • user_time
  ///   • timezone_offset
  ///   • source
  ///   • platform
  ///   • env
  Future<bool> _sendEventToServer({required TrackedEvent event}) async {
    try {
      final Map<String, String> formData = {
        'type': event.type,
        // attributes must be a JSON-encoded string in the form-body
        'attributes': jsonEncode(event.attributes),
        if (event.userId != null) 'user_id': event.userId.toString(),
        'user_time': event.userTime,
        'timezone_offset': event.timezoneOffset.toString(),
        'source': event.source,
        'platform': event.platform,
        'env': event.env,
      };

      final response = await http
          .post(
            Uri.parse(_endpoint),
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/x-www-form-urlencoded',
              'Authorization': _apiKey,
            },
            body: formData,
          )
          .timeout(const Duration(seconds: 10));

      if (kDebugMode) {
        print("flutter_custom_tracker: formData: ${formData.toString()}");
        print("flutter_custom_tracker: event.timezoneOffset: ${event.timezoneOffset}");
        print("flutter_custom_tracker: response.statusCode: ${response.statusCode}");
        print("flutter_custom_tracker: response.body: ${response.body}");
      }

      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (_) {
      return false;
    }
  }

  /// Internal: flush queued events when connectivity returns.
  Future<void> _flushPendingEventsToServer() async {
    final pending = await EventQueue.getAllEvents();
    for (final event in pending) {
      // Reuse the original event.userTime & event.userTimezone & source & platform
      final success = await _sendEventToServer(event: event);
      if (success) {
        await EventQueue.removeById(event.id);
      }
    }
  }

  /// Public: manually flush pending events immediately.
  Future<void> flushPendingEvents() async {
    await _flushPendingEventsToServer();
  }

  /// Set or update the user ID after initialization
  void setUserId(int? userId) {
    _userId = userId;
  }
}
