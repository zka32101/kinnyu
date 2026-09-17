import 'package:flutter/material.dart';
import '../../domain/models/financial_insight.dart';

/// インサイトを表示するカードウィジェット
class InsightCard extends StatefulWidget {
  final FinancialInsight insight;
  final String contextMessage;
  final VoidCallback? onDismiss;
  final VoidCallback? onViewDetails;

  const InsightCard({
    Key? key,
    required this.insight,
    required this.contextMessage,
    this.onDismiss,
    this.onViewDetails,
  }) : super(key: key);

  @override
  State<InsightCard> createState() => _InsightCardState();
}

class _InsightCardState extends State<InsightCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row: Icon, Title, Priority Pill
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon based on insight type
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: _buildInsightIcon(),
                ),
                // Title and Message
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.insight.title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.contextMessage,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                              height: 1.4,
                            ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // Priority Pill
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: _buildPriorityPill(context),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Impact Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: Colors.green.withOpacity(0.3),
                  width: 0.5,
                ),
              ),
              child: Text(
                '+${widget.insight.scoreImpact} points possible',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.green[700],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Expandable Action Items
            if (widget.insight.actionableItems.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () => setState(() => _isExpanded = !_isExpanded),
                    child: Row(
                      children: [
                        Text(
                          'Action Steps',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const Spacer(),
                        Icon(
                          _isExpanded ? Icons.expand_less : Icons.expand_more,
                          size: 20,
                          color: Colors.grey,
                        ),
                      ],
                    ),
                  ),
                  if (_isExpanded) ...[
                    const SizedBox(height: 8),
                    ..._buildActionItems(),
                  ],
                  const SizedBox(height: 12),
                ],
              ),
            // Action Buttons
            Row(
              children: [
                if (widget.onDismiss != null)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: widget.onDismiss,
                      icon: const Icon(Icons.close),
                      label: const Text('Dismiss'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                if (widget.onDismiss != null && widget.onViewDetails != null)
                  const SizedBox(width: 8),
                if (widget.onViewDetails != null)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: widget.onViewDetails,
                      icon: const Icon(Icons.arrow_forward),
                      label: const Text('Learn More'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightIcon() {
    IconData iconData;
    Color iconColor;

    switch (widget.insight.type) {
      case InsightType.anomaly:
        iconData = Icons.warning_rounded;
        iconColor = Colors.orange;
        break;
      case InsightType.recommendation:
        iconData = Icons.lightbulb_rounded;
        iconColor = Colors.blue;
        break;
      case InsightType.milestone:
        iconData = Icons.celebration;
        iconColor = Colors.green;
        break;
      case InsightType.trend:
        iconData = Icons.trending_up;
        iconColor = Colors.teal;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(iconData, color: iconColor, size: 24),
    );
  }

  Widget _buildPriorityPill(BuildContext context) {
    final priorityColors = [
      Colors.red,      // Priority 1 (highest)
      Colors.orange,   // Priority 2
      Colors.amber,    // Priority 3 (lowest)
    ];

    final color = priorityColors[
        (widget.insight.priority - 1).clamp(0, priorityColors.length - 1)
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        'P${widget.insight.priority}',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  List<Widget> _buildActionItems() {
    return widget.insight.actionableItems.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                item,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      height: 1.4,
                    ),
              ),
            ),
          ],
        );
      );
    }).toList();
  }
}
