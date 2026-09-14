import 'package:flutter/material.dart';
import '../../domain/models/household_balance_sheet.dart';

/// 詳細バランスシートカード - 資産・負債・純資産の詳細を表示
class DetailedBalanceSheetCard extends StatefulWidget {
  final HouseholdBalanceSheet sheet;

  const DetailedBalanceSheetCard({
    Key? key,
    required this.sheet,
  }) : super(key: key);

  @override
  State<DetailedBalanceSheetCard> createState() =>
      _DetailedBalanceSheetCardState();
}

class _DetailedBalanceSheetCardState extends State<DetailedBalanceSheetCard> {
  bool _expandAssets = true;
  bool _expandLiabilities = false;

  @override
  Widget build(BuildContext context) {
    final netWorthColor = widget.sheet.netWorth >= 0 ? Colors.green : Colors.red;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ヘッダー
            const Text(
              '📊 詳細バランスシート',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),

            // 純資産サマリー
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: netWorthColor.withValues(alpha: 0.1),
                border: Border.all(
                  color: netWorthColor.withValues(alpha: 0.3),
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '純資産',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '¥${widget.sheet.netWorth}',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: netWorthColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 資産セクション
            _ExpandableSection(
              title: '資産',
              icon: '💰',
              isExpanded: _expandAssets,
              onTap: () {
                setState(() {
                  _expandAssets = !_expandAssets;
                });
              },
              amount: widget.sheet.totalAssets,
              children: [
                _AssetRow(
                  label: '貯金口座',
                  amount: widget.sheet.savingsAccount,
                  icon: '🏦',
                  percentage: widget.sheet.totalAssets > 0
                      ? (widget.sheet.savingsAccount / widget.sheet.totalAssets) * 100
                      : 0.0,
                ),
                _AssetRow(
                  label: '当座預金',
                  amount: widget.sheet.checkingAccount,
                  icon: '💳',
                  percentage: widget.sheet.totalAssets > 0
                      ? (widget.sheet.checkingAccount / widget.sheet.totalAssets) * 100
                      : 0.0,
                ),
                _AssetRow(
                  label: '投資資産',
                  amount: widget.sheet.investmentsValue,
                  icon: '📈',
                  percentage: widget.sheet.totalAssets > 0
                      ? (widget.sheet.investmentsValue / widget.sheet.totalAssets) * 100
                      : 0.0,
                ),
                _AssetRow(
                  label: 'その他資産',
                  amount: widget.sheet.otherAssets,
                  icon: '📦',
                  percentage: widget.sheet.totalAssets > 0
                      ? (widget.sheet.otherAssets / widget.sheet.totalAssets) * 100
                      : 0.0,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 負債セクション
            _ExpandableSection(
              title: '負債',
              icon: '💳',
              isExpanded: _expandLiabilities,
              onTap: () {
                setState(() {
                  _expandLiabilities = !_expandLiabilities;
                });
              },
              amount: widget.sheet.totalLiabilities,
              children: [
                _LiabilityRow(
                  label: '短期債務',
                  amount: widget.sheet.shortTermDebt,
                  icon: '⏰',
                ),
                _LiabilityRow(
                  label: '長期債務',
                  amount: widget.sheet.longTermDebt,
                  icon: '📅',
                ),
                _LiabilityRow(
                  label: 'その他負債',
                  amount: widget.sheet.otherLiabilities,
                  icon: '📋',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 拡張可能なセクション
class _ExpandableSection extends StatelessWidget {
  final String title;
  final String icon;
  final bool isExpanded;
  final VoidCallback onTap;
  final int amount;
  final List<Widget> children;

  const _ExpandableSection({
    required this.title,
    required this.icon,
    required this.isExpanded,
    required this.onTap,
    required this.amount,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(icon, style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 8),
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Text(
                      '¥$amount',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      isExpanded ? Icons.expand_less : Icons.expand_more,
                      size: 20,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (isExpanded)
          Padding(
            padding: const EdgeInsets.only(top: 12, left: 12, right: 12),
            child: Column(
              children: children,
            ),
          ),
      ],
    );
  }
}

/// 資産行
class _AssetRow extends StatelessWidget {
  final String label;
  final int amount;
  final String icon;
  final double percentage;

  const _AssetRow({
    required this.label,
    required this.amount,
    required this.icon,
    required this.percentage,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(icon, style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Text(label),
                ],
              ),
              Text(
                '¥$amount',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: percentage / 100,
            minHeight: 4,
            backgroundColor: Colors.grey[200],
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
          ),
          const SizedBox(height: 4),
          Text(
            '${percentage.toStringAsFixed(1)}%',
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

/// 負債行
class _LiabilityRow extends StatelessWidget {
  final String label;
  final int amount;
  final String icon;

  const _LiabilityRow({
    required this.label,
    required this.amount,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Text(label),
            ],
          ),
          Text(
            '¥$amount',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
        ],
      ),
    );
  }
}
