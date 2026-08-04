import 'package:riverpod/riverpod.dart';
import '../../data/household_service.dart';
import '../../domain/models/household_group.dart';

final householdServiceProvider = Provider((ref) {
  return HouseholdService();
});

final userGroupProvider =
    FutureProvider.family<HouseholdGroup?, String>((ref, uid) async {
  final service = ref.watch(householdServiceProvider);
  return service.getUserGroup(uid);
});

final groupStreamProvider =
    StreamProvider.family<HouseholdGroup?, String>((ref, groupId) {
  final service = ref.watch(householdServiceProvider);
  return service.watchGroup(groupId);
});
