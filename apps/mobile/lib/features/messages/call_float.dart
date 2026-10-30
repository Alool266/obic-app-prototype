// Made by Dr Ali
// Keeps a group or 1:1 call above the app so it can shrink to a small window.

import 'dart:async';

import 'package:flutter/material.dart';

import '../../theme/obic_colors.dart';
import 'call_screen.dart';

class CallFloatController extends ChangeNotifier {
  CallFloatController._();
  static final CallFloatController instance = CallFloatController._();

  Widget? _call;
  bool _mini = false;
  String _title = 'OBIC';
  int _seconds = 0;
  CompleterBox? _box;

  bool get visible => _call != null;
  bool get mini => _mini;
  String get title => _title;
  int get seconds => _seconds;

  void show(
    Widget call, {
    required String title,
    required CompleterBox box,
  }) {
    _call = call;
    _box = box;
    _title = title;
    _seconds = 0;
    _mini = false;
    notifyListeners();
  }

  void note({required int seconds}) {
    if (_seconds == seconds) return;
    _seconds = seconds;
    if (_mini) notifyListeners();
  }

  void minimize() {
    if (_call == null || _mini) return;
    _mini = true;
    notifyListeners();
  }

  void expand() {
    if (_call == null || !_mini) return;
    _mini = false;
    notifyListeners();
  }

  void close(ObicCallFinish finish) {
    final box = _box;
    _call = null;
    _box = null;
    _mini = false;
    notifyListeners();
    box?.complete(finish);
  }

  String get clock {
    final m = (_seconds ~/ 60).toString().padLeft(2, '0');
    final s = (_seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

class CompleterBox {
  ObicCallFinish? value;
  bool _done = false;
  void complete(ObicCallFinish finish) {
    if (_done) return;
    _done = true;
    value = finish;
    _wait?.complete(finish);
  }

  Future<ObicCallFinish?> get future {
    if (_done) return Future.value(value);
    _wait ??= Completer<ObicCallFinish?>();
    return _wait!.future;
  }

  Completer<ObicCallFinish?>? _wait;
}

class CallFloatLayer extends StatelessWidget {
  const CallFloatLayer({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: CallFloatController.instance,
      builder: (context, _) {
        final host = CallFloatController.instance;
        final call = host.visible ? host._call : null;
        return Stack(
          fit: StackFit.expand,
          children: [
            child,
            if (call != null)
              Offstage(offstage: host.mini, child: call),
            if (call != null && host.mini)
              PositionedDirectional(
                end: 12,
                bottom: 96,
                child: Material(
                  color: ObicColors.navy,
                  elevation: 8,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    onTap: host.expand,
                    borderRadius: BorderRadius.circular(16),
                    child: SizedBox(
                      width: 132,
                      height: 88,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              host.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              host.clock,
                              style: const TextStyle(
                                color: ObicColors.blue,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
