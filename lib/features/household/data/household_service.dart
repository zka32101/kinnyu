import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../domain/models/household_group.dart';
import '../domain/models/household_budget.dart';
import '../domain/models/household_expense_summary.dart';
import '../../receipt/domain/models/receipt.dart';

class HouseholdService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _groupsRef =>
      _firestore.collection('household_groups');

  String _generateInviteCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random();
    return List.generate(6, (_) => chars[random.nextInt(chars.length)]).join();
  }

  Future<HouseholdGroup> createGroup({
    required String uid,
    required String name,
    required String nickname,
    int monthlyGoal = 30000,
  }) async {
    final inviteCode = _generateInviteCode();
    final now = DateTime.now();

    final group = HouseholdGroup(
      id: inviteCode,
      name: name,
      members: [uid],
      totalSavings: 0,
      monthlyGoal: monthlyGoal,
      createdAt: now,
      memberNicknames: {uid: nickname},
      memberContributions: {},
    );

    try {
      await _firestore.runTransaction((transaction) async {
        transaction.set(_groupsRef.doc(inviteCode), group.toJson());
        transaction.update(_firestore.collection('users').doc(uid), {
          'householdGroupId': inviteCode,
        });
      });
    } catch (e) {
      debugPrint('createGroup transaction failed: $e');
      rethrow;
    }

    return group;
  }

  Future<HouseholdGroup?> joinGroup({
    required String uid,
    required String inviteCode,
    required String nickname,
  }) async {
    final code = inviteCode.toUpperCase();
    final groupDocRef = _groupsRef.doc(code);
    final userDocRef = _firestore.collection('users').doc(uid);

    try {
      return await _firestore.runTransaction<HouseholdGroup?>((transaction) async {
        final doc = await transaction.get(groupDocRef);
        if (!doc.exists) return null;

        final group = HouseholdGroup.fromJson({...doc.data()!, 'id': doc.id});

        if (!group.members.contains(uid)) {
          transaction.update(groupDocRef, {
            'members': FieldValue.arrayUnion([uid]),
            'memberNicknames.$uid': nickname,
          });
          transaction.update(userDocRef, {
            'householdGroupId': code,
          });

          return HouseholdGroup(
            id: group.id,
            name: group.name,
            members: [...group.members, uid],
            totalSavings: group.totalSavings,
            monthlyGoal: group.monthlyGoal,
            createdAt: group.createdAt,
            memberNicknames: {...group.memberNicknames, uid: nickname},
            memberContributions: group.memberContributions,
          );
        }

        return group;
      });
    } catch (e) {
      throw Exception('Failed to join group: $e');
    }
  }

  Future<HouseholdGroup?> getUserGroup(String uid) async {
    try {
      final userDoc = await _firestore.collection('users').doc(uid).get();
      final groupId = userDoc.data()?['householdGroupId'] as String?;

      if (groupId == null) return null;

      final groupDoc = await _groupsRef.doc(groupId).get();
      if (!groupDoc.exists) return null;

      return HouseholdGroup.fromJson({...groupDoc.data()!, 'id': groupDoc.id});
    } catch (e) {
      return null;
    }
  }

  Stream<HouseholdGroup?> watchGroup(String groupId) {
    return _groupsRef.doc(groupId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return HouseholdGroup.fromJson({...doc.data()!, 'id': doc.id});
    }).transform(
      StreamTransformer.fromHandlers(
        handleError: (error, stack, sink) {
          debugPrint('watchGroup error: $error');
          sink.addError(error, stack);
        },
      ),
    );
  }

  Future<void> addSavings(String groupId, String uid, int amount) async {
    try {
      await _groupsRef.doc(groupId).update({
        'totalSavings': FieldValue.increment(amount),
        'memberContributions.$uid': FieldValue.increment(amount),
      });
    } catch (e) {
      debugPrint('addSavings failed: $e');
      rethrow;
    }
  }

  Future<void> leaveGroup({
    required String uid,
    required String groupId,
  }) async {
    final groupDocRef = _groupsRef.doc(groupId);
    final userDocRef = _firestore.collection('users').doc(uid);

    try {
      await _firestore.runTransaction((transaction) async {
        transaction.update(groupDocRef, {
          'members': FieldValue.arrayRemove([uid]),
          'memberNicknames.$uid': FieldValue.delete(),
          'memberContributions.$uid': FieldValue.delete(),
        });
        transaction.update(userDocRef, {
          'householdGroupId': FieldValue.delete(),
        });
      });
    } catch (e) {
      debugPrint('leaveGroup failed: $e');
      rethrow;
    }
  }

  // ==================== 予算管理機能 ====================

  Future<HouseholdBudget> initializeBudget(String groupId) async {
    final budget = HouseholdBudget.defaultTemplate(groupId);
    try {
      await _firestore.collection('household_budgets').doc(groupId).set(budget.toJson());
      return budget;
    } catch (e) {
      debugPrint('initializeBudget failed: $e');
      rethrow;
    }
  }

  Future<HouseholdBudget?> getBudget(String groupId) async {
    try {
      final doc = await _firestore.collection('household_budgets').doc(groupId).get();
      if (!doc.exists) return null;
      return HouseholdBudget.fromJson({...doc.data()!, 'id': doc.id});
    } catch (e) {
      debugPrint('getBudget failed: $e');
      return null;
    }
  }

  Future<void> updateBudget({
    required String groupId,
    required Map<BudgetCategory, int> budgets,
  }) async {
    try {
      final now = DateTime.now();
      await _firestore.collection('household_budgets').doc(groupId).update({
        'categoryBudgets': {
          for (var category in budgets.entries) category.key.name: category.value,
        },
        'updatedAt': now.toIso8601String(),
      });
    } catch (e) {
      debugPrint('updateBudget failed: $e');
      rethrow;
    }
  }

  /// 世帯メンバーの月間支出をカテゴリ別に集計
  /// 対象：groupId に属するすべてのメンバーのレシート
  Future<HouseholdMonthlyExpense> getMonthlyExpense({
    required String groupId,
    required DateTime month,
  }) async {
    try {
      final group = await getUserGroup(''); // ここはダミー、実装時には修正
      if (group == null) {
        throw Exception('Group not found: $groupId');
      }

      final expensesByCategory = <BudgetCategory, List<HouseholdExpenseRecord>>{};
      for (var category in BudgetCategory.values) {
        expensesByCategory[category] = [];
      }

      // グループの各メンバーについて、該当月のレシートを取得
      for (var memberUid in group.members) {
        final receipts = await _getReceiptsForMonth(memberUid, month);
        final nickname = group.memberNicknames[memberUid] ?? 'メンバー';

        for (var receipt in receipts) {
          final category = _mapReceiptCategoryToHouseholdCategory(receipt.category);
          expensesByCategory[category]?.add(
            HouseholdExpenseRecord(
              id: receipt.id,
              uid: memberUid,
              userNickname: nickname,
              date: receipt.date,
              category: category,
              amount: receipt.amount,
              receiptImagePath: receipt.imagePath,
            ),
          );
        }
      }

      return HouseholdMonthlyExpense(
        groupId: groupId,
        month: DateTime(month.year, month.month, 1),
        expensesByCategory: expensesByCategory,
        updatedAt: DateTime.now(),
      );
    } catch (e) {
      debugPrint('getMonthlyExpense failed: $e');
      rethrow;
    }
  }

  /// ユーザーの特定月のレシート情報を取得
  Future<List<Receipt>> _getReceiptsForMonth(String uid, DateTime month) async {
    try {
      final startDate = DateTime(month.year, month.month, 1);
      final endDate = DateTime(month.year, month.month + 1, 0, 23, 59, 59);

      final query = await _firestore
          .collection('receipts')
          .where('uid', isEqualTo: uid)
          .where('date', isGreaterThanOrEqualTo: startDate.toIso8601String())
          .where('date', isLessThanOrEqualTo: endDate.toIso8601String())
          .get();

      return query.docs.map((doc) {
        return Receipt.fromJson({...doc.data(), 'id': doc.id});
      }).toList();
    } catch (e) {
      debugPrint('_getReceiptsForMonth failed: $e');
      return [];
    }
  }

  /// ReceiptCategory を HouseholdBudgetCategory にマップ
  BudgetCategory _mapReceiptCategoryToHouseholdCategory(ReceiptCategory category) {
    switch (category) {
      case ReceiptCategory.convenience:
      case ReceiptCategory.grocery:
        return BudgetCategory.food;
      case ReceiptCategory.dining:
        return BudgetCategory.entertainment;
      case ReceiptCategory.entertainment:
        return BudgetCategory.entertainment;
      default:
        return BudgetCategory.other;
    }
  }
}
