import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';

/// アプリについて・免責事項・監修情報をいつでも確認できるページ。
/// オンボーディング時にしか表示されない免責事項を、アプリ利用中も
/// 参照できるようにするための恒常的な導線。
class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('このアプリについて')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppConstants.appName,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'バージョン ${AppConstants.appVersion}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            _buildSection(
              '📌 監修について',
              '本アプリは一般的な金融リテラシー教育を目的として制作されています。'
                  '現時点で専門家による個別監修は行っておらず、内容は公開情報・公的機関の '
                  '情報を基にした一般的な参考情報です。具体的な税務・法律・投資の判断は、'
                  '税理士・弁護士・ファイナンシャルプランナー等の専門家にご相談ください。',
            ),
            const SizedBox(height: 20),
            _buildSection(
              '📌 教育目的について',
              'このアプリのすべてのコンテンツ・シミュレーション・診断は教育目的です。'
                  '実際の投資成果を保証するものではありません。',
            ),
            const SizedBox(height: 20),
            _buildSection(
              '📌 投資シミュレーションについて',
              '実売買機能はありません。過去実績に基づく教育的シミュレーションであり、'
                  '実際の投資は専門家にご相談ください。',
            ),
            const SizedBox(height: 20),
            _buildSection(
              '📌 制度・補助金情報について',
              'アプリ内で紹介する公的制度・補助金・控除の情報は一般的な参考情報です。'
                  '金額・対象要件・申請方法は法改正等で変更される場合があるため、実際に '
                  '利用する際は必ずアプリ内に記載の窓口（市区町村・税務署・年金事務所等）で '
                  '最新情報をご確認ください。',
            ),
            const SizedBox(height: 20),
            _buildSection(
              '📌 個人情報について',
              '入力された家計情報は暗号化され、あなたのデバイスに安全に保存されます。'
                  '外部サーバーには個人を特定する情報は送信されません。',
            ),
            const SizedBox(height: 32),
            Container(
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                border: Border.all(color: Colors.orange.shade200),
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.all(12),
              child: const Text(
                '本アプリの情報だけで投資・保険・税務等の最終判断を行わず、必ず公式窓口・専門家にご確認ください。',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String body) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.deepOrange,
          ),
        ),
        const SizedBox(height: 8),
        Text(body, style: const TextStyle(fontSize: 12, height: 1.6)),
      ],
    );
  }
}
