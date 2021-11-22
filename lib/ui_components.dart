import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:rflutter_alert/rflutter_alert.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_week_view/flutter_week_view.dart';
import 'package:intl/intl.dart';
import 'dart:ui';
import 'package:auto_size_text/auto_size_text.dart';

import 'utils.dart';
import 'centered_circular_progress_indicator.dart';
import 'text_page.dart';
import 'calendar_event.dart';
import 'article.dart';
import 'config.dart' as config;

/// Top bar
var appBar = AppBar(
        title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Image.asset(
                  'res/topLogo.png',
                  width: 75,
                  height: 75,
                  color: Colors.black
              ),
              const Text(
                  config.Strings.DrawTitle,
                  style: TextStyle(color: Colors.white, fontSize: 30, fontFamily: 'Futura', fontWeight: FontWeight.bold)
              ),
              const SizedBox(width: 75)
            ]
        )
      );

/// News page (first app screen)
ValueListenableBuilder<List<Article>> news_page(ArticleList home_articles, var clicked_card_callback) {
  return ValueListenableBuilder(valueListenable: home_articles.articles,
      builder: (context, articles, Widget? _child) {
        Widget child = ListView();
        if (articles.isNotEmpty) {
          articles.removeWhere((article) => (article.date.isBefore(DateTime(2020, 12, 21))));
          articles.sort((a, b) => b.date.compareTo(a.date));
          child = ListView(children:
              articles.map((e) => build_card(e, clicked_card_callback)).toList());
        }
        var refresh_indicator = RefreshIndicator(
            onRefresh: home_articles.refresh, child: child);
        return refresh_indicator;
      });
}

/// Calendar page
ValueListenableBuilder<List<CalendarEvent>> calendar_page(EventList events) {
  return ValueListenableBuilder<List<CalendarEvent>>(
      valueListenable: events.events,
      builder: (context, events, Widget? unused_child) {
        if (events.isEmpty) {
          return const CenteredCircularProgressIndicator();
        }
        List<CalendarEvent> fitted_events = [];
        var min_time = const HourMinute(hour: 12);
        List<DateTime> dates = [];
        for (var e in events) {
          CalendarEvent tmp = CalendarEvent.from(e);
          tmp.start = fit_date_to_cal(e.start);
          tmp.end = fit_date_to_cal(e.end);
          var day = DateTime(tmp.start.year, tmp.start.month, tmp.start.day);
          if (!dates.contains(day)) dates.add(day);

          fitted_events.add(tmp);

          var ev_start = HourMinute(hour: tmp.start.hour, minute: tmp.start.minute);
          if (min_time > ev_start) min_time = ev_start;
        }
        min_time = min_time.subtract(const HourMinute(minute: 30));
        dates.sort((a, b) => a.compareTo(b));
        var wk = WeekView(
            dates: dates,
            initialTime: DateTime.now(),
            minimumTime: min_time,
            hoursColumnStyle: HoursColumnStyle(
                width: 25,
                textAlignment: Alignment.centerRight,
                timeFormatter: (time) => (time.hour.toString() + ' ')
            ),
            dayBarStyleBuilder: (date) => DayBarStyle(dateFormatter: (int year, int month, int day) {
              var date = DateTime(year, month, day);
              var year_str = (year == config.event_year
                  ? DateFormat.Md(Localizations.localeOf(context).languageCode).format(date)
                  : DateFormat.yMd(Localizations.localeOf(context).languageCode).format(date));
              var str = DateFormat.EEEE(Localizations.localeOf(context).languageCode).format(date)
                  + ' ' + year_str;
              return str;
            }),
            events: fitted_events.map((e) => get_wkview_event(context, e)).toList(),
            controller: WeekViewController(zoomCoefficient: .5, minZoom: .5)
        );
        wk.controller.changeZoomFactor(.59);
        return wk;
      }
  );
}

/// Create a [FlutterWeekViewEvent] from a [CalendarEvent]
FlutterWeekViewEvent get_wkview_event(context, calendar_event) {
  return FlutterWeekViewEvent(
      eventTextBuilder: (event, context, dayView, h, w) {
        List<Widget> elements = [
          Expanded(child: AutoSizeText(event.title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  minFontSize: 5,
                  wrapWords: false
          ))
        ];

        return Column(children: elements);
      },
      title: calendar_event.title,
      description: calendar_event.description,
      start: calendar_event.start,
      backgroundColor: config.calendars[calendar_event.type]?['color'],
      end: calendar_event.end,
      padding: const EdgeInsets.all(1),
      margin: const EdgeInsets.fromLTRB(0, 1, 0, 0),
      onTap: () { show_event_popup(calendar_event, context); }
  );
}

/// Create and open an [Alert] popup to show [CalendarEvent] info
void show_event_popup(CalendarEvent event, BuildContext context) {
  List<DialogButton> buttons = [];
  if (event.location.isNotEmpty && event.location != 'TBD') { // TODO remove once calendar fixed
    buttons.add(
        DialogButton(
            child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(height: 80, width: 200, child:
                    AutoSizeText(event.location.replaceAll(',', '\n'), textAlign: TextAlign.right, minFontSize: 6)),
                    const Icon(Icons.location_pin)
                ]),
            color: Colors.transparent,
            onPressed: () async {
              var url = (RegExp(r"-?[0-9]{1,2}\.[0-9]{6}, ?-?[0-9]{1,2}\.[0-9]{6}").hasMatch(event.location))
                  ? Uri(scheme: 'geo', host: event.location).toString()
                  : Uri(scheme: 'geo', host: '0,0', queryParameters: {'q': event.location}).toString();
              launch_url(url);
            }
    ));
  }

  var start_hour = DateFormat.Hm().format(event.start);
  var end_hour = DateFormat.Hm().format(event.end);

  Alert(
      context: context,
      style: AlertStyle(
          isCloseButton: false,
          animationDuration: const Duration(milliseconds: 100),
          backgroundColor: config.calendars[event.type]!['color'],
          alertBorder: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(2))),
          buttonAreaPadding: const EdgeInsets.all(0)
          ),
      buttons: buttons,
      // TODO scrollview
      content: Column(crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
                padding: const EdgeInsets.fromLTRB(0, 5, 0, 0),
                child: Text("$start_hour -> $end_hour",
                    style: const TextStyle(fontSize: 10)),
            ),
            Text(event.summary),
            Html(
                data: event.description.replaceAll('\\n', '<br />'),
                onLinkTap: (s, u1, u2, u3) { launch_url(s.toString()); },
                style: { 'a': Style(color: const Color(config.AppColors.dark_blue)) }
            )
          ])
  ).show();
}

/// Create a [Card] widget from an [Article]
/// Expand to a [TextPage]
Widget build_card(Article article, var action) {
  /*
  final img = article.img.isEmpty ? null
      : FadeInImage(
          placeholder: AssetImage('res/topLogo.png'),
          image: NetworkImage(article.img),
          alignment: Alignment.centerLeft,
          excludeFromSemantics: true
      );
      */
  return Card(
      child: ListTile(
          title: Text(article.title, style: TextStyle(color: (article.read ? Colors.grey : Colors.black))),
          // leading: SizedBox(width: 80, height: 80, child: img),
          trailing: const Icon(Icons.arrow_forward_ios_outlined, color: Colors.grey),
          onTap: () { action(article); }
      ));
}
