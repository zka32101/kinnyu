import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final onboardingCompletedProvider = FutureProvider<bool>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool('onboarding_completed') ?? false;
});

final markOnboardingCompletedProvider = FutureProvider<void>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('onboarding_completed', true);
});
