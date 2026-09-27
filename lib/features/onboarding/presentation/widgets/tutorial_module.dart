import 'package:flutter/material.dart';

/// ステップの解説（テキスト）表示ウィジェット
class TutorialModule extends StatefulWidget {
  final String explanationTitle;
  final String explanationText;
  final String stepDescription;
  final String stepEmoji;
  final VoidCallback onRead;

  const TutorialModule({
    Key? key,
    required this.explanationTitle,
    required this.explanationText,
    required this.stepDescription,
    required this.stepEmoji,
    required this.onRead,
  }) : super(key: key);

  @override
  State<TutorialModule> createState() => _TutorialModuleState();
}

class _TutorialModuleState extends State<TutorialModule> {
  bool _read = false;

  void _markAsRead() {
    setState(() => _read = true);
    widget.onRead();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ステップ説明
        Row(
          children: [
            Text(
              widget.stepEmoji,
              style: const TextStyle(fontSize: 32),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.stepDescription,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[700],
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // 解説カード
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.blue[50],
            border: Border.all(color: Colors.blue[200]!),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.menu_book, color: Colors.blue[700], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.explanationTitle,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700],
                        ),
                      ),
                    ),
                    if (_read)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: Colors.green[700],
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '既読',
                              style: TextStyle(
                                color: Colors.green[700],
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  widget.explanationText,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey[800],
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // アクションボタン
        if (!_read)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _markAsRead,
              icon: const Icon(Icons.check),
              label: const Text('読み終えた'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          )
        else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green[50],
              border: Border.all(color: Colors.green[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green[700], size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '解説を確認しました。次のステップに進む準備ができています！',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.green[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
