import 'package:flutter_riverpod/flutter_riverpod.dart';

class ShellTabController extends Notifier<int> {
  @override
  int build() => 0;

  void select(int index) {
    if (index < 0 || index > 3) return;
    state = index;
  }
}

final shellTabProvider = NotifierProvider<ShellTabController, int>(
  ShellTabController.new,
);
