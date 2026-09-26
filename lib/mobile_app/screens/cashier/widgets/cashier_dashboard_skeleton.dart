import 'package:flutter/material.dart';
import 'package:piggytrunk/widgets/common/shimmer_loading.dart';

/// Tab-aware shimmering skeleton loader for the Cashier Mobile App.
class CashierDashboardSkeleton extends StatelessWidget {
  final int currentIndex;

  const CashierDashboardSkeleton({
    super.key,
    this.currentIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ShimmerProvider(
      duration: const Duration(milliseconds: 1400),
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20.0, 16.0, 20.0, 24.0),
        child: _buildTabSkeleton(context, isDark),
      ),
    );
  }

  Widget _buildTabSkeleton(BuildContext context, bool isDark) {
    switch (currentIndex) {
      case 1:
        return _buildRequestsSkeleton(context, isDark);
      case 2:
        return _buildInventorySkeleton(context, isDark);
      case 3:
        return _buildPOSkeleton(context, isDark);
      case 4:
        return _buildProfileSkeleton(context, isDark);
      case 0:
      default:
        return _buildHomeSkeleton(context, isDark);
    }
  }

  // ==================== 1. HOME TAB SKELETON ====================
  Widget _buildHomeSkeleton(BuildContext context, bool isDark) {
    final cardBg = isDark ? const Color(0xFF1B2A3F) : Colors.white;
    final cardBorder = isDark ? const Color(0xFF28354A) : const Color(0xFFE2E8F0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top Header Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerBox(width: 100, height: 12, borderRadius: BorderRadius.circular(4), isDark: isDark),
                const SizedBox(height: 6),
                ShimmerBox(width: 150, height: 18, borderRadius: BorderRadius.circular(6), isDark: isDark),
              ],
            ),
            ShimmerBox(width: 42, height: 42, shape: BoxShape.circle, isDark: isDark),
          ],
        ),
        const SizedBox(height: 20),

        // 3 Metrics Row
        Row(
          children: List.generate(
            3,
            (index) => Expanded(
              child: Container(
                margin: EdgeInsets.only(right: index < 2 ? 10 : 0),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: cardBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerBox(width: 24, height: 24, borderRadius: BorderRadius.circular(6), isDark: isDark),
                    const SizedBox(height: 10),
                    ShimmerBox(width: 36, height: 18, borderRadius: BorderRadius.circular(4), isDark: isDark),
                    const SizedBox(height: 4),
                    ShimmerBox(width: 60, height: 10, borderRadius: BorderRadius.circular(3), isDark: isDark),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Quick Actions Grid
        Row(
          children: List.generate(
            2,
            (index) => Expanded(
              child: Container(
                margin: EdgeInsets.only(right: index == 0 ? 10 : 0),
                height: 52,
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: cardBorder),
                ),
                child: Center(
                  child: ShimmerBox(width: 90, height: 14, borderRadius: BorderRadius.circular(4), isDark: isDark),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),

        // List Header
        ShimmerBox(width: 140, height: 16, borderRadius: BorderRadius.circular(4), isDark: isDark),
        const SizedBox(height: 14),

        // Product Cards
        ...List.generate(
          3,
          (index) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: cardBorder),
            ),
            child: Row(
              children: [
                ShimmerBox(width: 44, height: 44, borderRadius: BorderRadius.circular(10), isDark: isDark),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShimmerBox(width: 130, height: 14, borderRadius: BorderRadius.circular(4), isDark: isDark),
                      const SizedBox(height: 6),
                      ShimmerBox(width: 80, height: 11, borderRadius: BorderRadius.circular(4), isDark: isDark),
                    ],
                  ),
                ),
                ShimmerBox(width: 60, height: 16, borderRadius: BorderRadius.circular(4), isDark: isDark),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ==================== 2. REQUESTS TAB SKELETON ====================
  Widget _buildRequestsSkeleton(BuildContext context, bool isDark) {
    final cardBg = isDark ? const Color(0xFF1B2A3F) : Colors.white;
    final cardBorder = isDark ? const Color(0xFF28354A) : const Color(0xFFE2E8F0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ShimmerBox(width: 160, height: 22, borderRadius: BorderRadius.circular(6), isDark: isDark),
        const SizedBox(height: 8),
        ShimmerBox(width: 220, height: 12, borderRadius: BorderRadius.circular(4), isDark: isDark),
        const SizedBox(height: 20),
        ...List.generate(
          4,
          (index) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ShimmerBox(width: 130, height: 16, borderRadius: BorderRadius.circular(4), isDark: isDark),
                    ShimmerBox(width: 75, height: 22, borderRadius: BorderRadius.circular(11), isDark: isDark),
                  ],
                ),
                const SizedBox(height: 10),
                ShimmerBox(width: 180, height: 12, borderRadius: BorderRadius.circular(4), isDark: isDark),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ShimmerBox(width: 100, height: 12, borderRadius: BorderRadius.circular(4), isDark: isDark),
                    ShimmerBox(width: 80, height: 12, borderRadius: BorderRadius.circular(4), isDark: isDark),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ==================== 3. INVENTORY TAB SKELETON ====================
  Widget _buildInventorySkeleton(BuildContext context, bool isDark) {
    final cardBg = isDark ? const Color(0xFF1B2A3F) : Colors.white;
    final cardBorder = isDark ? const Color(0xFF28354A) : const Color(0xFFE2E8F0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ShimmerBox(width: 140, height: 22, borderRadius: BorderRadius.circular(6), isDark: isDark),
        const SizedBox(height: 16),
        ShimmerBox(width: double.infinity, height: 46, borderRadius: BorderRadius.circular(12), isDark: isDark),
        const SizedBox(height: 18),
        ...List.generate(
          4,
          (index) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: cardBorder),
            ),
            child: Row(
              children: [
                ShimmerBox(width: 48, height: 48, borderRadius: BorderRadius.circular(10), isDark: isDark),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShimmerBox(width: 140, height: 14, borderRadius: BorderRadius.circular(4), isDark: isDark),
                      const SizedBox(height: 6),
                      ShimmerBox(width: 80, height: 11, borderRadius: BorderRadius.circular(4), isDark: isDark),
                    ],
                  ),
                ),
                ShimmerBox(width: 50, height: 20, borderRadius: BorderRadius.circular(6), isDark: isDark),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ==================== 4. POS TAB SKELETON ====================
  Widget _buildPOSkeleton(BuildContext context, bool isDark) {
    final cardBg = isDark ? const Color(0xFF1B2A3F) : Colors.white;
    final cardBorder = isDark ? const Color(0xFF28354A) : const Color(0xFFE2E8F0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ShimmerBox(width: 120, height: 22, borderRadius: BorderRadius.circular(6), isDark: isDark),
        const SizedBox(height: 16),
        ShimmerBox(width: double.infinity, height: 46, borderRadius: BorderRadius.circular(12), isDark: isDark),
        const SizedBox(height: 18),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 4,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.85,
          ),
          itemBuilder: (ctx, idx) => Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: ShimmerBox(
                    width: double.infinity,
                    height: double.infinity,
                    borderRadius: BorderRadius.circular(10),
                    isDark: isDark,
                  ),
                ),
                const SizedBox(height: 10),
                ShimmerBox(width: 80, height: 12, borderRadius: BorderRadius.circular(4), isDark: isDark),
                const SizedBox(height: 6),
                ShimmerBox(width: 50, height: 14, borderRadius: BorderRadius.circular(4), isDark: isDark),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ==================== 5. PROFILE TAB SKELETON ====================
  Widget _buildProfileSkeleton(BuildContext context, bool isDark) {
    final cardBg = isDark ? const Color(0xFF1B2A3F) : Colors.white;
    final cardBorder = isDark ? const Color(0xFF28354A) : const Color(0xFFE2E8F0);

    return Column(
      children: [
        const SizedBox(height: 10),
        Center(
          child: ShimmerBox(width: 90, height: 90, shape: BoxShape.circle, isDark: isDark),
        ),
        const SizedBox(height: 14),
        ShimmerBox(width: 140, height: 18, borderRadius: BorderRadius.circular(4), isDark: isDark),
        const SizedBox(height: 6),
        ShimmerBox(width: 90, height: 12, borderRadius: BorderRadius.circular(4), isDark: isDark),
        const SizedBox(height: 24),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: cardBorder),
          ),
          child: Column(
            children: List.generate(
              4,
              (index) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ShimmerBox(width: 90, height: 12, borderRadius: BorderRadius.circular(4), isDark: isDark),
                    ShimmerBox(width: 130, height: 12, borderRadius: BorderRadius.circular(4), isDark: isDark),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
