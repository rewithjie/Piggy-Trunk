import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../main.dart';
import '../theme/app_theme.dart';
import '../theme/app_text_styles.dart';
import '../screens/dashboard_screen.dart';
import '../screens/hog_raiser_screen.dart';
import '../screens/investments_screen.dart';
import '../screens/inventory_screen.dart';
import '../screens/pos_screen.dart';
import '../screens/settings_screen.dart';

final sidebarExpandedProvider = StateProvider<bool>((ref) => false);

class AdminSidebar extends ConsumerStatefulWidget {
  final String currentRoute;
  final VoidCallback onLogout;

  const AdminSidebar({
    Key? key,
    required this.currentRoute,
    required this.onLogout,
  }) : super(key: key);

  @override
  ConsumerState<AdminSidebar> createState() => _AdminSidebarState();
}

class _AdminSidebarState extends ConsumerState<AdminSidebar> {
  late List<SidebarItem> mainItems;
  late List<SidebarItem> footerItems;
  String? _hoveredRoute;

  @override
  void initState() {
    super.initState();
    mainItems = [
      SidebarItem(
        label: 'Dashboard',
        iconAsset: 'assets/icons/sidebar/dashboard.svg',
        fallbackIcon: Icons.apps_outlined,
        route: '/dashboard',
      ),
      SidebarItem(
        label: 'Hog Raiser',
        iconAsset: 'assets/icons/sidebar/raisers.svg',
        fallbackIcon: Icons.group_outlined,
        route: '/raisers',
      ),
      SidebarItem(
        label: 'Investment',
        iconAsset: 'assets/icons/sidebar/investment.svg',
        fallbackIcon: Icons.trending_up_outlined,
        route: '/investments',
      ),
      SidebarItem(
        label: 'Inventory',
        iconAsset: 'assets/icons/sidebar/inventory.svg',
        fallbackIcon: Icons.inventory_2_outlined,
        route: '/inventory',
      ),
      SidebarItem(
        label: 'POS',
        iconAsset: 'assets/icons/sidebar/pos.svg',
        fallbackIcon: Icons.point_of_sale_outlined,
        route: '/pos',
      ),
    ];

    footerItems = [
      SidebarItem(
        label: 'Theme',
        iconAsset: 'assets/icons/sidebar/theme.svg',
        fallbackIcon: Icons.dark_mode_outlined,
        route: '/theme',
      ),
      SidebarItem(
        label: 'Settings',
        iconAsset: 'assets/icons/sidebar/settings.svg',
        fallbackIcon: Icons.settings_outlined,
        route: '/settings',
      ),
      SidebarItem(
        label: 'Sign out',
        iconAsset: 'assets/icons/sidebar/logout.svg',
        fallbackIcon: Icons.logout_outlined,
        route: '/logout',
      ),
    ];
  }

