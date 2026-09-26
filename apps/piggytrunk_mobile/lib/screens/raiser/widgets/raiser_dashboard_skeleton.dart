import 'package:flutter/material.dart';
import 'package:piggytrunk/widgets/common/shimmer_loading.dart';

/// Comprehensive, tab-aware shimmering skeleton loader for the Hog Raiser Mobile App.
/// Provides synchronized, premium loading placeholders that perfectly match
/// Home, Requests, Hogs, and Profile layouts with zero layout shift.
class RaiserDashboardSkeleton extends StatelessWidget {
  final int currentIndex;

  const RaiserDashboardSkeleton({
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
        return _buildRequestsSkeleton(context, isDark);
      case 2:
        return _buildHogsSkeleton(context, isDark);
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
        // Header Bar: Avatar + Name + Notification Bell
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                ShimmerBox(
                  width: 44,
                  height: 44,
                  shape: BoxShape.circle,
                  isDark: isDark,
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerBox(
                      width: 90,
                      height: 12,
                      borderRadius: BorderRadius.circular(4),
                      isDark: isDark,
                    ),
                    const SizedBox(height: 6),
                    ShimmerBox(
                      width: 140,
                      height: 18,
                      borderRadius: BorderRadius.circular(4),
                      isDark: isDark,
                    ),
                  ],
                ),
              ],
            ),
            Row(
              children: [
                ShimmerBox(
                  width: 40,
                  height: 40,
                  shape: BoxShape.circle,
                  isDark: isDark,
                ),
                const SizedBox(width: 8),
                ShimmerBox(
                  width: 40,
                  height: 40,
                  shape: BoxShape.circle,
                  isDark: isDark,
                ),
              ],
            ),
          ],
        ),

        const SizedBox(height: 20),

        // Hero Investment Card Skeleton (Matching Dark Navy Banner)
        Container(
          width: double.infinity,
          height: 175,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF18314F) : const Color(0xFF18314F),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF18314F).withValues(alpha: 0.2),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Top Row: Batch Pill & Status Dot
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ShimmerBox(
                    width: 110,
                    height: 24,
                    borderRadius: BorderRadius.circular(12),
                    baseColor: Colors.white.withValues(alpha: 0.15),
                    highlightColor: Colors.white.withValues(alpha: 0.3),
                  ),
                  ShimmerBox(
                    width: 85,
                    height: 14,
                    borderRadius: BorderRadius.circular(4),
                    baseColor: Colors.white.withValues(alpha: 0.15),
                    highlightColor: Colors.white.withValues(alpha: 0.3),
                  ),
                ],
              ),

              // Middle: Total Investment Number
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShimmerBox(
                    width: 120,
                    height: 12,
                    borderRadius: BorderRadius.circular(4),
                    baseColor: Colors.white.withValues(alpha: 0.2),
                    highlightColor: Colors.white.withValues(alpha: 0.35),
                  ),
                  const SizedBox(height: 8),
                  ShimmerBox(
                    width: 180,
                    height: 28,
                    borderRadius: BorderRadius.circular(6),
                    baseColor: Colors.white.withValues(alpha: 0.25),
                    highlightColor: Colors.white.withValues(alpha: 0.45),
                  ),
                ],
              ),

              // Bottom row: 3 mini pills
              Row(
                children: [
                  Expanded(
                    child: ShimmerBox(
                      height: 26,
                      borderRadius: BorderRadius.circular(13),
                      baseColor: Colors.white.withValues(alpha: 0.15),
                      highlightColor: Colors.white.withValues(alpha: 0.3),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ShimmerBox(
                      height: 26,
                      borderRadius: BorderRadius.circular(13),
                      baseColor: Colors.white.withValues(alpha: 0.15),
                      highlightColor: Colors.white.withValues(alpha: 0.3),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // 4 Metric Stats Grid (2x2)
        Row(
          children: [
            Expanded(child: _buildMetricBox(context, isDark, cardBg, cardBorder)),
            const SizedBox(width: 12),
            Expanded(child: _buildMetricBox(context, isDark, cardBg, cardBorder)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildMetricBox(context, isDark, cardBg, cardBorder)),
            const SizedBox(width: 12),
            Expanded(child: _buildMetricBox(context, isDark, cardBg, cardBorder)),
          ],
        ),

        const SizedBox(height: 24),

        // Section Title: Quick Actions / Activity
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ShimmerBox(
              width: 130,
              height: 18,
              borderRadius: BorderRadius.circular(4),
              isDark: isDark,
            ),
            ShimmerBox(
              width: 60,
              height: 14,
              borderRadius: BorderRadius.circular(4),
              isDark: isDark,
            ),
          ],
        ),
        const SizedBox(height: 14),

        // 3 Activity List Item Cards
        _buildActivityCardSkeleton(isDark, cardBg, cardBorder),
        const SizedBox(height: 10),
        _buildActivityCardSkeleton(isDark, cardBg, cardBorder),
        const SizedBox(height: 10),
        _buildActivityCardSkeleton(isDark, cardBg, cardBorder),
      ],
    );
  }

  Widget _buildMetricBox(BuildContext context, bool isDark, Color cardBg, Color cardBorder) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.12 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ShimmerBox(
                width: 32,
                height: 32,
                borderRadius: BorderRadius.circular(10),
                isDark: isDark,
              ),
              ShimmerBox(
                width: 40,
                height: 12,
                borderRadius: BorderRadius.circular(4),
                isDark: isDark,
              ),
            ],
          ),
          const SizedBox(height: 14),
          ShimmerBox(
            width: 75,
            height: 12,
            borderRadius: BorderRadius.circular(4),
            isDark: isDark,
          ),
          const SizedBox(height: 6),
          ShimmerBox(
            width: 95,
            height: 20,
            borderRadius: BorderRadius.circular(4),
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildActivityCardSkeleton(bool isDark, Color cardBg, Color cardBorder) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
      ),
      child: Row(
        children: [
          ShimmerBox(
            width: 40,
            height: 40,
            borderRadius: BorderRadius.circular(12),
            isDark: isDark,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerBox(
                  width: 130,
                  height: 14,
                  borderRadius: BorderRadius.circular(4),
                  isDark: isDark,
                ),
                const SizedBox(height: 6),
                ShimmerBox(
                  width: 90,
                  height: 11,
                  borderRadius: BorderRadius.circular(4),
                  isDark: isDark,
                ),
              ],
            ),
          ),
          ShimmerBox(
            width: 65,
            height: 22,
            borderRadius: BorderRadius.circular(11),
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  // ==================== 2. REQUESTS TAB SKELETON ====================
  Widget _buildRequestsSkeleton(BuildContext context, bool isDark) {
    final cardBg = isDark ? const Color(0xFF1B2A3F) : Colors.white;
    final cardBorder = isDark ? const Color(0xFF28354A) : const Color(0xFFE2E8F0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title Bar
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerBox(
                  width: 140,
                  height: 22,
                  borderRadius: BorderRadius.circular(4),
                  isDark: isDark,
                ),
                const SizedBox(height: 6),
                ShimmerBox(
                  width: 190,
                  height: 12,
                  borderRadius: BorderRadius.circular(4),
                  isDark: isDark,
                ),
              ],
            ),
            ShimmerBox(
              width: 38,
              height: 38,
              borderRadius: BorderRadius.circular(12),
              isDark: isDark,
            ),
          ],
        ),

        const SizedBox(height: 20),

        // Quick Category Action Cards (Horizontal Row)
        Row(
          children: List.generate(
            3,
            (index) => Expanded(
              child: Container(
                margin: EdgeInsets.only(right: index < 2 ? 10.0 : 0),
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: cardBorder),
                ),
                child: Column(
                  children: [
                    ShimmerBox(
                      width: 36,
                      height: 36,
                      shape: BoxShape.circle,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 8),
                    ShimmerBox(
                      width: 55,
                      height: 12,
                      borderRadius: BorderRadius.circular(4),
                      isDark: isDark,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 18),

        // Search Bar Skeleton
        ShimmerBox(
          width: double.infinity,
          height: 44,
          borderRadius: BorderRadius.circular(14),
          isDark: isDark,
        ),

        const SizedBox(height: 20),

        // Section Title
        ShimmerBox(
          width: 110,
          height: 16,
          borderRadius: BorderRadius.circular(4),
          isDark: isDark,
        ),
        const SizedBox(height: 12),

        // Request Item Cards
        ...List.generate(
          4,
          (i) => Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: _buildActivityCardSkeleton(isDark, cardBg, cardBorder),
          ),
        ),
      ],
    );
  }

  // ==================== 3. HOGS TAB SKELETON ====================
  Widget _buildHogsSkeleton(BuildContext context, bool isDark) {
    final cardBg = isDark ? const Color(0xFF1B2A3F) : Colors.white;
    final cardBorder = isDark ? const Color(0xFF28354A) : const Color(0xFFE2E8F0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title Bar & Batch Pill
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerBox(
                  width: 150,
                  height: 22,
                  borderRadius: BorderRadius.circular(4),
                  isDark: isDark,
                ),
                const SizedBox(height: 6),
                ShimmerBox(
                  width: 180,
                  height: 12,
                  borderRadius: BorderRadius.circular(4),
                  isDark: isDark,
                ),
              ],
            ),
            ShimmerBox(
              width: 80,
              height: 26,
              borderRadius: BorderRadius.circular(13),
              isDark: isDark,
            ),
          ],
        ),

        const SizedBox(height: 18),

        // Segmented Tab Switcher (Hogs / Reports)
        Container(
          width: double.infinity,
          height: 44,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: cardBorder),
          ),
          child: Row(
            children: [
              Expanded(
                child: ShimmerBox(
                  height: 36,
                  borderRadius: BorderRadius.circular(10),
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: ShimmerBox(
                  height: 36,
                  borderRadius: BorderRadius.circular(10),
                  isDark: isDark,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),

        // Hog Cards
        ...List.generate(
          4,
          (i) => Container(
            margin: const EdgeInsets.only(bottom: 12.0),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        ShimmerBox(
                          width: 38,
                          height: 38,
                          borderRadius: BorderRadius.circular(12),
                          isDark: isDark,
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ShimmerBox(
                              width: 90,
                              height: 16,
                              borderRadius: BorderRadius.circular(4),
                              isDark: isDark,
                            ),
                            const SizedBox(height: 4),
                            ShimmerBox(
                              width: 60,
                              height: 11,
                              borderRadius: BorderRadius.circular(4),
                              isDark: isDark,
                            ),
                          ],
                        ),
                      ],
                    ),
                    ShimmerBox(
                      width: 70,
                      height: 22,
                      borderRadius: BorderRadius.circular(11),
                      isDark: isDark,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ShimmerBox(
                        height: 26,
                        borderRadius: BorderRadius.circular(8),
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ShimmerBox(
                        height: 26,
                        borderRadius: BorderRadius.circular(8),
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),
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
        // Big Center Avatar
        Center(
          child: Column(
            children: [
              ShimmerBox(
                width: 90,
                height: 90,
                shape: BoxShape.circle,
                isDark: isDark,
              ),
              const SizedBox(height: 14),
              ShimmerBox(
                width: 160,
                height: 20,
                borderRadius: BorderRadius.circular(6),
                isDark: isDark,
              ),
              const SizedBox(height: 6),
              ShimmerBox(
                width: 90,
                height: 14,
                borderRadius: BorderRadius.circular(10),
                isDark: isDark,
              ),
            ],
          ),
        ),

        const SizedBox(height: 28),

        // 4 Profile Option Cards
        ...List.generate(
          4,
          (i) => Container(
            margin: const EdgeInsets.only(bottom: 12.0),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cardBorder),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    ShimmerBox(
                      width: 32,
                      height: 32,
                      borderRadius: BorderRadius.circular(10),
                      isDark: isDark,
                    ),
                    const SizedBox(width: 14),
                    ShimmerBox(
                      width: 120,
                      height: 15,
                      borderRadius: BorderRadius.circular(4),
                      isDark: isDark,
                    ),
                  ],
                ),
                ShimmerBox(
                  width: 18,
                  height: 18,
                  borderRadius: BorderRadius.circular(4),
                  isDark: isDark,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
