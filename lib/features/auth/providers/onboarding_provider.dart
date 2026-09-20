import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final onboardingCompletedProvider =
    NotifierProvider<OnboardingNotifier, bool>(OnboardingNotifier.new);

class OnboardingNotifier extends Notifier<bool> {
  static const prefKey = 'has_seen_onboarding';
  final bool? _overrideInitial;

  OnboardingNotifier([this._overrideInitial]);

  @override
  bool build() {
    if (_overrideInitial != null) {
      return _overrideInitial;
    }
    _loadFromPrefs();
    return false;
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final val = prefs.getBool(prefKey) ?? false;
    if (val != state) {
      state = val;
    }
  }

  Future<void> completeOnboarding() async {
    state = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(prefKey, true);
  }
}
