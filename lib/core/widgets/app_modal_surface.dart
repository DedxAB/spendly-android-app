import 'package:flutter/material.dart';
import 'package:spendly/core/theme/app_design_tokens.dart';

class AppModalSurface extends StatelessWidget {
  const AppModalSurface({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadii.lg)),
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: child,
    );
  }
}
