/// App base widget

import 'package:flutter/material.dart';
import 'package:background_fetch/background_fetch.dart';

import 'screen/places.dart';
import 'services/articles_list.dart';
import 'services/database.dart';
import 'services/events_list.dart';
import 'data/article.dart';
import 'services/notifications.dart';
import 'ui/text_page.dart';
import 'screen/calendar.dart';
import 'screen/news.dart';
import 'config.dart' as config;
import 'tools/background_service.dart';


class MyHomePage extends StatefulWidget {
	MyHomePage({Key? key}) : super(key: key);

	final db = DBInstance();
	late final notifier = Notifications();

	late final articles = ArticleList(db: db);
	late final events = EventList(db: db);

	@override
		State<MyHomePage> createState() => _MyHomePageState();

	background_task() async {
		events.refresh();
		var new_articles = await articles.refresh();
		Article last = new_articles.first;
		if (new_articles.isNotEmpty) {
			notifier.show(
					last.title, '',
					'${last.id}',
					last.categories.get_first()?.slug,
					last.categories.get_first()?.name
					);
		}
	}
}

class _MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin {

  late final TabController _principalController = TabController(length: 3, vsync: this, initialIndex: 0);
  late String lang;

  @override
    Widget build(BuildContext context) {
      return Scaffold(
          body: TabBarView(
						physics: const NeverScrollableScrollPhysics(),
            controller: _principalController,
            children: [
              news_page(widget.articles, openArticle),
							calendar_page(widget.events),
							places_page(widget.events)
            ]
          ),
          bottomNavigationBar: Container(
            color: Colors.white,
						padding: const EdgeInsets.all(4.0),
            child: TabBar(
              controller: _principalController,
              indicatorColor: const Color(config.AppColors.green),
              indicatorSize: TabBarIndicatorSize.label,
              indicatorWeight: 2,
              labelColor: const Color(config.AppColors.green),
              unselectedLabelColor: const Color(config.AppColors.light_blue),
              tabs: const [
                Tab(icon: Icon(Icons.home)),
								Tab(icon: Icon(Icons.access_time)),
                Tab(icon: Icon(Icons.place))
              ]
              )
            )
          );
    }

  @override
    initState() {
      super.initState();
      widget.events.fill();
      initBackgroundService(widget.background_task)
        .then((e) => BackgroundFetch.start());
    }

  @override
    void didChangeDependencies() async {
      if (widget.articles.lang == null) {
        await widget.articles.init_lang();
      }
      var cur_lang = Localizations.localeOf(context).languageCode;
      if (widget.articles.lang != cur_lang) {
        widget.articles.update_lang(cur_lang);
      }
      else if (widget.articles.items.value.isEmpty) {
        widget.articles.fill();
      }
      super.didChangeDependencies();
    }

  /// At the closing of the app, we destroy everything so it close clean.
  /// (background service will still run)
  @override
    void dispose() {
      _principalController.dispose();
      widget.db.close();
      super.dispose();
    }

  openArticle(Article article) {
		if (Navigator.canPop(context)) Navigator.pop(context);
		_principalController.index = 0;
		Navigator.push(context,
				MaterialPageRoute(builder: (context) =>
					TextPage(title: article.title, content: article.content, date: article.date)));
	}
}