  void _navigate(String route) {
    if (route == '/theme') {
      final current = ref.read(themeModeProvider);
      final next = current == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
      ref.read(themeModeProvider.notifier).state = next;
      return;
    }

    if (route == '/logout') {
      widget.onLogout();
    } else {
      final screen = _screenForRoute(route);
      final messenger = ScaffoldMessenger.maybeOf(context);
      messenger?.hideCurrentSnackBar();
      messenger?.removeCurrentSnackBar();

      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => screen,
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? const Color(0xff151f2e) : PiggyTrunkTheme.ptSurface;
    final borderColor = isDark ? const Color(0xff28354a) : PiggyTrunkTheme.ptBorder;
    final textColor = isDark ? const Color(0xffecf2ff) : PiggyTrunkTheme.ptText;
    final isExpanded = ref.watch(sidebarExpandedProvider);
    final targetWidth = isExpanded ? 300.0 : 112.0;
    return Container(
      width: targetWidth,
      decoration: BoxDecoration(
        color: surfaceColor,
        border: Border(
          right: BorderSide(
            color: borderColor,
            width: 1,
          ),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final showExpandedContent = constraints.maxWidth >= 240;

          Widget buildMainItems() {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              child: Column(
                children: mainItems
                    .map((item) => _buildNavItem(
                          item,
                          widget.currentRoute == item.route,
                          showExpandedContent,
                        ))
                    .toList(),
              ),
            );
          }

          Widget buildFooterItems() {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              child: Column(
                children: footerItems
                    .map((item) => _buildNavItem(
                          item,
                          false,
                          showExpandedContent,
                        ))
                    .toList(),
              ),
            );
          }

          return Column(
            children: [
          /// Sidebar Header with Hamburger Toggle
          Container(
            constraints: const BoxConstraints(minHeight: 82),
            padding: EdgeInsets.symmetric(
              horizontal: showExpandedContent ? 12 : 4,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: surfaceColor,
              border: Border(
                bottom: BorderSide(
                  color: borderColor,
                  width: 1,
                ),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: showExpandedContent
                      ? MainAxisAlignment.start
                      : MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: SizedBox(
                        width: 58,
                        height: 58,
                        child: Image.asset(
                          'assets/piggytrunkremovebg.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    SizedBox(width: showExpandedContent ? 12 : 6),
                    if (showExpandedContent)
                      Flexible(
                        child: Text(
                          'PiggyTrunk',
                          style: AppTextStyles.sidebarBrand(textColor),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    const SizedBox(width: 8),
                    _buildSidebarToggle(isExpanded),
                  ],
                ),
              ],
            ),
          ),

            Expanded(
              child: Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.zero,
                      children: [
                        buildMainItems(),
                      ],
                    ),
                  ),
                  Divider(
                    color: borderColor,
                    thickness: 1,
                    height: 1,
                  ),
                  buildFooterItems(),
                ],
              ),
            ),
            ],
          );
        },
      ),
    );
  }

  Widget _screenForRoute(String route) {
    switch (route) {
      case '/dashboard':
        return const DashboardScreen();
      case '/raisers':
        return const HogRaiserScreen();
      case '/investments':
        return const InvestmentsScreen();
      case '/inventory':
        return const InventoryScreen();
      case '/pos':
        return const POSScreen();
      case '/settings':
        return const SettingsScreen();
      default:
        return const DashboardScreen();
    }
  }

  /// Build individual navigation item with hover effects
  Widget _buildNavItem(
    SidebarItem item,
    bool isActive,
    bool isExpanded,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? const Color(0xff28354a) : PiggyTrunkTheme.ptBorder;
    final textColor = isDark ? const Color(0xffecf2ff) : PiggyTrunkTheme.ptText;
    final mutedColor = isDark ? const Color(0xff9cb0c9) : PiggyTrunkTheme.ptMuted;
    return MouseRegion(
      onEnter: (_) {
        setState(() {
          _hoveredRoute = item.route;
        });
      },
      onExit: (_) {
        setState(() {
          _hoveredRoute = null;
        });
      },
      cursor: SystemMouseCursors.click,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: isActive
              ? borderColor.withOpacity(0.5)
              : _hoveredRoute == item.route
                  ? borderColor.withOpacity(0.3)
                  : Colors.transparent,
          border: Border.all(
            color: isActive
                ? borderColor
                : _hoveredRoute == item.route
                    ? borderColor.withOpacity(0.5)
                    : Colors.transparent,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: GestureDetector(
          onTap: () => _navigate(item.route),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment:
                isExpanded ? MainAxisAlignment.start : MainAxisAlignment.center,
            children: [
              /// Icon
              Tooltip(
                message: item.label,
                child: SvgPicture.asset(
                  item.iconAsset,
                  width: 20,
                  height: 20,
                  colorFilter: ColorFilter.mode(
                    isActive ? textColor : mutedColor,
                    BlendMode.srcIn,
                  ),
                  placeholderBuilder: (context) => Icon(
                    item.fallbackIcon,
                    size: 20,
                    color: isActive ? textColor : mutedColor,
                  ),
                ),
              ),
              if (isExpanded) ...[
                const SizedBox(width: 16),

                /// Label
                Expanded(
                  child: Text(
                    item.label,
                    style: AppTextStyles.sidebarLabel(
                      isActive ? textColor : mutedColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSidebarToggle(bool isExpanded) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? const Color(0xffecf2ff) : PiggyTrunkTheme.ptText;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          ref.read(sidebarExpandedProvider.notifier).state = !isExpanded;
        },
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            color: Colors.transparent,
          ),
          child: Icon(
            isExpanded ? Icons.menu_open_outlined : Icons.menu_outlined,
            color: textColor,
            size: 18,
          ),
        ),
      ),
    );
  }
}

class SidebarItem {
  final String label;
  final String iconAsset;
  final IconData fallbackIcon;
  final String route;

  SidebarItem({
    required this.label,
    required this.iconAsset,
    required this.fallbackIcon,
    required this.route,
  });
}
