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
                          IconButton(
                            icon: const Icon(Icons.menu_rounded, size: 28),
                            onPressed: () =>
                                _scaffoldKey.currentState?.openDrawer(),
                            tooltip: 'Menu',
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

    return IconButton(
      icon: const Icon(Icons.refresh_rounded, size: 26, color: kColorAccent),
      onPressed: model.isIdle ? () => _refreshQuestion(context, model) : null,
      tooltip: 'New question for current topic',
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
