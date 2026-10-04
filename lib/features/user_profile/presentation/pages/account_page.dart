import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/firebase/account_deletion_service.dart';
import '../../../../core/firebase/secure_storage_service.dart';
import '../../../../core/firebase/auth_provider.dart';
import '../../../../core/subscription/subscription_provider.dart';
import '../../../premium/presentation/pages/paywall_page.dart';

/// アカウント情報の確認・Googleログイン・プレミアム加入状況を表示するページ。
class AccountPage extends ConsumerStatefulWidget {
  const AccountPage({Key? key}) : super(key: key);

  @override
  ConsumerState<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends ConsumerState<AccountPage> {
  bool _processing = false;

  Future<void> _signInWithGoogle() async {
    if (_processing) return;
    setState(() => _processing = true);
    try {
      final authService = ref.read(authServiceProvider);
      final result = await authService.signInWithGoogle();
      if (!mounted) return;
      if (result != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Googleアカウントでログインしました')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ログインに失敗しました: $e')),
      );
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  Future<void> _signOut() async {
    if (_processing) return;
    setState(() => _processing = true);
    try {
      final authService = ref.read(authServiceProvider);
      await authService.signOut();
      // アプリはログインユーザーが常に存在する前提で動くため、
      // ログアウト後は新しい匿名アカウントで再サインインする。
      await authService.signInAnonymously();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ログアウトしました')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ログアウトに失敗しました: $e')),
      );
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  /// アカウントと、クラウド上・端末内のデータをすべて削除する。
  ///
  /// 順序: ①再認証（Googleログインの場合）→ ②Firestore のデータ削除 →
  /// ③ログインアカウント削除 → ④端末内のデータ削除 → 新しい匿名アカウントで再開。
  /// 再認証を先にするのは、データだけ消えてアカウントが残る事態を避けるため。
  Future<void> _deleteAccount() async {
    if (_processing) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('アカウントとデータを削除'),
        content: const Text(
          '次のデータがすべて削除され、元に戻せません。\n'
          '・家計・支出・レシート・貯蓄目標・仮想投資などの記録\n'
          '・ミッション、ストリーク、クイズの進み具合\n'
          '・世帯リーグからの脱退（ニックネームと貢献額も削除）\n\n'
          'プレミアムの購読は自動では解約されません。'
          'Google Play の「定期購入」から、別途解約してください。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('やめる'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('削除する'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _processing = true);
    try {
      final authService = ref.read(authServiceProvider);
      final uid = authService.getCurrentUser()?.uid;
      if (uid == null) throw Exception('ログイン情報が見つかりません');

      if (!await authService.reauthenticateForDeletion()) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('本人確認がキャンセルされたため、削除を中止しました')),
        );
        return;
      }
      await AccountDeletionService().deleteUserData(uid);
      await authService.deleteCurrentUser();

      await SecureStorageService.clearAll();
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      // アプリはログインユーザーが常に存在する前提のため、新しい匿名アカウントで再開する。
      await authService.signInAnonymously();
      if (!mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('アカウントとデータを削除しました')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('削除に失敗しました。もう一度お試しください: $e')),
      );
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  Widget _buildDeleteCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'アカウントとデータの削除',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'このアカウントと、保存されているすべてのデータを削除します。',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                onPressed: _processing ? null : _deleteAccount,
                icon: const Icon(Icons.delete_forever),
                label: const Text('アカウントとデータを削除'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);
    final isPremium = ref.watch(isPremiumProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('アカウント')),
      body: userAsync.when(
        data: (user) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildAccountCard(user),
            const SizedBox(height: 16),
            _buildPremiumCard(isPremium),
            const SizedBox(height: 16),
            _buildDeleteCard(),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('エラー: $error')),
      ),
    );
  }

  Widget _buildAccountCard(User? user) {
    final isGoogleLinked =
        user?.providerData.any((p) => p.providerId == 'google.com') ?? false;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.blue[50],
                  backgroundImage:
                      user?.photoURL != null ? NetworkImage(user!.photoURL!) : null,
                  child: user?.photoURL == null
                      ? Icon(Icons.person, color: Colors.blue[700], size: 28)
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isGoogleLinked
                            ? (user?.displayName ?? 'Googleアカウント')
                            : 'ゲストとして利用中',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      if (isGoogleLinked && user?.email != null)
                        Text(
                          user!.email!,
                          style: TextStyle(color: Colors.grey[600], fontSize: 13),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (!isGoogleLinked) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'ゲストデータは端末に紐づいています。機種変更やアプリの再インストールに備えて、'
                  'Googleアカウントでログインしてデータを保護しましょう。',
                  style: TextStyle(color: Colors.orange[900], fontSize: 12, height: 1.4),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _processing ? null : _signInWithGoogle,
                  icon: _processing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.login),
                  label: const Text('Googleでログイン'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ] else
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _processing ? null : _signOut,
                  icon: const Icon(Icons.logout),
                  label: const Text('ログアウト'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumCard(bool isPremium) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.workspace_premium,
                  color: isPremium ? Colors.amber[700] : Colors.grey,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    isPremium ? 'プレミアム会員です' : '無料プランを利用中',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (!isPremium)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PaywallPage()),
                    );
                  },
                  icon: const Icon(Icons.upgrade),
                  label: const Text('プレミアムにアップグレード'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber[700],
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              )
            else
              Text(
                'すべての機能を制限なくご利用いただけます。ありがとうございます！',
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
          ],
        ),
      ),
    );
  }
}
