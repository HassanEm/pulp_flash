library pulp_flash;

import 'dart:async';
import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PulpFlashProvider extends StatelessWidget {
  const PulpFlashProvider(
      {required this.child,
      this.maxFlashWidth = 300,
      this.maxMessages = 5,
      super.key});
  final Widget child;
  final int maxMessages;
  final double maxFlashWidth;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<PulpFlash>(
      create: (_) =>
          PulpFlash(maxFlashWidth: maxFlashWidth, maxMessages: maxMessages),
      child: child,
    );
  }
}

class PulpFlash extends ChangeNotifier {
  PulpFlash({
    this.maxMessages = 5,
    this.maxFlashWidth = 300,
  });
  final List<Message> _messages = [];
  UnmodifiableListView<Message> get displayingMessages =>
      UnmodifiableListView<Message>(_messages);
  OverlayEntry? _overlayEntry;

  /// [maxMessages] is the maximum number of messages that can be displayed at the same time.
  final int maxMessages;

  /// [maxFlashWidth] is the maximum width of the flash message.
  final double maxFlashWidth;

  /// [_insertOverlay] adds the overlay to the screen.
  void _insertOverlay(BuildContext context) {
    if (_overlayEntry != null) {
      return;
    }

    /// OverlayEntry uses a Cunsumer<PulpFlash> to listen for changes and rebuild if needed.
    _overlayEntry = OverlayEntry(
        builder: (context) => Positioned(
              bottom: 32,
              left: 32,
              child: Consumer<PulpFlash>(
                builder: (context, model, _) => Column(
                    mainAxisSize: MainAxisSize.min,
                    children: model._messages
                        .map((m) => _FlashWidget(
                              m,
                              maxFlashWidth,
                              key: ValueKey('Key:${m.key}'),
                            ))
                        .toList()),
              ),
            ));
    Overlay.of(context).insert(_overlayEntry!);
  }

  /// [removeMessage] removes the message from [_messages] and notifyListeners.
  void removeMessage(Message m) {
    _messages.remove(m);
    if (_messages.isEmpty) {
      _overlayEntry?.remove();
      _overlayEntry = null;
    }
    notifyListeners();
  }

  /// [showMessage] get a context and a message and show it.
  /// note: tow message with same key not allowed.
  void showMessage(BuildContext context,
      {required Message inputMessage,
      Duration duration = const Duration(seconds: 5)}) async {
    /// if the _overlayEntry is already displayes, do nothing.
    if (_overlayEntry == null) {
      _insertOverlay(context);
    }

    /// Prevent to show a message with same key (for similar key error issues).
    if (displayingMessages.where((m) => m.key == inputMessage.key).isNotEmpty) {
      return;
    }

    /// Prevent to show more than [maxMessages] messages.
    if (_messages.length >= maxMessages) {
      removeMessage(_messages.firstWhere((m) => !m.pinned,
          orElse: () => _messages.first));
    }
    _messages.add(inputMessage);
    notifyListeners();
  }

  static PulpFlash of(BuildContext context) {
    return Provider.of<PulpFlash>(context, listen: false);
  }
}

/// [status] is just for preffred color, text, icon, etc.
enum FlashStatus { error, tips, successful, warning, custom }

extension _FlashStatusExt on FlashStatus {
  String get title {
    switch (this) {
      case FlashStatus.error:
        return "Erorr";
      case FlashStatus.successful:
        return "Successful";
      case FlashStatus.tips:
        return "Tips";
      case FlashStatus.warning:
        return "Warning";
      case FlashStatus.custom:
        return "New Message";
    }
  }

  MaterialColor get color {
    switch (this) {
      case FlashStatus.tips:
        return Colors.blue;
      case FlashStatus.successful:
        return Colors.green;
      case FlashStatus.error:
        return Colors.red;
      case FlashStatus.warning:
        return Colors.amber;
      case FlashStatus.custom:
        return Colors.grey;
    }
  }

  IconData get icon {
    switch (this) {
      case FlashStatus.tips:
        return Icons.tips_and_updates_rounded;
      case FlashStatus.successful:
        return Icons.check_rounded;
      case FlashStatus.error:
        return Icons.error_rounded;
      case FlashStatus.warning:
        return Icons.warning_rounded;
      case FlashStatus.custom:
        return Icons.circle;
    }
  }
}

class Message {
  /// [Message] containe all information that is needed to display a flash message.
  Message(
      {this.title,
      this.expandable = true,
      this.description,
      required this.status,
      this.actionLabel,
      this.onActionPressed,
      this.pinned = false,
      this.key,
      this.color,
      this.icon,
      this.displayDuration = const Duration(seconds: 10)}) {
    key ??= UniqueKey();
  }

