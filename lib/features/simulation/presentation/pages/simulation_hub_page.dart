import 'package:flutter/material.dart';
import 'household_simulator_page.dart';
import 'investment_simulator_page.dart';

class SimulationHubPage extends StatelessWidget {
  const SimulationHubPage({Key? key}) : super(key: key);

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
          const SizedBox(height: 16),
          _buildCard(
            context,
            icon: Icons.home_work,
            color: Colors.indigo,
            title: '家計シミュレーション',
            description: '収入と支出から、毎月の貯蓄額と将来の資産を計算',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HouseholdSimulatorPage()),
            ),
          ),
          const SizedBox(height: 12),
          _buildCard(
            context,
            icon: Icons.trending_up,
            color: Colors.green,
            title: '積立投資シミュレーション',
            description: '毎月の積立額と投資先から、将来の資産を計算',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const InvestmentSimulatorPage()),
            ),
          ),
        ],
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
