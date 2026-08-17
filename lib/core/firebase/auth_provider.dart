import 'package:riverpod/riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_service.dart';
import '../../features/user_profile/presentation/providers/user_provider.dart';

final authServiceProvider = Provider((ref) {
  return AuthService();
});

final currentUserProvider = StreamProvider((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

final userProfileProvider = FutureProvider((ref) async {
  final authService = ref.watch(authServiceProvider);
  final user = await ref.watch(currentUserProvider.future);

  if (user == null) {
    final result = await authService.signInAnonymously();
    if (result != null) {
      return authService.getUserProfile(result.user!.uid);
    }
    return null;
  }

  return authService.getUserProfile(user.uid);
});
