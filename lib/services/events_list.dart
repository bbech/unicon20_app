import 'dart:developer';
import 'package:flutter/cupertino.dart';
import 'package:sqflite/sqflite.dart';

import '../data/event.dart';
import '../tools/api.dart' as api;

/// Hold a [CalendarEvent] list, a connection
/// to [Database] and functions to read from
/// an ICS URL
class EventList {
  late Database _db;
  final events = ValueNotifier<List<CalendarEvent>>([]);

  EventList({required db}) {
    _db = db;
  }

  /// Get events from db and from ics calendar
  get_events() async {
    await get_events_from_db()
        .then((e) {
          events.value += e;
        });
    if (events.value.isEmpty) {
      await get_events_from_ics();
    }
  }

  /// Clear and refresh events from db & ics
  refresh() async {
    events.value = [];
    get_events();
  }

  /// Download new events
  get_events_from_ics() {
    var new_events_list = api.get_events_from_ics();
    new_events_list.then((new_event) {
      events.value += new_event;
      new_event.forEach(save_event);
    }).catchError((error) {
      log('error while downloading new articles: $error');
    });
  }

  /// Save a new [CalendarEvent]
  save_event(CalendarEvent event) {
    _db.insert('events', event.toSqlMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Read events from db
  Future<List<CalendarEvent>> get_events_from_db() async {
    var raw_events = await _db.query('events');

    return raw_events.map((e) {
      dynamic start = e['start'];
      dynamic end = e['end'];
      return CalendarEvent(
          uid: e['uid'].toString(),
          title: e['title'].toString(),
          start: DateTime.fromMillisecondsSinceEpoch(start),
          end: DateTime.fromMillisecondsSinceEpoch(end),
          location: e['location'].toString(),
          type: e['type'].toString(),
          description: e['description'].toString(),
          summary: e['summary'].toString()
      );
    }).toList();
  }
}