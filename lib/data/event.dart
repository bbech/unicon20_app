import '../tools/utils.dart';
import 'abstract.dart';

/// Event data
class CalendarEvent extends AData {
  final String uid;
  final String title;
  DateTime start;
  DateTime end;
  final String location;
  final String type;
  final String description;
  final String summary;

  CalendarEvent({
    required this.uid,
    required this.title,
    required this.start,
    required this.end,
    required this.location,
    required this.type,
    required this.description,
    required this.summary
  });

  CalendarEvent.from(CalendarEvent e)
      : uid = e.uid,
      title = e.title,
      start = e.start,
      end = e.end,
      location = e.location,
      type = e.type,
      description = e.description,
      summary = e.summary;

  CalendarEvent.fromICalJson(json, String calendar)
      : uid = json['UID'].toString(),
      title = clean_ics_text_fields(json['SUMMARY']),
      start = DateTime.parse(json['DTSTART']).toLocal(),
      end = DateTime.parse(json['DTEND']).toLocal(),
      location = clean_ics_text_fields(json['LOCATION']),
      type = calendar,
      description = clean_ics_text_fields(json['DESCRIPTION']),
      summary = clean_ics_text_fields(json['SUMMARY']);

  get id return uid;

  Map<String, dynamic> toSqlMap() {
    return {
      'uid': uid,
      'title': title,
      'start': start.millisecondsSinceEpoch,
      'end': end.millisecondsSinceEpoch,
      'location': location,
      'type': type,
      'description': description,
      'summary': summary
    };
  }

  @override
  String toString() {
    return "$title $start $end (start is utc: ${start.isUtc})";
  }
}
