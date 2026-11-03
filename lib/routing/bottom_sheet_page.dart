import 'package:flutter/material.dart';

/// A router page shown as a Material modal bottom sheet, so a route such
/// as the volume picker slides up over the screen and Back closes it.
class BottomSheetPage<T> extends Page<T> {
  const BottomSheetPage({required this.child, super.key});

  final Widget child;

  @override
  Route<T> createRoute(BuildContext context) {
    return ModalBottomSheetRoute<T>(
      settings: this,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => child,
    );
  }
}
