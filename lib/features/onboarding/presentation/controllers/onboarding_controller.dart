import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lexii/core/constants/app_constants.dart';

final onboardingControllerProvider =
    StateNotifierProvider<OnboardingController, OnboardingState>((ref) {
  return OnboardingController();
});

class OnboardingState {
  final int currentPage;
  final bool isCompleted;

  const OnboardingState({
    this.currentPage = 0,
    this.isCompleted = false,
  });

  OnboardingState copyWith({int? currentPage, bool? isCompleted}) {
    return OnboardingState(
      currentPage: currentPage ?? this.currentPage,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

class OnboardingController extends StateNotifier<OnboardingState> {
  OnboardingController() : super(const OnboardingState());

  void nextPage() {
    state = state.copyWith(currentPage: state.currentPage + 1);
  }

  void goToPage(int page) {
    state = state.copyWith(currentPage: page);
  }

  Future<void> completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.onboardingCompletedKey, true);
    state = state.copyWith(isCompleted: true);
  }

  static Future<bool> isOnboardingCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(AppConstants.onboardingCompletedKey) ?? false;
  }
}
