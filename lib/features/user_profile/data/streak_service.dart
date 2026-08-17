import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class StreakData {
  final String uid;
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastCompletedDate;

  StreakData({
    required this.uid,
    required this.currentStreak,
    required this.longestStreak,
    this.lastCompletedDate,
  });

  factory StreakData.fromJson(Map<String, dynamic> json) {
    return StreakData(
      uid: json['uid'],
      currentStreak: json['currentStreak'] ?? 0,
      longestStreak: json['longestStreak'] ?? 0,
      lastCompletedDate: json['lastCompletedDate'] != null
          ? (json['lastCompletedDate'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'lastCompletedDate': lastCompletedDate != null
          ? Timestamp.fromDate(lastCompletedDate!)
          : null,
    };
  }
}

class StreakService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<StreakData> getStreak(String uid) async {
    try {
      final doc = await _firestore.collection('streaks').doc(uid).get();
      if (!doc.exists) {
        return StreakData(
          uid: uid,
          currentStreak: 0,
          longestStreak: 0,
        );
      }
      return StreakData.fromJson(doc.data()!);
    } catch (e) {
      print('Failed to get streak: $e');
      return StreakData(uid: uid, currentStreak: 0, longestStreak: 0);
    }
  }

  Future<void> updateStreak(String uid) async {
    try {
      final docRef = _firestore.collection('streaks').doc(uid);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday =
          DateTime(now.year, now.month, now.day).subtract(const Duration(days: 1));

      // Read, calculate and write inside a single transaction so concurrent
      // calls (e.g. rapid taps or multiple devices) serialize correctly
      // instead of racing and clobbering each other (lost update).
      await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(docRef);
        final streak = doc.exists
            ? StreakData.fromJson(doc.data()!)
            : StreakData(uid: uid, currentStreak: 0, longestStreak: 0);

        final lastDate = streak.lastCompletedDate;

        int newStreak = streak.currentStreak;
        int newLongestStreak = streak.longestStreak;

        if (lastDate == null) {
          newStreak = 1;
        } else {
          final lastDay = DateTime(lastDate.year, lastDate.month, lastDate.day);
          if (lastDay.isAtSameMomentAs(yesterday)) {
            newStreak = streak.currentStreak + 1;
          } else if (!lastDay.isAtSameMomentAs(today)) {
            newStreak = 1;
          }
        }

        if (newStreak > newLongestStreak) {
          newLongestStreak = newStreak;
        }

        final data = {
          'uid': uid,
          'currentStreak': newStreak,
          'longestStreak': newLongestStreak,
          'lastCompletedDate': Timestamp.fromDate(today),
          'updatedAt': FieldValue.serverTimestamp(),
        };

        if (doc.exists) {
          transaction.update(docRef, data);
        } else {
          transaction.set(docRef, data);
        }
      });
    } catch (e) {
      debugPrint('Failed to update streak: $e');
    }
  }

  Stream<StreakData> getStreakStream(String uid) {
    return _firestore
        .collection('streaks')
        .doc(uid)
        .snapshots()
        .map((doc) {
          if (!doc.exists) {
            return StreakData(uid: uid, currentStreak: 0, longestStreak: 0);
          }
          return StreakData.fromJson(doc.data()!);
        })
        .transform(
          StreamTransformer.fromHandlers(
            handleError: (error, stack, sink) {
              debugPrint('getStreakStream error: $error');
              sink.addError(error, stack);
            },
          ),
        );
  }
}
