import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.child,
    this.showBack = true,
    this.resizeToAvoidBottomInset = true,
  });

  final Widget child;
  final bool showBack;
  final bool resizeToAvoidBottomInset;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      backgroundColor: AppColors.skyBg,
      body: SafeArea(
        child: Column(
          children: [
            if (showBack)
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(left: 8, top: 4),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    color: AppColors.text,
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                ),
              ),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}
