import 'package:PiliPlus/common/skeleton/video_reply.dart';
import 'package:PiliPlus/common/sliver_single_child_delegate.dart';
import 'package:PiliPlus/common/style.dart';
import 'package:PiliPlus/common/widgets/loading_widget/http_error.dart';
import 'package:PiliPlus/common/widgets/scaffold/mini_scaffold.dart';
import 'package:PiliPlus/common/widgets/sliver/sliver_floating_header.dart';
import 'package:PiliPlus/grpc/bilibili/main/community/reply/v1.pb.dart'
    show ReplyInfo;
import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/pages/video/reply/controller.dart';
import 'package:PiliPlus/pages/video/reply/vote/reply_vote_item.dart';
import 'package:PiliPlus/pages/video/reply/widgets/reply_item_grpc.dart';
import 'package:PiliPlus/pages/video/reply_reply/view.dart';
import 'package:PiliPlus/utils/feed_back.dart';
import 'package:easy_debounce/easy_throttle.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

class VideoReplySlivers extends StatefulWidget {
  const VideoReplySlivers({
    super.key,
    required this.heroTag,
    this.replyLevel = 1,
  });

  final String heroTag;
  final int replyLevel;

  @override
  State<VideoReplySlivers> createState() => _VideoReplySliversState();
}

class _VideoReplySliversState extends State<VideoReplySlivers> {
  late VideoReplyController _videoReplyController;
  late ColorScheme colorScheme;
  double bottom = 0;

  @override
  void initState() {
    super.initState();
    _videoReplyController = Get.find<VideoReplyController>(tag: widget.heroTag);
    if (_videoReplyController.loadingState.value is Loading) {
      _videoReplyController.queryData();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    colorScheme = ColorScheme.of(context);
    bottom = MediaQuery.viewPaddingOf(context).bottom;
  }

  @override
  Widget build(BuildContext context) {
    return SliverMainAxisGroup(
      slivers: [
        SliverFloatingHeaderWidget(
          backgroundColor: colorScheme.surface,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 2.5, 6, 2.5),
            child: Obx(() {
              final sortType = _videoReplyController.sortType.value;
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    sortType.desc,
                    style: const TextStyle(fontSize: 13),
                  ),
                  TextButton.icon(
                    style: Style.buttonStyle,
                    onPressed: _videoReplyController.queryBySort,
                    icon: Icon(
                      Icons.sort,
                      size: 16,
                      color: colorScheme.secondary,
                    ),
                    label: Text(
                      sortType.descShort,
                      style: TextStyle(
                        fontSize: 13,
                        color: colorScheme.secondary,
                      ),
                    ),
                  ),
                ],
              );
            }),
          ),
        ),
        Obx(() => _buildBody(_videoReplyController.loadingState.value)),
      ],
    );
  }

  Widget _buildBody(LoadingState<List<ReplyInfo>?> loadingState) {
    switch (loadingState) {
      case Loading():
        return const SliverPrototypeExtentList(
          prototypeItem: VideoReplySkeleton(),
          delegate: SliverSingleChildDelegate(
            count: 5,
            child: VideoReplySkeleton(),
          ),
        );
      case Success(:final response):
        if (response != null && response.isNotEmpty) {
          var count = response.length + 1;
          final voteCard = _videoReplyController.voteCard;
          final hasVote = voteCard != null;
          if (hasVote) {
            count++;
          }
          return SliverList.builder(
            itemBuilder: (context, index) {
              if (hasVote) {
                if (index == 0) {
                  return buildVoteCard(context, colorScheme, voteCard);
                } else {
                  index--;
                }
              }
              if (index == response.length) {
                _videoReplyController.onLoadMore();
                return Container(
                  height: 125,
                  alignment: Alignment.center,
                  margin: EdgeInsets.only(bottom: bottom),
                  child: Text(
                    _videoReplyController.isEnd ? '没有更多了' : '加载中...',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: colorScheme.outline),
                  ),
                );
              } else {
                return ReplyItemGrpc(
                  replyItem: response[index],
                  replyLevel: widget.replyLevel,
                  replyReply: replyReply,
                  onReply: _videoReplyController.onReply,
                  onDelete: (item, subIndex) =>
                      _videoReplyController.onRemove(index, item, subIndex),
                  upMid: _videoReplyController.upMid,
                  getTag: () => widget.heroTag,
                  onCheckReply: _videoReplyController.onCheckReply,
                  onToggleTop: (item) => _videoReplyController.onToggleTop(
                    item,
                    index,
                    _videoReplyController.aid,
                    _videoReplyController.videoType.replyType,
                  ),
                );
              }
            },
            itemCount: count,
          );
        }

        final child = SliverToBoxAdapter(
          child: HttpError(
            errMsg: '还没有评论',
            onReload: _videoReplyController.onReload,
          ),
        );
        if (_videoReplyController.voteCard case final voteCard?) {
          return SliverMainAxisGroup(
            slivers: [
              SliverToBoxAdapter(
                child: buildVoteCard(context, colorScheme, voteCard),
              ),
              child,
            ],
          );
        }
        return child;
      case Error(:final errMsg):
        return SliverToBoxAdapter(
          child: HttpError(
            errMsg: errMsg,
            onReload: _videoReplyController.onReload,
          ),
        );
    }
  }

  void replyReply(ReplyInfo replyItem, int? id) {
    EasyThrottle.throttle('replyReply', const Duration(milliseconds: 500), () {
      int oid = replyItem.oid.toInt();
      int rpid = replyItem.id.toInt();
      MiniScaffold.of(context).showBottomSheet(
        constraints: const BoxConstraints(),
        (context) => VideoReplyReplyPanel(
          id: id,
          oid: oid,
          rpid: rpid,
          firstFloor: replyItem.replyControl.isNote ? null : replyItem,
          replyType: _videoReplyController.videoType.replyType,
          isVideoDetail: true,
          isNested: true,
          upMid: _videoReplyController.upMid,
        ),
      );
    });
  }
}
