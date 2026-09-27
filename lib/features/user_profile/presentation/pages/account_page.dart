import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
