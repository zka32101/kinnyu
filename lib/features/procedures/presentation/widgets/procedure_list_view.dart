import 'package:flutter/material.dart';
import '../../domain/models/procedure_info.dart';

/// カテゴリ選択チップ＋詳細展開リストで制度・手続きを表示する再利用可能なウィジェット。
///
/// [controller] を渡すとスクロール可能な親（DraggableScrollableSheet 等）に
/// 組み込む用途になり、渡さない場合は shrinkWrap でページ内に埋め込める。
class ProcedureListView extends StatefulWidget {
  final List<ProcedureInfo> procedures;
  final ScrollController? controller;

  /// 各制度の詳細が展開されたときに呼ばれる（閲覧済みトラッキング等に利用）
  final void Function(ProcedureInfo procedure)? onExpand;

  /// 無料ユーザーに表示する件数の上限。null の場合は無制限。
  final int? freeLimit;

  /// 上限を超えた際に表示するロック解除ボタンのタップハンドラ
  final VoidCallback? onUnlockTap;

  const ProcedureListView({
    super.key,
    required this.procedures,
    this.controller,
    this.onExpand,
    this.freeLimit,
    this.onUnlockTap,
  });

  @override
  State<ProcedureListView> createState() => _ProcedureListViewState();
}

class _ProcedureListViewState extends State<ProcedureListView> {
  ProcedureCategory? _selectedCategory;

  @override
  void didUpdateWidget(covariant ProcedureListView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // widget.procedures が新しいリストに差し替わった際、選択中のカテゴリが
    // 新リストに存在しないカテゴリのまま残ると、絞り込み結果が無言で
    // 空リストになってしまうため、その場合はリセットする。
    if (_selectedCategory != null &&
        !widget.procedures.any((p) => p.category == _selectedCategory)) {
      _selectedCategory = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = widget.procedures.map((p) => p.category).toSet().toList()
      ..sort((a, b) => a.label.compareTo(b.label));
    final filtered = _selectedCategory == null
        ? widget.procedures
        : widget.procedures.where((p) => p.category == _selectedCategory).toList();

    final hasLimit = widget.freeLimit != null && filtered.length > widget.freeLimit!;
    final visible = hasLimit ? filtered.take(widget.freeLimit!).toList() : filtered;
    final lockedCount = hasLimit ? filtered.length - visible.length : 0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (categories.length > 1)
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: const Text('すべて'),
                    selected: _selectedCategory == null,
                    onSelected: (_) => setState(() => _selectedCategory = null),
                  ),
                ),
                ...categories.map((c) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ChoiceChip(
                        avatar: Icon(c.icon, size: 16, color: c.color),
                        label: Text(c.label),
                        selected: _selectedCategory == c,
                        onSelected: (_) => setState(() => _selectedCategory = c),
                      ),
                    )),
              ],
            ),
          ),
        const SizedBox(height: 8),
        ListView.builder(
          controller: widget.controller,
          shrinkWrap: widget.controller == null,
          physics: widget.controller == null
              ? const NeverScrollableScrollPhysics()
              : null,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          itemCount: visible.length + (lockedCount > 0 ? 1 : 0),
          itemBuilder: (context, index) {
            if (index >= visible.length) {
              return _buildLockedTeaser(context, lockedCount);
            }
            final p = visible[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ExpansionTile(
                onExpansionChanged: (expanded) {
                  if (expanded) widget.onExpand?.call(p);
                },
                leading: CircleAvatar(
                  backgroundColor: p.category.color.withAlpha(30),
                  child: Icon(p.category.icon, color: p.category.color, size: 20),
                ),
                title: Text(
                  p.title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                subtitle: Text(
                  p.category.label,
                  style: TextStyle(fontSize: 11, color: p.category.color),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _detailRow('概要', p.summary),
                        _detailRow('対象者', p.eligibility),
                        _detailRow('金額の目安', p.benefitAmount),
                        _detailRow('申請方法', p.howToApply),
                        _detailRow('タイミング', p.applyWindow),
                        _detailRow('相談・申請先', p.sourceNote),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildLockedTeaser(BuildContext context, int lockedCount) {
    return Card(
      color: Colors.amber.shade50,
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: widget.onUnlockTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.lock, color: Colors.amber.shade800),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'あと$lockedCount件の制度はプレミアムで閲覧できます',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Colors.amber.shade900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'タップしてプレミアムの詳細を見る',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward, color: Colors.amber.shade800),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }
}

/// カテゴリ選択チップで絞り込める、制度・手続き一覧のボトムシートを表示する。
void showProcedureListSheet(
  BuildContext context, {
  required String title,
  required List<ProcedureInfo> procedures,
  void Function(ProcedureInfo procedure)? onExpand,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) {
      return DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '制度の内容・金額は変更される場合があります。利用の際は記載の窓口で最新情報をご確認ください。',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ProcedureListView(
                  procedures: procedures,
                  controller: scrollController,
                  onExpand: onExpand,
                ),
              ),
            ],
          );
        },
      );
    },
  );
}
