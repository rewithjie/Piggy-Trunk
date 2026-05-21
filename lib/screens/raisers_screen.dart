import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/admin_sidebar.dart';
import '../widgets/screen_top_bar.dart';

class RaisersScreen extends StatelessWidget {
  const RaisersScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Theme-aware color getters
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    Color bgDark = isDark ? PiggyTrunkTheme.ptBgDark : PiggyTrunkTheme.ptBg;
    
    return Scaffold(
      backgroundColor: bgDark,
      body: Row(

        children: [
          AdminSidebar(
            currentRoute: '/raisers',
            onLogout: () => Navigator.of(context).pushReplacementNamed('/login'),
          ),
          Expanded(
            child: Column(
              children: [
                /// REUSABLE TOP BAR
                ScreenTopBar(),
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(32),
                          child: Text(
                            'Hog Raiser',
                            style: Theme.of(context).textTheme.displayMedium?.copyWith(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.04,
                                ),
                          ),
                        ),
                        Text(
                          'Hog Raisers Management Coming Soon',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
