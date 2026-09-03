import 'package:flutter/material.dart';

/// チュートリアル動画プレイヤーウィジェット
class TutorialVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final String title;
  final int durationSeconds;
  final VoidCallback? onClose;
  final VoidCallback? onComplete;

  const TutorialVideoPlayer({
    Key? key,
    required this.videoUrl,
    required this.title,
    required this.durationSeconds,
    this.onClose,
    this.onComplete,
  }) : super(key: key);

  @override
  State<TutorialVideoPlayer> createState() => _TutorialVideoPlayerState();
}

class _TutorialVideoPlayerState extends State<TutorialVideoPlayer> {
  late double _currentPosition = 0;
  bool _isPlaying = false;
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    // 実装時に動画プレイヤーライブラリ（例：video_player）を統合
    _isPlaying = true;
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      color: Colors.black,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ビデオプレイヤーコンテナ
          Container(
            color: Colors.black,
            width: double.infinity,
            height: 280,
            child: Stack(
              children: [
                // ビデオプレースホルダー
                Center(
                  child: Container(
                    color: Colors.grey[900],
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _isPlaying ? Icons.pause_circle : Icons.play_circle,
                          color: Colors.white,
                          size: 64,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          widget.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                // プログレスバー
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Column(
                    children: [
                      Slider(
                        value: _currentPosition,
                        max: widget.durationSeconds.toDouble(),
                        onChanged: (value) {
                          setState(() => _currentPosition = value);
                        },
                        activeColor: Colors.red,
                        inactiveColor: Colors.grey[700],
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatDuration(_currentPosition.toInt()),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              _formatDuration(widget.durationSeconds),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // 閉じるボタン
                Positioned(
                  top: 8,
                  right: 8,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () {
                      widget.onClose?.call();
                      Navigator.pop(context);
                    },
                  ),
                ),
              ],
            ),
          ),
          // 再生コントロール
          Container(
            color: Colors.black87,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '時間: ${_formatDuration(widget.durationSeconds)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey[400],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // 再生・一時停止ボタン
                    FloatingActionButton(
                      mini: true,
                      backgroundColor: Colors.red,
                      onPressed: () {
                        setState(() => _isPlaying = !_isPlaying);
                      },
                      child: Icon(
                        _isPlaying ? Icons.pause : Icons.play_arrow,
                        color: Colors.white,
                      ),
                    ),
                    // スキップバック
                    FloatingActionButton(
                      mini: true,
                      backgroundColor: Colors.grey[700],
                      onPressed: () {
                        setState(() {
                          _currentPosition =
                              (_currentPosition - 10).clamp(0, widget.durationSeconds.toDouble());
                        });
                      },
                      child: const Icon(
                        Icons.replay_10,
                        color: Colors.white,
                      ),
                    ),
                    // スキップ
                    FloatingActionButton(
                      mini: true,
                      backgroundColor: Colors.grey[700],
                      onPressed: () {
                        setState(() {
                          _currentPosition =
                              (_currentPosition + 10).clamp(0, widget.durationSeconds.toDouble());
                        });
                      },
                      child: const Icon(
                        Icons.forward_10,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      widget.onComplete?.call();
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    child: const Text(
                      'チュートリアルを終了',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
