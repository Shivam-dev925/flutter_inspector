import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dev_panel/src/core/dev_panel_controller.dart';

/// The main overlay UI for the DevPanel
class DevPanelOverlay extends StatefulWidget {
  const DevPanelOverlay({super.key});

  @override
  State<DevPanelOverlay> createState() => _DevPanelOverlayState();
}

class _DevPanelOverlayState extends State<DevPanelOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      reverseDuration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutQuart,
      reverseCurve: Curves.easeInQuad,
    ));

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DevPanelController>(
      builder: (context, controller, child) {
        if (controller.isVisible) {
          _animationController.forward();
        } else {
          _animationController.reverse();
        }

        if (!controller.isVisible && !_animationController.isAnimating) {
          return const SizedBox.shrink();
        }

        return Directionality(
          textDirection: TextDirection.ltr,
          child: MediaQuery(
            data: MediaQueryData.fromView(View.of(context)),
            child: Localizations(
              locale: const Locale('en', 'US'),
              delegates: const [
                DefaultMaterialLocalizations.delegate,
                DefaultWidgetsLocalizations.delegate,
              ],
              child: Scaffold(
                backgroundColor: Colors.transparent,
                body: Material(
                  type: MaterialType.transparency,
                  child: Stack(
                    children: [
                      // Backdrop
                      GestureDetector(
                        onTap: () => controller.hide(),
                        child: FadeTransition(
                          opacity: _fadeAnimation,
                          child: Container(
                            color: Colors.black.withOpacity(0.6),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                              child: Container(color: Colors.transparent),
                            ),
                          ),
                        ),
                      ),
                      // Panel
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: SlideTransition(
                          position: _slideAnimation,
                          child: Container(
                            height: MediaQuery.of(context).size.height * 0.75,
                            margin: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E293B),
                              borderRadius: BorderRadius.circular(32),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 30,
                                  offset: Offset(0, -10),
                                ),
                              ],
                              border: Border.all(
                                color: Colors.white.withOpacity(0.1),
                                width: 1,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(32),
                              child: HeroControllerScope.none(
                                child: Navigator(
                                  onGenerateRoute: (settings) {
                                    return MaterialPageRoute(
                                      builder: (context) => Column(
                                      children: [
                                        _buildHeader(context, controller),
                                        if (controller.plugins.isNotEmpty)
                                          _buildTabBar(controller),
                                        Expanded(
                                          child: Container(
                                            color: const Color(0xFF0F172A),
                                            child: _buildContent(controller),
                                          ),
                                        ),
                                      ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, DevPanelController controller) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
      color: const Color(0xFF1E293B),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.developer_mode,
              color: Color(0xFF6366F1),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'DevPanel',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                'Developer Tools',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white54,
                ),
              ),
            ],
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close_rounded, color: Colors.white70),
            onPressed: () => controller.hide(),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.05),
              hoverColor: Colors.white.withOpacity(0.1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(DevPanelController controller) {
    return Container(
      height: 72,
      color: const Color(0xFF1E293B),
      padding: const EdgeInsets.only(bottom: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: controller.plugins.length,
        itemBuilder: (context, index) {
          final plugin = controller.plugins[index];
          final isSelected = controller.currentTabIndex == index;

          return GestureDetector(
            onTap: () => controller.setTab(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF6366F1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF6366F1)
                      : Colors.white.withOpacity(0.1),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    plugin.icon,
                    size: 20,
                    color: isSelected ? Colors.white : Colors.white60,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    plugin.name,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? Colors.white : Colors.white60,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildContent(DevPanelController controller) {
    if (controller.plugins.isEmpty) {
      return const Center(
        child: Text(
          'No plugins configured',
          style: TextStyle(color: Colors.white54),
        ),
      );
    }

    final currentPlugin = controller.plugins[controller.currentTabIndex];
    return Theme(
      data: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF6366F1),
          surface: Color(0xFF1E293B),
        ),
      ),
      child: currentPlugin.build(context),
    );
  }
}
