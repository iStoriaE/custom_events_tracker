import 'dart:convert';
import 'package:hive_ce/hive.dart';

/// ------------------------------------------------------------------------
/// TrackedEvent now includes:
///  • id             (String)
///  • type           (String)
///  • attributes     (Map<String, dynamic>)    – stored as JSON string in adapter
///  • source         (String)   // always "mobile"
///  • platform       (String)   // "android" or "ios"
///  • userId         (int)
///  • user_time      (String)   // local time in yyyy-MM-dd'T'HH:mm:ssXXX
///  • userTimezone   (String)   // IANA timezone name, e.g. "Asia/Gaza"
///  • env            (String)
/// ------------------------------------------------------------------------
class TrackedEvent {
  final String id;
  final String type;
  final Map<String, dynamic> attributes;
  final String source;       // always "mobile"
  final String platform;     // "android" or "ios"
  final int userId;
  final String userTime;     // local timestamp string
  final String userTimezone; // IANA timezone string
  final String env;

  TrackedEvent({
    required this.id,
    required this.type,
    required this.attributes,
    required this.source,
    required this.platform,
    required this.userId,
    required this.userTime,
    required this.userTimezone,
    required this.env,
  });
}

/// ------------------------------------------------------------------------
/// Hive CE TypeAdapter for TrackedEvent:
///  • Reads/writes userTime & userTimezone & source & platform
///  • Order of read/write must match exactly.
/// ------------------------------------------------------------------------
class TrackedEventAdapter extends TypeAdapter<TrackedEvent> {
  @override
  final int typeId = 0;

  @override
  TrackedEvent read(BinaryReader reader) {
    final id             = reader.readString();
    final type           = reader.readString();
    final attributesJson = reader.readString();
    final source         = reader.readString();
    final platform       = reader.readString();
    final userId         = reader.readInt();
    final userTime       = reader.readString();
    final userTimezone   = reader.readString();
    final env            = reader.readString();

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
      userTimezone: userTimezone,
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
    writer.writeInt(event.userId);
    writer.writeString(event.userTime);       // local timestamp string
    writer.writeString(event.userTimezone);   // IANA timezone
    writer.writeString(event.env);
  }
}
