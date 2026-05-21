import 'package:flutter/material.dart';
import 'piggyremovedbg.dart';
import '../theme/app_theme.dart';

/// Reusable App Header with Logo
class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showLogo;
  final VoidCallback? onLogoTap;

  const AppHeader({
    Key? key,
    required this.title,
    this.actions,
    this.showLogo = true,
    this.onLogoTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Theme-aware colors
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceDark = isDark ? PiggyTrunkTheme.ptSurfaceDark : PiggyTrunkTheme.ptSurface;
    final textDark = isDark ? PiggyTrunkTheme.ptTextDark : PiggyTrunkTheme.ptText;
    final primaryDark = isDark ? PiggyTrunkTheme.ptPrimaryDark : PiggyTrunkTheme.ptPrimary;
    
    return AppBar(
      title: showLogo
          ? Row(
              children: [
                GestureDetector(
                  onTap: onLogoTap,
                  child: PiggyTrunkLogo(size: LogoSize.small),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            )
          : Text(title),
      elevation: 0,
      backgroundColor: surfaceDark,
      foregroundColor: textDark,
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

/// App Drawer with Logo
class AppDrawer extends StatelessWidget {
  final List<DrawerItem> items;
  final VoidCallback? onLogout;

  const AppDrawer({
    Key? key,
    required this.items,
    this.onLogout,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceDark = isDark ? PiggyTrunkTheme.ptSurfaceDark : PiggyTrunkTheme.ptSurface;
    final textDark = isDark ? PiggyTrunkTheme.ptTextDark : PiggyTrunkTheme.ptText;
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: surfaceDark,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                PiggyTrunkLogo(size: LogoSize.medium),
                const SizedBox(height: 12),
                Text(
                  'PiggyTrunk Admin',
                  style: TextStyle(
                    color: textDark,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          ...items.map((item) {
            return ListTile(
              leading: Icon(item.icon),
              title: Text(item.label),
              onTap: item.onTap,
            );
          }).toList(),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: onLogout,
          ),
        ],
      ),
    );
  }
}

class DrawerItem {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  DrawerItem({
    required this.label,
    required this.icon,
    required this.onTap,
  });
}

/// Floating Action Button with Logo Background
class LogoFAB extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;

  const LogoFAB({
    Key? key,
    required this.onPressed,
    required this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceDark = isDark ? PiggyTrunkTheme.ptSurfaceDark : PiggyTrunkTheme.ptSurface;
    return FloatingActionButton(
      onPressed: onPressed,
      backgroundColor: surfaceDark,
      child: Icon(icon),
    );
  }
}

/// Logo Hero Transition Widget
class LogoHero extends StatelessWidget {
  final double size;
  final bool withBorder;
  final String tag;
  final VoidCallback? onTap;

  const LogoHero({
    Key? key,
    this.size = 120,
    this.withBorder = false,
    this.tag = 'logo_hero',
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Hero(
        tag: tag,
        child: PiggyTrunkLogo(
          size: size,
          withBorder: withBorder,
        ),
      ),
    );
  }
}
