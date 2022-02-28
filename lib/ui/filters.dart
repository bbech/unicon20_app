
import '../config.dart' as config;
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:unicon/data/event.dart';

var day_status = {};
build_day_filter_btns(events) {
return ValueListenableBuilder(
			valueListenable: events.items, child: const CircularProgressIndicator(),
			builder: (context, List<Event> events_list, _child) {
			var ev_days = events.get_day_extent();
			var children = <Widget>[];

			for (DateTime d in ev_days) {
				var timestamp = d.millisecondsSinceEpoch;
				if (!day_status.keys.contains(timestamp))
						day_status[timestamp] = false;
				children.add(CheckboxListTile(checkColor: Colors.white, value: day_status[timestamp], onChanged: (b) {
							day_status[timestamp] = !day_status[timestamp];
							List<DateTime> selected = [];
							for (var e in day_status.keys) {
								if (day_status[e] == true)
									selected.add(DateTime.fromMillisecondsSinceEpoch(e));
							}
							events.filter_by_days(selected);
						},
						dense: true, visualDensity: const VisualDensity(vertical: -4),
						contentPadding: EdgeInsets.zero,
						title: Text(DateFormat.E(Localizations.localeOf(context).languageCode).format(d)
							+ ' ' + DateFormat.Md(Localizations.localeOf(context).languageCode).format(d),
							style: const TextStyle(height: 1, color: Colors.white))
			));
			}
			return Column(children: children);
			});
}

var cal_status = {};
build_calendar_filter(events) {
return ValueListenableBuilder(
			valueListenable: events.items, child: const CircularProgressIndicator(),
			builder: (context, List<Event> events_list, _child) {
			var calendars = events.get_calendars();
			var children = <Widget>[];

			for (var cal in calendars) {
				if (!cal_status.keys.contains(cal))
						cal_status[cal] = false;
				children.add(Container(color: config.calendars[cal]?['color'],
				child: CheckboxListTile(
					checkColor: Colors.white,
					value: cal_status[cal],
					onChanged: (b) {
							cal_status[cal] = !cal_status[cal];
							var selected = [];
							for (var c in cal_status.keys) {
								if (cal_status[c] == true)
									selected.add(c);
							}
							events.filter_by_types(selected);
						},
						dense: true, subtitle: null, visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
						title: Text(cal,
							style: const TextStyle(height: 1))
			)));
			}
			return Column(children: children);
			});
}

get_filters(evlist) {
	return Container(
	color: Colors.black.withOpacity(.3),
	child: Column(children: [
				ExpansionTile(
					title: const Text('days', style: TextStyle(color: Colors.white)),
					children: [build_day_filter_btns(evlist)]
					),
				 ExpansionTile(
					title: const Text('legend', style: TextStyle(color: Colors.white)),
					children: [build_calendar_filter(evlist)]
					)
	]));

}