import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/image_provider_util.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/widgets/loading_state.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../members/providers/member_providers.dart';
import '../../../members/domain/models/member_profile.dart';
import '../../../auth/domain/models/app_user.dart';
import '../../../campaigns/providers/campaign_providers.dart';
import '../../providers/admin_dashboard_providers.dart';
import 'package:fl_chart/fl_chart.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(myProfileProvider);
    final theme = Theme.of(context);

    return profileAsync.when(
      loading: () => const LoadingState(),
      error: (e, _) => _buildContent(context, theme, null),
      data: (profile) => _buildContent(context, theme, profile),
    );
  }

  Widget _buildContent(
    BuildContext context,
    ThemeData theme,
    MemberProfile? profile,
  ) {
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          // ── AppBar ────────────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 160,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: AppColors.primaryDark,
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.parallax,
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primaryDark, Color(0xFF0D47A1)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                _roleLabel(profile?.role),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Admin Dashboard',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Impact Nation Gospel Center',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            actions: [
              // Theme toggle
              Consumer(
                builder: (ctx, ref, _) {
                  final mode = ref.watch(themeModeProvider);
                  IconData icon;
                  if (mode == ThemeMode.light)
                    icon = Icons.dark_mode_outlined;
                  else if (mode == ThemeMode.dark)
                    icon = Icons.brightness_auto_outlined;
                  else
                    icon = Icons.light_mode_outlined;
                  return IconButton(
                    tooltip: 'Toggle Theme',
                    icon: Icon(icon, color: Colors.white),
                    onPressed: () =>
                        ref.read(themeModeProvider.notifier).toggleTheme(),
                  );
                },
              ),
              if (profile != null)
                GestureDetector(
                  onTap: () => context.go('/admin/profile'),
                  child: Container(
                    margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      backgroundImage: profile.photoUrl != null
                          ? getImageProvider(profile.photoUrl!)
                          : null,
                      child: profile.photoUrl == null
                          ? Text(
                              _initials(profile.fullName),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            )
                          : null,
                    ),
                  ),
                ),
            ],
          ),

          // ── Content ───────────────────────────────────────────────────────
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              AppBreakpoints.isDesktop(context) ? 24 : 16,
              20,
              AppBreakpoints.isDesktop(context) ? 24 : 16,
              24,
            ),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Overview stats
                Text(
                  'Overview',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                _OverviewGrid(),
                const SizedBox(height: 24),

                // Campaign summary
                _CampaignSummaryCard(),
                const SizedBox(height: 24),

                // Charts
                Text(
                  'Analytics',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                _AdminCharts(),
                const SizedBox(height: 24),

                // Quick actions
                Text(
                  'Quick Actions',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                _AdminQuickActions(),
                const SizedBox(height: 24),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  String _roleLabel(UserRole? role) {
    return switch (role) {
      UserRole.SUPER_ADMIN => 'Super Admin',
      UserRole.FINANCE_OFFICER => 'Finance Officer',
      UserRole.ADMIN => 'Admin',
      _ => 'Admin',
    };
  }

  String _initials(String? name) {
    if (name == null || name.trim().isEmpty) return '?';
    final parts =
        name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    return parts.map((w) => w[0]).take(2).join().toUpperCase();
  }
}

// ── Breakpoint helper (local alias) ────────────────────────────────────────

class AppBreakpoints {
  static const double _desktop = 900;
  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= _desktop;
}

// ── Overview Stats Grid ─────────────────────────────────────────────────────

class _OverviewGrid extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(adminDashboardStatsProvider);
    final isDesktop = AppBreakpoints.isDesktop(context);

    return statsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => ErrorState(message: err.toString()),
      data: (stats) {
        final List<(String, String, IconData, Color)> data = [
          (
            '${stats.totalMembers}',
            'Total\nMembers',
            Icons.group_rounded,
            AppColors.primary,
          ),
          (
            '${stats.totalParticipants}',
            'Total\nParticipants',
            Icons.handshake_rounded,
            const Color(0xFF7B1FA2),
          ),
          (
            '₦${_fmtK(stats.totalVerified)}',
            'Total\nRaised',
            Icons.payments_rounded,
            AppColors.secondary,
          ),
          (
            '${stats.pledgedOnlyMembers}',
            'Pledged\nOnly',
            Icons.hourglass_empty_rounded,
            const Color(0xFFE65100),
          ),
        ];

        return GridView.count(
          crossAxisCount: isDesktop ? 4 : 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: isDesktop ? 2.0 : 1.6,
          children: data.map((s) {
            final (value, label, icon, color) = s;
            return _OverviewCard(
              value: value,
              label: label,
              icon: icon,
              color: color,
            );
          }).toList(),
        );
      },
    );
  }

  String _fmtK(double v) {
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}k';
    return v.toStringAsFixed(0);
  }
}

class _OverviewCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  const _OverviewCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    height: 1.2,
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

// ── Campaign Summary Card ────────────────────────────────────────────────────

