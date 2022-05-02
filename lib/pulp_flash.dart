library pulp_flash;

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PulpFlash extends ChangeNotifier {
  final List<Message> _messages = [];
  OverlayEntry? _overlayEntry;

  void _insertOverlay(BuildContext context) {
    if (_overlayEntry != null) {
      return;
    }
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
                              key: ValueKey('Key:${m.id}'),
                            ))
                        .toList()),
              ),
            ));
    Overlay.of(context)?.insert(_overlayEntry!);
  }

  void _removeMessage(Message m) {
    _messages.remove(m);
    if (_messages.isEmpty) {
      _overlayEntry?.remove();
      _overlayEntry = null;
    }
    notifyListeners();
  }

  void showMessage(BuildContext context,
      {required Message inputMessage,
      Duration duration = const Duration(seconds: 5)}) async {
    if (_overlayEntry == null) {
      _insertOverlay(context);
    }

    if (_messages.length >= 5) {
      _removeMessage(_messages.firstWhere((m) => !m.pinned,
          orElse: () => _messages.first));
    }
    _messages.add(inputMessage);
    notifyListeners();
  }
}

enum FlashStatus { error, tips, successful, warning }

extension _FlashStatusExt on FlashStatus {
  String get text {
    switch (this) {
      case FlashStatus.error:
        return "Erorr";
      case FlashStatus.successful:
        return "Successful";
      case FlashStatus.tips:
        return "Tips";
      case FlashStatus.warning:
        return "Warning";
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
    }
  }
}

class Message {
  Message(
      {this.title,
      this.description,
      required this.status,
      this.actionLabel,
      this.onActionPressed,
      this.pinned = false,
      this.displayDuration = const Duration(seconds: 10)});

  final String id =
      '${10000000 + Random().nextInt(89999999)}.${Random().nextDouble()}.${10000000 + Random().nextInt(89999999)}';

  final FlashStatus status;
  final String? title;
  final String? description;
  final Duration displayDuration;
  final String? actionLabel;
  final void Function()? onActionPressed;
  final bool pinned;
}

class _FlashWidget extends StatefulWidget {
  const _FlashWidget(this.message, {Key? key}) : super(key: key);
  final Message message;

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
    const double maxWidth = 300;
    return ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: maxWidth),
        child: TweenAnimationBuilder<double>(
          tween: fadinFadeout,
          duration: const Duration(milliseconds: 200),
          builder: (context, value, child) =>
              Opacity(opacity: value, child: child!),
          child: Card(
            clipBehavior: Clip.antiAlias,
            child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: maxWidth, end: 0),
                duration: widget.message.displayDuration,
                builder: (context, value, child) {
                  final Widget headerWidget = ListTile(
                    isThreeLine: exapnd &&
                        widget.message.description?.isNotEmpty == true,
                    subtitle:
                        exapnd && widget.message.description?.isNotEmpty == true
                            ? Text(widget.message.description!)
                            : null,
                    key: ValueKey('key_first${widget.message.id}'),
                    horizontalTitleGap: 0,
                    leading: Icon(widget.message.status.icon,
                        color: widget.message.status.color),
                    title: Text(
                        widget.message.title ?? widget.message.status.text),
                    trailing: IconButton(
                        onPressed: () => dissmiss(context),
                        icon: const Icon(Icons.close_rounded)),
                  );
                  return MouseRegion(
                    onEnter: (_) => setState(() => exapnd = true),
                    onExit: (_) => setState(() => exapnd = false),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!widget.message.pinned)
                          Container(
                            color: widget.message.status.color,
                            width: value,
                            height: 3,
                          ),
                        AnimatedSize(
                          duration: const Duration(milliseconds: 200),
                          child: !exapnd
                              ? headerWidget
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  key: ValueKey(
                                      'key_second${widget.message.id}'),
                                  children: [
                                    headerWidget,
                                    if (widget.message.actionLabel != null ||
                                        widget.message.onActionPressed != null)
                                      Padding(
                                        padding: const EdgeInsets.only(
                                            left: 52, bottom: 16),
                                        child: InkWell(
                                          borderRadius:
                                              BorderRadius.circular(3),
                                          onTap: widget.message.onActionPressed,
                                          child: Padding(
                                            padding: const EdgeInsets.all(2.0),
                                            child: Text(
                                              widget.message.actionLabel ??
                                                  'Action',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .overline
                                                  ?.apply(
                                                      fontSizeDelta: 2,
                                                      fontWeightDelta: 4,
                                                      color: widget.message
                                                                  .onActionPressed ==
                                                              null
                                                          ? Theme.of(context)
                                                              .disabledColor
                                                          : widget.message
                                                              .status.color),
                                            ),
                                          ),
                                        ),
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
        ));
  }

  Future<void> dissmiss(BuildContext context) async {
    setState(() => fadinFadeout = Tween<double>(begin: 0, end: 0));
    await Future.delayed(const Duration(milliseconds: 400));
    Provider.of<PulpFlash>(context, listen: false)
        ._removeMessage(widget.message);
  }

  @override
  void dispose() {
    super.dispose();
    timeOutAction?.ignore();
  }
}
