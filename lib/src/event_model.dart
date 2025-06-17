import 'dart:convert';
import 'package:hive_ce/hive.dart';

/// ------------------------------------------------------------------------
/// TrackedEvent now includes:
///  • id             (String)
///  • type           (String)
///  • attributes     (Map&lt;String, dynamic&gt;)    – stored as JSON string in adapter
///  • source         (String)   // always "mobile"
///  • platform       (String)   // "android" or "ios"
///  • userId         (int?)     // optional user ID
///  • user_time      (String)   // local time in yyyy-MM-dd'T'HH:mm:ss
///  • timezoneOffset   (int)   // Timezone offset in hours, e.g. 2, 0, -5
///  • env            (String)
/// ------------------------------------------------------------------------
class TrackedEvent {
  final String id;
  final String type;
  final Map<String, dynamic> attributes;
  final String source; // always "mobile"
  final String platform; // "android" or "ios"
  final int? userId; // Changed to nullable
  final String userTime; // local timestamp string
  final int timezoneOffset; // Timezone offset in hours
  final String env;

  TrackedEvent({
    required this.id,
    required this.type,
    required this.attributes,
    required this.source,
    required this.platform,
    this.userId, // Made optional
    required this.userTime,
    required this.timezoneOffset,
    required this.env,
  });
}

/// ------------------------------------------------------------------------
/// Hive CE TypeAdapter for TrackedEvent:
///  • Reads/writes userTime & timezoneOffset & source & platform
///  • Order of read/write must match exactly.
/// ------------------------------------------------------------------------
class TrackedEventAdapter extends TypeAdapter<TrackedEvent> {
  @override
  final int typeId = 0;

  @override
  TrackedEvent read(BinaryReader reader) {
    final id = reader.readString();
    final type = reader.readString();
    final attributesJson = reader.readString();
    final source = reader.readString();
    final platform = reader.readString();
    final hasUserId = reader.readBool();
    final userId = hasUserId ? reader.readInt() : null;
    final userTime = reader.readString();
    final timezoneOffset = reader.readInt();
    final env = reader.readString();

    return TrackedEvent(
      id: id,
      type: type,
      attributes: Map<String, dynamic>.from(
        jsonDecode(attributesJson) as Map<String, dynamic>,
      ),
      source: source,
      platform: platform,
      userId: userId,
      userTime: userTime,
      timezoneOffset: timezoneOffset,
      env: env,
    );
  }

  @override
  void write(BinaryWriter writer, TrackedEvent event) {
    writer.writeString(event.id);
    writer.writeString(event.type);
    writer.writeString(jsonEncode(event.attributes)); // JSON string
    writer.writeString(event.source);
    writer.writeString(event.platform);
    writer.writeBool(event.userId != null);
    if (event.userId != null) {
      writer.writeInt(event.userId!);
    }
    writer.writeString(event.userTime); // local timestamp string
    writer.writeInt(event.timezoneOffset);
    writer.writeString(event.env);
  }
}
