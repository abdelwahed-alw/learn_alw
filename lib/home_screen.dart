// lib/home_screen.dart
// Thin shell: assembles the Scaffold with DrawerWidget + MainScreenBody.

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app_state_model.dart';
import 'constants.dart';
import 'drawer_widget.dart';
import 'main_screen_body.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final model = context.watch<AppStateModel>();

    return Scaffold(
      key:
          _scaffoldKey, // We need a GlobalKey<ScaffoldState> to open the drawer
      backgroundColor: kColorBackground,
      drawer: const DrawerWidget(),
      body: Stack(
        children: [
          // The body contains the background gradient and the scrollable content
          const MainScreenBody(),

          // Custom Floating AppBar (Glassmorphism)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  color: kColorBackground.withValues(alpha: 0.6),
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                         _AnimatedIconButton(
  icon: Icons.menu_rounded,
  onTap: () => _scaffoldKey.currentState?.openDrawer(),
),
                          Text(
                            'Salearn',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                          ),
                          _buildRefreshButton(model, context),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRefreshButton(AppStateModel model, BuildContext context) {
    if (!model.hasApiKey)
      return const SizedBox(width: 48); // placeholder for spacing

    if (model.isGeneratingQuestion) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2, color: kColorAccent),
        ),
      );
    }

   return _AnimatedIconButton(
  icon: Icons.refresh_rounded,
  color: kColorAccent,
  onTap: model.isIdle ? () => _refreshQuestion(context, model) : null,
);
  }

  Future<void> _refreshQuestion(
      BuildContext context, AppStateModel model) async {
    final error = await model.generateQuestion();
    if (error != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: kColorError,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
class _AnimatedIconButton extends StatefulWidget {
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _AnimatedIconButton({
    required this.icon,
    this.color = kColorText,
    this.onTap,
  });

  @override
  State<_AnimatedIconButton> createState() => _AnimatedIconButtonState();
}

class _AnimatedIconButtonState extends State<_AnimatedIconButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
      lowerBound: 0.0,
      upperBound: 0.15,
    );
    _scale = Tween<double>(begin: 1.0, end: 0.82).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onTapDown(_) => _ctrl.forward();
  void _onTapUp(_) async {
    await _ctrl.reverse();
    widget.onTap?.call();
  }
  void _onTapCancel() => _ctrl.reverse();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: kColorSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: kColorBorder),
          ),
          child: Icon(widget.icon, size: 22, color: widget.color),
        ),
      ),
    );
  }
}