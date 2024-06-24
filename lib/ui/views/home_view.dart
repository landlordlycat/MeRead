import 'package:flutter/material.dart';
import 'package:flutter_swipe_action_cell/flutter_swipe_action_cell.dart';
import 'package:get/get.dart';
import 'package:meread/helpers/isar_helper.dart';
import 'package:meread/helpers/prefs_helper.dart';
import 'package:meread/models/category.dart';
import 'package:meread/models/feed.dart';
import 'package:meread/models/post.dart';
import 'package:meread/ui/viewmodels/home_controller.dart';
import 'package:meread/ui/widgets/post_card.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final GlobalKey<RefreshIndicatorState> _refreshKey = GlobalKey();
  final c = Get.put(HomeController());

  @override
  void initState() {
    super.initState();
    if (PrefsHelper.refreshOnStartup) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _refreshKey.currentState?.show();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Obx(() => Text(
              c.appBarTitle.value,
            )),
        centerTitle: false,
        actions: [
          IconButton(
            onPressed: c.filterUnread,
            icon: Obx(() => c.onlyUnread.value
                ? const Icon(Icons.radio_button_checked)
                : const Icon(Icons.radio_button_unchecked)),
          ),
          IconButton(
            onPressed: c.filterFavorite,
            icon: Obx(() => c.onlyFavorite.value
                ? const Icon(Icons.bookmark)
                : const Icon(Icons.bookmark_border_outlined)),
          ),
          PopupMenuButton(
            elevation: 1,
            position: PopupMenuPosition.under,
            itemBuilder: (BuildContext context) {
              return <PopupMenuEntry>[
                PopupMenuItem(
                  onTap: c.markAllRead,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Icon(Icons.done_all_outlined, size: 20),
                      const SizedBox(width: 10),
                      Text('markAllAsRead'.tr),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                PopupMenuItem(
                  child: SearchAnchor(
                    isFullScreen: true,
                    searchController: c.searchController,
                    builder: (context, controller) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Icon(Icons.search_outlined, size: 20),
                          const SizedBox(width: 10),
                          Text('fullTextSearch'.tr),
                        ],
                      );
                    },
                    suggestionsBuilder: (BuildContext context,
                        SearchController controller) async {
                      List<Post> results =
                          await IsarHelper.search(controller.text);
                      return results
                          .map((e) => Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 4),
                                child: PostCard(post: e),
                              ))
                          .toList();
                    },
                  ),
                ),
                PopupMenuItem(
                  onTap: c.toAddFeed,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Icon(Icons.add_outlined, size: 20),
                      const SizedBox(width: 10),
                      Text('addFeed'.tr),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                PopupMenuItem(
                  onTap: c.toSetting,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Icon(Icons.settings_outlined, size: 20),
                      const SizedBox(width: 10),
                      Text('moreSetting'.tr),
                    ],
                  ),
                ),
              ];
            },
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          key: _refreshKey,
          onRefresh: c.refreshPosts,
          child: Obx(
            () => ListView.separated(
              physics: c.postList.isEmpty
                  ? const AlwaysScrollableScrollPhysics()
                  : const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
              itemBuilder: (context, index) {
                return SwipeActionCell(
                  key: ObjectKey(c.postList[index]),
                  trailingActions: [
                    SwipeAction(
                      color: Colors.transparent,
                      content: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(25),
                          color:
                              Theme.of(context).colorScheme.secondaryContainer,
                        ),
                        child: Icon(
                          Icons.done_outline_rounded,
                          color: Theme.of(context)
                              .colorScheme
                              .onSecondaryContainer,
                        ),
                      ),
                      onTap: (handler) async {
                        c.updateReadStatus(c.postList[index]);
                        c.getUnreadCount();
                        await handler(false);
                      },
                    ),
                  ],
                  child: InkWell(
                    onTap: () {
                      Get.toNamed('/post', arguments: c.postList[index])!
                          .then((_) {
                        c.getPosts();
                        c.getUnreadCount();
                      });
                    },
                    child: PostCard(post: c.postList[index]),
                  ),
                );
              },
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemCount: c.postList.length,
            ),
          ),
        ),
      ),
      drawerEdgeDragWidth: Get.width * 0.3,
      drawer: Drawer(
        child: SafeArea(
          child: Obx(
            () => ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: 12),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                  child: ListTile(
                    title: Text('allFeeds'.tr),
                    onTap: c.focusAllFeeds,
                    tileColor: Theme.of(context)
                        .colorScheme
                        .secondaryContainer
                        .withAlpha(80),
                    visualDensity: VisualDensity.compact,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                ),
                for (Category category in c.categorys)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    child: ExpansionTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      collapsedShape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      visualDensity: VisualDensity.compact,
                      title: GestureDetector(
                        onTap: () {
                          c.focusCategory(category);
                        },
                        child: Text(
                            '${category.name} (${c.getUnreadCountByCategory(category)})'),
                      ),
                      children: [
                        Column(
                          children: [
                            for (Feed feed in category.feeds)
                              ListTile(
                                dense: true,
                                title: Text(
                                  feed.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: Text(c.unreadCount[feed].toString()),
                                tileColor: Theme.of(context)
                                    .colorScheme
                                    .secondaryContainer
                                    .withAlpha(80),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(
                                        feed == category.feeds.first ? 24 : 0),
                                    bottom: Radius.circular(
                                        feed == category.feeds.last ? 24 : 0),
                                  ),
                                ),
                                onTap: () {
                                  c.focusFeed(feed);
                                },
                                onLongPress: () => c.toEditFeed(feed),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
