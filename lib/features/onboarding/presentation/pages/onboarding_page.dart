import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../home/presentation/pages/home_page.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import 'first_month_guide_page.dart';

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({Key? key}) : super(key: key);

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() => _currentPage = index);
        },
        children: [
          _buildWelcomePage(),
          _buildEducationPage(),
          _buildDisclaimerPage(),
        ],
      ),
    );
  }

  Widget _buildWelcomePage() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade300, Colors.blue.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.savings, size: 80, color: Colors.white),
            const SizedBox(height: 24),
            const Text(
              '金融オンライン大学',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              '楽しく学ぶ家計管理アプリ',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 48),
            ElevatedButton.icon(
              onPressed: () => _pageController.nextPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              ),
              icon: const Icon(Icons.arrow_forward),
              label: const Text('はじめる'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEducationPage() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.amber.shade300, Colors.amber.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.school, size: 80, color: Colors.white),
            const SizedBox(height: 24),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  Text(
                    '学習目的のアプリです',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'このアプリは金融知識を学ぶための教育目的ツールです。実際の投資・取引機能はありません。',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                      height: 1.6,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 24),
                  Text(
                    '✓ 家計管理の基礎を学べる\n✓ 節約のコツを診断\n✓ 仮想シミュレーションで実践',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white,
                      height: 1.8,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),
            ElevatedButton.icon(
              onPressed: () => _pageController.nextPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              ),
              icon: const Icon(Icons.arrow_forward),
              label: const Text('利用規約を確認'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDisclaimerPage() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '利用規約 & 免責事項',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              '📌 教育目的について',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryOrange,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'このアプリのすべてのコンテンツ・シミュレーション・診断は教育目的です。実際の投資成果を保証するものではありません。',
              style: TextStyle(fontSize: 12, height: 1.6),
            ),
            const SizedBox(height: 24),
            const Text(
              '📌 投資シミュレーションについて',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryOrange,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '• 実売買機能はありません\n• 過去実績に基づく教育的シミュレーションです\n• 実際の投資は専門家にご相談ください',
              style: TextStyle(fontSize: 12, height: 1.6),
            ),
            const SizedBox(height: 24),
            const Text(
              '📌 制度・補助金情報について',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryOrange,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'アプリ内で紹介する公的制度・補助金・控除の情報は一般的な参考情報です。金額・対象要件・申請方法は法改正等で変更される場合があるため、実際に利用する際は必ず記載の窓口（市区町村・税務署・年金事務所等）で最新情報をご確認ください。個別の税務・法律・投資判断については専門家にご相談ください。',
              style: TextStyle(fontSize: 12, height: 1.6),
            ),
            const SizedBox(height: 24),
            const Text(
              '📌 個人情報について',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryOrange,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '入力された家計情報は、匿名のアカウントID（氏名・メールアドレス等は取得しません）に紐づけて安全なクラウドサーバーに保存され、複数端末間の同期や「世帯」機能での共有に利用されます。氏名・住所・電話番号など、個人を直接特定できる情報の取得・送信は行いません。',
              style: TextStyle(fontSize: 12, height: 1.6),
            ),
            const SizedBox(height: 32),
            Container(
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                border: Border.all(color: Colors.orange.shade200),
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.all(12),
              child: Text(
                '上記の内容に同意します。',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.orange.shade900,
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const FirstMonthGuidePage(),
                    ),
                  );
                },
                icon: const Icon(Icons.school),
                label: const Text('最初の1ヶ月ガイドを見る'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.blue,
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool('onboarding_completed', true);
                  if (mounted) {
                    Navigator.pushReplacement(
                      context,
                      PageRouteAnimations.fadeTransition(const HomePage()),
                    );
                  }
                },
                icon: const Icon(Icons.check),
                label: const Text('同意して開始'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
