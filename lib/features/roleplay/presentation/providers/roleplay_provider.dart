import 'package:riverpod/riverpod.dart';
import '../../data/roleplay_service.dart';

final roleplayServiceProvider = Provider((ref) {
  return RoleplayService();
});
