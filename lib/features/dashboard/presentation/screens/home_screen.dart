import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:impact_nation_fund_raising/core/utils/currency_formatter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/utils/image_provider_util.dart';
import '../../../../core/widgets/loading_state.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../members/providers/member_providers.dart';
import '../../../members/domain/models/member_profile.dart';
import '../../../campaigns/providers/campaign_providers.dart';
import '../../../contributions/providers/contribution_providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(myProfileProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return profileAsync.when(
      loading: () => const LoadingState(),
      error: (e, _) => _buildBody(context, theme, colorScheme, null),
      data: (profile) => _buildBody(context, theme, colorScheme, profile),
    );
  }

  Widget _buildBody(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    MemberProfile? profile,
  ) {
    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          // ── SliverAppBar ─────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 180,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: AppColors.primary,
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.parallax,
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          _greeting(),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          profile != null
                              ? profile.fullName.split(' ').first
                              : 'Friend',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Your generosity makes a difference 🙏',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
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
              if (profile != null) ...[
                IconButton(
                  icon: const Icon(
                    Icons.notifications_none,
                    color: Colors.white,
                  ),
                  onPressed: () => context.push('/home/notifications'),
                ),
                GestureDetector(
                  onTap: () => context.go('/profile'),
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
            ],
          ),

          // ── Content ───────────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Campaign Progress Card
                _CampaignCard(),
                const SizedBox(height: 20),

                // Stats row
                _StatsRow(),
                const SizedBox(height: 24),

                // Section header
                Text(
                  'Quick Actions',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),

                // Quick actions grid
                _QuickActionsGrid(profile: profile),
                const SizedBox(height: 24),

                // Section header
                Text(
                  'Latest Updates',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),

                // Activity feed
                _ActivityFeed(),
                const SizedBox(height: 16),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning 🌅';
    if (hour < 17) return 'Good afternoon ☀️';
    return 'Good evening 🌙';
  }

  String _initials(String name) {
    if (name.isEmpty) return '?';
    return name.trim().split(' ').map((w) => w[0]).take(2).join().toUpperCase();
  }
}

// ── Campaign Progress Card ──────────────────────────────────────────────────

class _CampaignCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final campaignAsync = ref.watch(activeCampaignProvider);

    return campaignAsync.when(
      loading: () => const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => ErrorState(message: e.toString()),
      data: (campaign) {
        if (campaign == null) return const SizedBox.shrink();

        final progress = campaign.progressPercentage;
        final raised = campaign.totalVerified;
        final goal = campaign.targetAmount;
        final remainingDays = campaign.endDate
            .difference(DateTime.now())
            .inDays
            .clamp(0, 9999);

        return GestureDetector(
          onTap: () => context.push('/home/campaign'),
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, Color(0xFF1565C0)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.35),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.volunteer_activism,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            campaign.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            'Impact Nation Gospel Center',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.75),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
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
                        campaign.status.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.white.withValues(alpha: 0.25),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.white,
                    ),
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 10),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '₦${_fmt(raised)} raised',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                    Text(
                      'of ₦${_fmt(goal)}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${(progress * 100).toStringAsFixed(0)}% funded · $remainingDays days remaining',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => context.push('/home/campaign'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_card_rounded, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Make a Pledge',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _fmt(double v) => CurrencyFormatter.formatCompact(v);
}

// ── Stats Row ──────────────────────────────────────────────────────────────

class _StatsRow extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final campaignAsync = ref.watch(activeCampaignProvider);
    final campaign = campaignAsync.value;

    final members = campaign?.participantsCount ?? 0;
    final pledged = campaign?.totalPledged ?? 0.0;
    final verified = campaign?.totalVerified ?? 0.0;
    String fmtK(double v) => CurrencyFormatter.formatCompactCurrency(v);

    return Row(
      children: [
        _StatChip(
          icon: Icons.group_rounded,
          label: 'Participants',
          value: '$members',
        ),
        const SizedBox(width: 10),
        _StatChip(
          icon: Icons.handshake_rounded,
          label: 'Pledged',
          value: fmtK(pledged),
        ),
        const SizedBox(width: 10),
        _StatChip(
          icon: Icons.verified_rounded,
          label: 'Collected',
          value: fmtK(verified),
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.6,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary, size: 20),
            const SizedBox(height: 6),
            Text(
              value,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Quick Actions Grid ─────────────────────────────────────────────────────

class _QuickActionsGrid extends StatelessWidget {
  final MemberProfile? profile;
  const _QuickActionsGrid({required this.profile});

  @override
  Widget build(BuildContext context) {
    final actions = [
      _Action(
        icon: Icons.add_card_rounded,
        label: 'Make\nPledge',
        color: AppColors.primary,
        onTap: () => context.push('/home/campaign'),
      ),
      _Action(
        icon: Icons.receipt_long_rounded,
        label: 'My\nPledges',
        color: const Color(0xFF7B1FA2),
        onTap: () => context.go('/pledges'),
      ),
      _Action(
        icon: Icons.person_rounded,
        label: 'My\nProfile',
        color: AppColors.secondary,
        onTap: () => context.go('/profile'),
      ),
      _Action(
        icon: Icons.notifications_outlined,
        label: 'Updates',
        color: AppColors.gold,
        onTap: () => context.push('/home/notifications'),
      ),
    ];

    return GridView.count(
      crossAxisCount: 4,
      childAspectRatio: 0.75,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      children: actions.map((a) => _QuickActionItem(action: a)).toList(),
    );
  }
}

class _Action {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _Action({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
}

class _QuickActionItem extends StatelessWidget {
  final _Action action;
  const _QuickActionItem({required this.action});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: action.onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: action.color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: action.color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(action.icon, color: action.color, size: 22),
            ),
            const SizedBox(height: 6),
            Text(
              action.label,
              textAlign: TextAlign.center,
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Activity Feed ──────────────────────────────────────────────────────────

class _ActivityFeed extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contributionsAsync = ref.watch(myContributionsProvider);
    final theme = Theme.of(context);

    return contributionsAsync.when(
      loading: () => const SizedBox(
        height: 80,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (all) {
        // Show the 5 most recent contributions (any status) sorted by date
        final recent = all.take(5).toList();

        if (recent.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.5,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                'No activity yet — be the first to contribute! 🙏',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                ),
              ),
            ),
          );
        }

        return Column(
          children: recent.map((c) {
            final isVerified = c.status.name == 'VERIFIED';
            final icon = isVerified
                ? Icons.check_circle_rounded
                : Icons.upload_rounded;
            final iconColor = isVerified
                ? AppColors.success
                : AppColors.primary;
            final action = isVerified
                ? 'contribution of ₦${_fmt(c.amount)} verified ✓'
                : 'submitted a payment of ₦${_fmt(c.amount)}';
            final timeAgo = _timeAgo(c.createdAt);

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.5,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: iconColor.withValues(alpha: 0.12),
                    child: Icon(icon, color: iconColor, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'You',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          action,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.6,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    timeAgo,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.45,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  String _fmt(double v) => CurrencyFormatter.formatCompact(v);

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
