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

  final _uuid = Uuid();
  bool _initialized = false;
  late String _endpoint;
  late String _apiKey;
  late String _env;
  late int _userId;
  late String _platform; // "android" or "ios"

  /// Initialize once (e.g. in main()):
  ///  • endpointUrl : your backend URL
  ///  • env         : "production", "staging", etc.
  ///  • userId      : current user’s ID (int)
  Future<void> initialize({
    required String endpointUrl,
    required String apiKey,
    required String env,
    required int userId,
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
    // 1) Obtain local DateTime and format as ISO 8601 with timezone offset
    final DateTime nowLocal = DateTime.now();
    final DateFormat formatter = DateFormat("yyyy-MM-dd'T'HH:mm:ss");
    final String offset = nowLocal.timeZoneOffset.isNegative
        ? '-${nowLocal.timeZoneOffset.abs().inHours.toString().padLeft(2, '0')}:${(nowLocal.timeZoneOffset.abs().inMinutes % 60).toString().padLeft(2, '0')}'
        : '+${nowLocal.timeZoneOffset.inHours.toString().padLeft(2, '0')}:${(nowLocal.timeZoneOffset.inMinutes % 60).toString().padLeft(2, '0')}';
    final String userTimeStr = '${formatter.format(nowLocal)}$offset';

    // 3) source constant is always "mobile"
    const String sourceConst = 'mobile';

    final event = TrackedEvent(
      id: _uuid.v4(),
      type: type,
      attributes: attributes,
      source: sourceConst,
      platform: _platform,
      userId: _userId,
      userTime: userTimeStr,
      userTimezone: offset,
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
  }

  /// Internal: POST exactly these eight fields as form-data:
  ///   • type
  ///   • attributes (JSON string)
  ///   • user_id
  ///   • user_time
  ///   • user_timezone
  ///   • source
  ///   • platform
  ///   • env
  Future<bool> _sendEventToServer({required TrackedEvent event}) async {
    try {
      final Map<String, String> formData = {
        'type': event.type,
        // attributes must be a JSON-encoded string in the form-body
        'attributes': jsonEncode(event.attributes),
        'user_id': event.userId.toString(),
        'user_time': event.userTime, // e.g. "2025-06-04T14:20:30+02:00"
        'user_timezone': event.userTimezone, // e.g. "Asia/Gaza"
        'source': event.source, // always "mobile"
        'platform': event.platform, // "android" or "ios"
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
        print("ISTORIAEVENTTRACKER${event.userTimezone}");
        print("ISTORIAEVENTTRACKER${response.statusCode}");
        print("ISTORIAEVENTTRACKER${response.body}");
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
}