class _CampaignSummaryCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final campaignAsync = ref.watch(activeCampaignProvider);
    final theme = Theme.of(context);

    return campaignAsync.when(
      loading: () => const SizedBox(
        height: 150,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => const _NoCampaignCard(),
      data: (campaign) {
        if (campaign == null) return const _NoCampaignCard();

        final progress = campaign.progressPercentage;
        final raised = campaign.totalVerified;
        final goal = campaign.targetAmount;
        final remainingDays = campaign.endDate
            .difference(DateTime.now())
            .inDays
            .clamp(0, 9999);

        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.15),
            ),
            color: theme.colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.4,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.campaign_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    campaign.name,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      campaign.status.name,
                      style: const TextStyle(
                        color: AppColors.success,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: theme.colorScheme.outline.withValues(
                    alpha: 0.2,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '₦${_fmtK(raised)} raised',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'Goal: ₦${_fmtK(goal)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.55,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${(progress * 100).toStringAsFixed(0)}% · $remainingDays days remaining',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _fmtK(double v) {
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}k';
    return v.toStringAsFixed(0);
  }
}

// ── Admin Quick Actions ──────────────────────────────────────────────────────

class _AdminQuickActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final actions = [
      (
        Icons.group_rounded,
        'Members',
        AppColors.primary,
        () => context.go('/admin/members'),
      ),
      (
        Icons.visibility_rounded,
        'Transparency',
        const Color(0xFF7B1FA2),
        () => context.push('/admin/dashboard/transparency'),
      ),
      (
        Icons.verified_rounded,
        'Verify',
        AppColors.secondary,
        () => context.push('/admin/dashboard/verify'),
      ),
      (
        Icons.campaign_rounded,
        'Campaigns',
        const Color(0xFFE65100),
        () => context.push('/admin/dashboard/campaigns'),
      ),
    ];

    return GridView.count(
      crossAxisCount: 4,
      childAspectRatio: 0.75,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      children: actions.map((a) {
        final (icon, label, color, onTap) = a;
        return InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── No Campaign Empty State Card ──────────────────────────────────────────────

class _NoCampaignCard extends StatelessWidget {
  const _NoCampaignCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.campaign_outlined,
            size: 48,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 12),
          Text(
            'No Active Campaign',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Create a campaign in the Campaigns section to start tracking fundraising progress.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Admin Charts ──────────────────────────────────────────────────────

class _AdminCharts extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(adminDashboardStatsProvider);
    final theme = Theme.of(context);
    final isDesktop = AppBreakpoints.isDesktop(context);

    return statsAsync.when(
      loading: () => const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (err, _) => const _NoCampaignCard(),
      data: (stats) {
        if (stats.totalTarget == 0) {
          return const _NoCampaignCard();
        }

        final barChart = _buildBarChart(theme, stats);
        final pieChart = _buildPieChart(theme, stats);

        if (isDesktop) {
          // Side-by-side on wide screens
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: barChart),
              const SizedBox(width: 16),
              Expanded(child: pieChart),
            ],
          );
        }

        // Stacked on mobile
        return Column(
          children: [
            barChart,
            const SizedBox(height: 16),
            pieChart,
          ],
        );
      },
    );
  }

  Widget _buildBarChart(ThemeData theme, dynamic stats) {
    return Container(
      height: 250,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.15),
        ),
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.3,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Campaign Progress',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          // Use SizedBox (not Expanded) so fl_chart always has bounded height on web
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: stats.totalTarget > 0 ? stats.totalTarget : 1000,
                barTouchData: BarTouchData(enabled: true),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final labels = ['Target', 'Pledged', 'Paid'];
                        if (value.toInt() >= 0 &&
                            value.toInt() < labels.length) {
                          return Text(
                            labels[value.toInt()],
                            style: const TextStyle(fontSize: 10),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: [
                  BarChartGroupData(
                    x: 0,
                    barRods: [
                      BarChartRodData(
                        toY: stats.totalTarget,
                        color: Colors.grey.withValues(alpha: 0.5),
                        width: 22,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  ),
                  BarChartGroupData(
                    x: 1,
                    barRods: [
                      BarChartRodData(
                        toY: stats.totalPledged,
                        color: AppColors.primary,
                        width: 22,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  ),
                  BarChartGroupData(
                    x: 2,
                    barRods: [
                      BarChartRodData(
                        toY: stats.totalVerified,
                        color: AppColors.secondary,
                        width: 22,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPieChart(ThemeData theme, dynamic stats) {
    return Container(
      height: 250,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.15),
        ),
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.3,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Payment Methods',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          // Use SizedBox (not Expanded) so fl_chart always has bounded height on web
          SizedBox(
            height: 180,
            child: stats.paymentMethods.isEmpty
                ? const Center(child: Text('No payment data'))
                : PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 40,
                      sections: stats.paymentMethods.entries.map((e) {
                        final color =
                            e.key.toUpperCase().contains('CASH')
                            ? AppColors.secondary
                            : AppColors.primary;
                        return PieChartSectionData(
                          color: color,
                          value: e.value,
                          title: e.key,
                          radius: 40,
                          titleStyle: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
