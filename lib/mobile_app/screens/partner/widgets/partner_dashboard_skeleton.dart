import 'package:flutter/material.dart';
import 'package:piggytrunk/widgets/common/shimmer_loading.dart';

/// Tab-aware shimmering skeleton loader for the Partner/Investor Mobile App.
class PartnerDashboardSkeleton extends StatelessWidget {
  final int currentIndex;

  const PartnerDashboardSkeleton({
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
        padding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 24.0),
        child: _buildTabSkeleton(context, isDark),
      ),
    );
  }

  Widget _buildTabSkeleton(BuildContext context, bool isDark) {
    switch (currentIndex) {
      case 1:
        return _buildProjectsSkeleton(context, isDark);
      case 2:
        return _buildActivitiesSkeleton(context, isDark);
      case 3:
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
        // Header Row: Partner Name + Notification Bell
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerBox(
                  width: 130,
                  height: 12,
                  borderRadius: BorderRadius.circular(4),
                  isDark: isDark,
                ),
                const SizedBox(height: 6),
                ShimmerBox(
                  width: 170,
                  height: 18,
                  borderRadius: BorderRadius.circular(6),
                  isDark: isDark,
                ),
              ],
            ),
            ShimmerBox(
              width: 42,
              height: 42,
              shape: BoxShape.circle,
              isDark: isDark,
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Portfolio Hero Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShimmerBox(
                width: 160,
                height: 12,
                borderRadius: BorderRadius.circular(4),
                isDark: isDark,
              ),
              const SizedBox(height: 12),
              ShimmerBox(
                width: 220,
                height: 32,
                borderRadius: BorderRadius.circular(8),
                isDark: isDark,
              ),
              const SizedBox(height: 16),
              Divider(color: cardBorder, height: 1),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ShimmerBox(width: 90, height: 12, borderRadius: BorderRadius.circular(4), isDark: isDark),
                  ShimmerBox(width: 60, height: 14, borderRadius: BorderRadius.circular(4), isDark: isDark),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Section Title: Active Projects / Batches
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ShimmerBox(width: 130, height: 16, borderRadius: BorderRadius.circular(4), isDark: isDark),
            ShimmerBox(width: 60, height: 12, borderRadius: BorderRadius.circular(4), isDark: isDark),
          ],
        ),
        const SizedBox(height: 14),

        // Project Cards
        ...List.generate(
          2,
          (index) => Container(
            margin: const EdgeInsets.only(bottom: 14),
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
                    ShimmerBox(width: 140, height: 16, borderRadius: BorderRadius.circular(4), isDark: isDark),
                    ShimmerBox(width: 70, height: 22, borderRadius: BorderRadius.circular(12), isDark: isDark),
                  ],
                ),
                const SizedBox(height: 12),
                ShimmerBox(width: double.infinity, height: 8, borderRadius: BorderRadius.circular(4), isDark: isDark),
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

  // ==================== 2. PROJECTS TAB SKELETON ====================
  Widget _buildProjectsSkeleton(BuildContext context, bool isDark) {
    final cardBg = isDark ? const Color(0xFF1B2A3F) : Colors.white;
    final cardBorder = isDark ? const Color(0xFF28354A) : const Color(0xFFE2E8F0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ShimmerBox(width: 150, height: 22, borderRadius: BorderRadius.circular(6), isDark: isDark),
        const SizedBox(height: 8),
        ShimmerBox(width: 220, height: 12, borderRadius: BorderRadius.circular(4), isDark: isDark),
        const SizedBox(height: 20),
        ...List.generate(
          3,
          (index) => Container(
            margin: const EdgeInsets.only(bottom: 14),
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
                    ShimmerBox(width: 160, height: 18, borderRadius: BorderRadius.circular(4), isDark: isDark),
                    ShimmerBox(width: 80, height: 24, borderRadius: BorderRadius.circular(12), isDark: isDark),
                  ],
                ),
                const SizedBox(height: 14),
                ShimmerBox(width: double.infinity, height: 10, borderRadius: BorderRadius.circular(5), isDark: isDark),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ShimmerBox(width: 110, height: 12, borderRadius: BorderRadius.circular(4), isDark: isDark),
                    ShimmerBox(width: 90, height: 12, borderRadius: BorderRadius.circular(4), isDark: isDark),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ==================== 3. ACTIVITIES TAB SKELETON ====================
  Widget _buildActivitiesSkeleton(BuildContext context, bool isDark) {
    final cardBg = isDark ? const Color(0xFF1B2A3F) : Colors.white;
    final cardBorder = isDark ? const Color(0xFF28354A) : const Color(0xFFE2E8F0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ShimmerBox(width: 160, height: 22, borderRadius: BorderRadius.circular(6), isDark: isDark),
        const SizedBox(height: 8),
        ShimmerBox(width: 240, height: 12, borderRadius: BorderRadius.circular(4), isDark: isDark),
        const SizedBox(height: 20),
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
                ShimmerBox(width: 40, height: 40, shape: BoxShape.circle, isDark: isDark),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShimmerBox(width: 140, height: 14, borderRadius: BorderRadius.circular(4), isDark: isDark),
                      const SizedBox(height: 6),
                      ShimmerBox(width: 180, height: 11, borderRadius: BorderRadius.circular(4), isDark: isDark),
                    ],
                  ),
                ),
                ShimmerBox(width: 45, height: 10, borderRadius: BorderRadius.circular(4), isDark: isDark),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ==================== 4. PROFILE TAB SKELETON ====================
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
        ShimmerBox(width: 150, height: 18, borderRadius: BorderRadius.circular(4), isDark: isDark),
        const SizedBox(height: 6),
        ShimmerBox(width: 100, height: 12, borderRadius: BorderRadius.circular(4), isDark: isDark),
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
