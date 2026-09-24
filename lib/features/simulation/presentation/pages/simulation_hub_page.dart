import 'package:flutter/material.dart';
import 'household_simulator_page.dart';
import 'investment_simulator_page.dart';
import 'loan_repayment_simulator_page.dart';
import 'take_home_pay_page.dart';
import 'furusato_nozei_page.dart';
import 'nisa_ideco_page.dart';
import 'emergency_fund_page.dart';
import 'insurance_coverage_page.dart';
import 'rent_vs_buy_page.dart';
import 'education_cost_page.dart';
import 'pension_estimator_page.dart';
import '../../../payslip/presentation/pages/payslip_capture_page.dart';
import '../../../life_plan/presentation/pages/life_plan_timeline_page.dart';

class _SimulatorEntry {
  final IconData icon;
  final Color color;
  final String title;
  final String description;
  final WidgetBuilder pageBuilder;

  const _SimulatorEntry({
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
    required this.pageBuilder,
  });
}

class SimulationHubPage extends StatelessWidget {
  const SimulationHubPage({Key? key}) : super(key: key);

  static final Map<String, List<_SimulatorEntry>> _sections = {
    '全体を見る': [
      _SimulatorEntry(
        icon: Icons.timeline,
        color: Colors.deepPurple,
        title: 'ライフプランタイムライン',
        description: '教育費・退職・年金など、人生のお金の出来事を年齢順に一覧表示',
        pageBuilder: (_) => const LifePlanTimelinePage(),
      ),
      _SimulatorEntry(
        icon: Icons.home_work,
        color: Colors.indigo,
        title: '家計シミュレーション',
        description: '収入と支出から、毎月の貯蓄額と将来の資産を計算',
        pageBuilder: (_) => const HouseholdSimulatorPage(),
      ),
    ],
    '税金・給与': [
      _SimulatorEntry(
        icon: Icons.payments,
        color: Colors.teal,
        title: '手取り額シミュレーション',
        description: '額面年収から税金・社会保険料を差し引いた手取り額を計算',
        pageBuilder: (_) => const TakeHomePayPage(),
      ),
      _SimulatorEntry(
        icon: Icons.document_scanner,
        color: Colors.cyan,
        title: '給与明細OCR',
        description: '給与明細を撮影するだけで、総支給額・手取り額を自動読み取り',
        pageBuilder: (_) => const PayslipCapturePage(),
      ),
      _SimulatorEntry(
        icon: Icons.volunteer_activism,
        color: Colors.red,
        title: 'ふるさと納税 控除上限額',
        description: '年収・家族構成から、実質2,000円で寄付できる上限額を計算',
        pageBuilder: (_) => const FurusatoNozeiPage(),
      ),
      _SimulatorEntry(
        icon: Icons.account_balance,
        color: Colors.purple,
        title: 'NISA・iDeCo枠管理',
        description: '非課税投資枠の残り枠と、iDeCoの節税効果を計算',
        pageBuilder: (_) => const NisaIdecoPage(),
      ),
    ],
    '住まい・借入': [
      _SimulatorEntry(
        icon: Icons.compare_arrows,
        color: Colors.brown,
        title: '住宅購入 vs 賃貸',
        description: '家賃と住宅ローンを比較し、何年で購入が有利になるかを計算',
        pageBuilder: (_) => const RentVsBuyPage(),
      ),
      _SimulatorEntry(
        icon: Icons.request_quote,
        color: Colors.deepOrange,
        title: '借入返済シミュレーション',
        description: '住宅ローンなどの返済額・総利息・残高の推移を計算',
        pageBuilder: (_) => const LoanRepaymentSimulatorPage(),
      ),
    ],
    '将来に備える': [
      _SimulatorEntry(
        icon: Icons.trending_up,
        color: Colors.green,
        title: '積立投資シミュレーション',
        description: '毎月の積立額と投資先から、将来の資産を計算',
        pageBuilder: (_) => const InvestmentSimulatorPage(),
      ),
      _SimulatorEntry(
        icon: Icons.shield,
        color: Colors.blueGrey,
        title: '生活防衛資金プランナー',
        description: '目標の貯蓄額と、現在のペースでの達成時期を計算',
        pageBuilder: (_) => const EmergencyFundPage(),
      ),
      _SimulatorEntry(
        icon: Icons.health_and_safety,
        color: Colors.pink,
        title: '必要保障額シミュレーション',
        description: '万一の場合に遺族の生活を支える、必要な保険金額を計算',
        pageBuilder: (_) => const InsuranceCoveragePage(),
      ),
      _SimulatorEntry(
        icon: Icons.school,
        color: Colors.lightBlue,
        title: '教育費プランナー',
        description: '進路（公立/私立）別に、必要な教育費総額と積立目安を計算',
        pageBuilder: (_) => const EducationCostPage(),
      ),
      _SimulatorEntry(
        icon: Icons.elderly,
        color: Colors.indigo,
        title: '年金・退職金シミュレーション',
        description: '将来の年金受給見込み額と退職金の概算を計算',
        pageBuilder: (_) => const PensionEstimatorPage(),
      ),
    ],
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('シミュレーション')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            '数字を入れるだけで、将来のお金をシミュレーションできます。',
            style: TextStyle(fontSize: 13, color: Colors.grey),
          ),
          const SizedBox(height: 20),
          for (final section in _sections.entries) ...[
            _buildSectionHeader(section.key),
            const SizedBox(height: 8),
            for (final entry in section.value) ...[
              _buildCard(
                context,
                icon: entry.icon,
                color: entry.color,
                title: entry.title,
                description: entry.description,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: entry.pageBuilder),
                ),
              ),
              const SizedBox(height: 12),
            ],
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.bold,
        color: Colors.grey.shade600,
      ),
    );
  }

  Widget _buildCard(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withAlpha(30),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 4),
                    Text(description,
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
