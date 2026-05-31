import 'package:flutter/widgets.dart';

/// Minimal dependency-free state propagation.
///
/// This is the hand-rolled stand-in for the `provider` package: an
/// [InheritedWidget] exposes a [Listenable] down the tree, and screens rebuild
/// with the framework's own [ListenableBuilder]. No external package required.
class GameScope<T extends Listenable> extends InheritedWidget {
  const GameScope({super.key, required this.model, required super.child});

  final T model;

  static T read<T extends Listenable>(BuildContext context) {
    final scope =
        context.getInheritedWidgetOfExactType<GameScope<T>>();
    assert(scope != null, 'No GameScope<$T> available in this context.');
    return scope!.model;
  }

  static T watch<T extends Listenable>(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<GameScope<T>>();
    assert(scope != null, 'No GameScope<$T> available in this context.');
    return scope!.model;
  }

  @override
  bool updateShouldNotify(GameScope<T> oldWidget) =>
      oldWidget.model != model;
}

extension GameScopeX on BuildContext {
  T read<T extends Listenable>() => GameScope.read<T>(this);
  T watch<T extends Listenable>() => GameScope.watch<T>(this);
}