  late Key? key;

  /// [status] is just for preffred color, text, icon, etc.
  final FlashStatus status;
  final String? title;
  final String? description;

  final Color? color;
  final IconData? icon;

  /// [displayDuration] is the duration that the message will be displayed.
  final Duration displayDuration;
  final String? actionLabel;
  final void Function()? onActionPressed;

  /// When [expandable] is true, flash just show the title and when you hover on it more details are shown with animation.
  /// pinned messages are infinitely displayed.
  final bool pinned, expandable;
}

class _FlashWidget extends StatefulWidget {
  const _FlashWidget(this.message, this.maxWidth, {Key? key}) : super(key: key);
  final Message message;
  final double maxWidth;

  @override
  State<_FlashWidget> createState() => _FlashWidgetState();
}

class _FlashWidgetState extends State<_FlashWidget> {
  late final Future<void>? timeOutAction;
  Tween<double> fadinFadeout = Tween<double>(begin: 0, end: 1);
  bool exapnd = false;
  @override
  void initState() {
    super.initState();

    timeOutAction = widget.message.pinned
        ? null
        : Future<void>.delayed(widget.message.displayDuration)
            .whenComplete(() => dissmiss(context));
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: widget.maxWidth),
      child: TweenAnimationBuilder<double>(
        tween: fadinFadeout,
        duration: const Duration(milliseconds: 200),
        builder: (context, value, child) =>
            Opacity(opacity: value, child: child!),
        child: Card(
          clipBehavior: Clip.antiAlias,
          child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: widget.maxWidth, end: 0),
              duration: widget.message.displayDuration,
              builder: (context, value, child) {
                final Widget headerWidget = ListTile(
                  subtitle: (exapnd || !widget.message.expandable) &&
                          widget.message.description?.isNotEmpty == true
                      ? Text(widget.message.description!)
                      : null,
                  key: ValueKey('key_first${widget.message.key}'),
                  horizontalTitleGap: 0,
                  leading: Icon(
                      widget.message.icon ?? widget.message.status.icon,
                      color:
                          widget.message.color ?? widget.message.status.color),
                  title:
                      Text(widget.message.title ?? widget.message.status.title),
                  trailing: IconButton(
                      onPressed: () => dissmiss(context),
                      icon: const Icon(Icons.close_rounded)),
                );
                return MouseRegion(
                  onEnter: !widget.message.expandable
                      ? null
                      : (_) => setState(() => exapnd = true),
                  onExit: !widget.message.expandable
                      ? null
                      : (_) => setState(() => exapnd = false),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!widget.message.pinned)
                        Container(
                          color: widget.message.color ??
                              widget.message.status.color,
                          width: value,
                          height: 3,
                        ),
                      AnimatedSize(
                        duration: const Duration(milliseconds: 200),
                        child: (!exapnd && widget.message.expandable)
                            ? headerWidget
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                key:
                                    ValueKey('key_second${widget.message.key}'),
                                children: [
                                  headerWidget,
                                  if (widget.message.actionLabel != null ||
                                      widget.message.onActionPressed != null)
                                    Row(
                                      children: [
                                        const SizedBox(width: 50),
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(bottom: 16),
                                          child: InkWell(
                                            borderRadius:
                                                BorderRadius.circular(3),
                                            onTap: () {
                                              if (widget.message
                                                      .onActionPressed !=
                                                  null) {
                                                widget
                                                    .message.onActionPressed!();
                                              }
                                              dissmiss(context);
                                            },
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.all(2.0),
                                              child: Text(
                                                widget.message.actionLabel ??
                                                    'Action',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .labelSmall
                                                    ?.apply(
                                                        fontSizeDelta: 2,
                                                        fontWeightDelta: 4,
                                                        color: widget.message
                                                                    .onActionPressed ==
                                                                null
                                                            ? Theme.of(context)
                                                                .disabledColor
                                                            : widget.message
                                                                    .color ??
                                                                widget
                                                                    .message
                                                                    .status
                                                                    .color),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                      )
                    ],
                  ),
                );
              }),
          margin: const EdgeInsets.symmetric(vertical: 8),
        ),
      ),
    );
    // );
  }

  Future<void> dissmiss(BuildContext context) async {
    setState(() => fadinFadeout = Tween<double>(begin: 0, end: 0));
    await Future.delayed(const Duration(milliseconds: 400));
    Provider.of<PulpFlash>(context, listen: false)
        .removeMessage(widget.message);
  }

  @override
  void dispose() {
    super.dispose();
    timeOutAction?.ignore();
  }
}
