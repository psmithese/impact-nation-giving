import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/adaptive_layout.dart';
import '../../providers/onboarding_provider.dart';

/// Premium multi-page onboarding + welcome screen
class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  void _completeAndGo(String route) {
    ref.read(onboardingCompletedProvider.notifier).completeOnboarding();
    context.go(route);
  }

  static const _pages = [
    _OnboardPage(
      icon: Icons.volunteer_activism_rounded,
      title: 'Give with Purpose',
      subtitle:
          'Join Impact Nation Gospel Center\'s mission. Every contribution brings us closer to our goal and helps others rise.',
      color: AppColors.gold,
    ),
    _OnboardPage(
      icon: Icons.shield_rounded,
      title: 'Secure & Transparent',
      subtitle:
          'Track every pledge and payment in real time. Bank transfers and cash contributions — all verified by our finance team.',
      color: Color(0xFF0EA5E9),
    ),
    _OnboardPage(
      icon: Icons.people_alt_rounded,
      title: 'Community Together',
      subtitle:
          'See who\'s pledged, who\'s contributed, and celebrate milestones together as one Impact Nation family.',
      color: AppColors.success,
    ),
  ];

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  // ── Mobile body helper ───────────────────────────────────────────────────
  Widget _buildMobileBody(BuildContext context, Size size, bool isLastPage) {
    return Stack(
      children: [
        // Dark gradient background
        Container(
          decoration: const BoxDecoration(
            gradient: AppColors.heroGradient,
          ),
        ),

        // Background circle accent
        Positioned(
          top: -size.height * 0.1,
          right: -size.width * 0.2,
          child: Container(
            width: size.width * 0.8,
            height: size.width * 0.8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.04),
                width: 60,
              ),
            ),
          ),
        ),

        SafeArea(
          child: Column(
            children: [
              // Skip button
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 8, 16, 0),
                  child: TextButton(
                    onPressed: isLastPage ? null : () => _completeAndGo('/login'),
                    child: Text(
                      'Skip',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),

              // Logo header
              const SizedBox(height: 8),
              _buildLogoHeader(),
              const SizedBox(height: 8),

              // Onboarding pages
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _pages.length,
                  onPageChanged: (i) => setState(() => _currentPage = i),
                  itemBuilder: (_, i) => _OnboardPageWidget(page: _pages[i]),
                ),
              ),

              // Dots indicator
              _DotsIndicator(
                count: _pages.length,
                current: _currentPage,
              ),
              const SizedBox(height: 32),

              // Action buttons
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: isLastPage
                      ? _buildFinalButtons(context)
                      : _buildNextButton(),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ],
    );
  }

  // ── Desktop body helper ──────────────────────────────────────────────────
  Widget _buildDesktopBody(BuildContext context, bool isLastPage) {
    return Row(
      children: [
        // Left — full onboarding experience
        Expanded(
          flex: 6,
          child: Stack(
            children: [
              Container(
                decoration: const BoxDecoration(
                  gradient: AppColors.heroGradient,
                ),
              ),
              Positioned(
                top: -120,
                right: -120,
                child: Container(
                  width: 500,
                  height: 500,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.04),
                      width: 80,
                    ),
                  ),
                ),
              ),
              SafeArea(
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    _buildLogoHeader(),
                    const SizedBox(height: 8),
                    Expanded(
                      child: PageView.builder(
                        controller: _pageController,
                        itemCount: _pages.length,
                        onPageChanged: (i) =>
                            setState(() => _currentPage = i),
                        itemBuilder: (_, i) =>
                            _OnboardPageWidget(page: _pages[i]),
                      ),
                    ),
                    _DotsIndicator(
                      count: _pages.length,
                      current: _currentPage,
                    ),
                    const SizedBox(height: 48),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Right — sign-in CTA card
        Expanded(
          flex: 4,
          child: Container(
            color: AppColors.backgroundDark,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Get Started',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Sign in to manage campaigns,\nverify contributions and more.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.55),
                          fontSize: 14,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Primary: Sign In
                      GestureDetector(
                        onTap: () => _completeAndGo('/login'),
                        child: Container(
                          height: 56,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                AppColors.goldLight,
                                AppColors.gold,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.gold.withValues(alpha: 0.4),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Text(
                              'Sign In',
                              style: TextStyle(
                                color: AppColors.primaryDark,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Secondary: Create Account
                      GestureDetector(
                        onTap: () => _completeAndGo('/register'),
                        child: Container(
                          height: 56,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2),
                              width: 1.5,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              'Create Account',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
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
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isLastPage = _currentPage == _pages.length - 1;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.backgroundDark,
        body: AdaptiveLayout(
          mobileChild: _buildMobileBody(context, size, isLastPage),
          desktopChild: _buildDesktopBody(context, isLastPage),
        ),
      ),
    );
  }

  Widget _buildLogoHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: const BoxDecoration(shape: BoxShape.circle),
          child: ClipOval(
            child: Image.asset(
              'assets/images/ingc_logo.png',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.church_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'IMPACT NATION',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
              ),
            ),
            Text(
              'GOSPEL CENTER',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 10,
                letterSpacing: 2,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNextButton() {
    return GestureDetector(
      key: const ValueKey('next'),
      onTap: _nextPage,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.goldLight, AppColors.gold],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppColors.gold.withValues(alpha: 0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Next',
              style: TextStyle(
                color: AppColors.primaryDark,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(width: 8),
            Icon(Icons.arrow_forward_rounded,
                color: AppColors.primaryDark, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildFinalButtons(BuildContext context) {
    return Column(
      key: const ValueKey('final'),
      children: [
        GestureDetector(
          onTap: () => _completeAndGo('/login'),
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.goldLight, AppColors.gold],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: AppColors.gold.withValues(alpha: 0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Center(
              child: Text(
                'Sign In',
                style: TextStyle(
                  color: AppColors.primaryDark,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () => _completeAndGo('/register'),
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.25),
                width: 1.5,
              ),
            ),
            child: Center(
              child: Text(
                'Create Account',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Onboarding Page Data ─────────────────────────────────────────────────────

class _OnboardPage {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  const _OnboardPage({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });
}

// ── Onboarding Page Widget ───────────────────────────────────────────────────

class _OnboardPageWidget extends StatelessWidget {
  final _OnboardPage page;
  const _OnboardPageWidget({required this.page});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon glow bubble
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: page.color.withValues(alpha: 0.12),
              border: Border.all(
                color: page.color.withValues(alpha: 0.3),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: page.color.withValues(alpha: 0.2),
                  blurRadius: 40,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Icon(page.icon, color: page.color, size: 56),
          ),
          const SizedBox(height: 40),
          Text(
            page.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            page.subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.65),
              fontSize: 15,
              height: 1.6,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Dots Indicator ───────────────────────────────────────────────────────────

class _DotsIndicator extends StatelessWidget {
  final int count;
  final int current;
  const _DotsIndicator({required this.count, required this.current});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final isActive = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: isActive
                ? AppColors.goldLight
                : Colors.white.withValues(alpha: 0.25),
          ),
        );
      }),
    );
  }
}
