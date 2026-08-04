import 'package:flutter/material.dart';
import '../../domain/models/glossary_term.dart';

class GlossaryPage extends StatefulWidget {
  const GlossaryPage({Key? key}) : super(key: key);

  @override
  State<GlossaryPage> createState() => _GlossaryPageState();
}

class _GlossaryPageState extends State<GlossaryPage> {
  String _keyword = '';
  GlossaryCategory? _categoryFilter;

  List<GlossaryTerm> get _filtered {
    var list = GlossaryData.search(_keyword);
    if (_categoryFilter != null) {
      list = list.where((t) => t.category == _categoryFilter).toList();
    }
    return list;
  }

  Color _categoryColor(GlossaryCategory c) {
    switch (c) {
      case GlossaryCategory.savings:
        return Colors.blue;
      case GlossaryCategory.tax:
        return Colors.orange;
      case GlossaryCategory.invest:
        return Colors.green;
      case GlossaryCategory.insurance:
        return Colors.red;
      case GlossaryCategory.general:
        return Colors.purple;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;

    return Scaffold(
      appBar: AppBar(title: const Text('お金の用語辞典')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: InputDecoration(
                hintText: '用語を検索（例: 複利、NISA）',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                isDense: true,
              ),
              onChanged: (v) => setState(() => _keyword = v),
            ),
          ),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _buildFilterChip('すべて', null),
                ...GlossaryCategory.values.map(
                  (c) => _buildFilterChip(
                    GlossaryCategoryInfo.displayNames[c]!,
                    c,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: filtered.isEmpty
                ? const Center(
                    child: Text('該当する用語がありません',
                        style: TextStyle(color: Colors.grey)),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final t = filtered[index];
                      return _buildTermCard(t);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, GlossaryCategory? category) {
    final selected = _categoryFilter == category;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => setState(() => _categoryFilter = category),
      ),
    );
  }

  Widget _buildTermCard(GlossaryTerm t) {
    final color = _categoryColor(t.category);
    return Card(
      margin: EdgeInsets.zero,
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: color.withAlpha(30),
          child: Text(
            GlossaryCategoryInfo.displayNames[t.category]!.substring(0, 1),
            style: TextStyle(
                color: color, fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ),
        title: Text(
          t.term,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(t.reading,
            style: const TextStyle(fontSize: 12, color: Colors.grey)),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t.definition, style: const TextStyle(fontSize: 14, height: 1.5)),
          if (t.example != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withAlpha(20),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.lightbulb_outline, size: 16, color: color),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      t.example!,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
