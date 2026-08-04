import 'package:riverpod/riverpod.dart';
import '../../data/challenge_service.dart';
import '../../domain/models/challenge.dart';

final challengeServiceProvider = Provider((ref) {
  return ChallengeService();
});

final currentChallengeProvider = StreamProvider<Challenge>((ref) {
  final service = ref.watch(challengeServiceProvider);
  return service.watchCurrentChallenge();
});
