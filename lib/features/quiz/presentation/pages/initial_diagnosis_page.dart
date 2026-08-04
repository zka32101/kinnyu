import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/pattern_diagnosis.dart';
import '../../domain/models/diagnosis_question.dart';
import '../pages/diagnosis_result_page.dart';

class InitialDiagnosisPage extends ConsumerWidget {
  const InitialDiagnosisPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('家計診断クイズ')),
      body: const _DiagnosisFlow(),
    );
  }
}

class _DiagnosisFlow extends ConsumerStatefulWidget {
  const _DiagnosisFlow({Key? key}) : super(key: key);

  @override
  ConsumerState<_DiagnosisFlow> createState() => _DiagnosisFlowState();
}

class _DiagnosisFlowState extends ConsumerState<_DiagnosisFlow> {
  final questions = DiagnosisQuestions.questions;
  late List<int?> answers;
  int currentIndex = 0;

  @override
  void initState() {
    super.initState();
    answers = List.filled(questions.length, null);
  }

  @override
  Widget build(BuildContext context) {
    if (currentIndex >= questions.length) {
      final diagnosis = _generateDiagnosis();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => DiagnosisResultPage(diagnosis: diagnosis),
          ),
        );
      });
      return const Center(child: CircularProgressIndicator());
    }

    final question = questions[currentIndex];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LinearProgressIndicator(
            value: (currentIndex + 1) / questions.length,
          ),
          const SizedBox(height: 24),
          Text(
            '質問 ${currentIndex + 1} / ${questions.length}',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 8),
          Text(
            question.question,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 24),
          ...List.generate(
            question.options.length,
            (index) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    answers[currentIndex] = index;
                    currentIndex++;
                  });
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  alignment: Alignment.centerLeft,
                ),
                child: Text(
                  question.options[index],
                  style: const TextStyle(fontSize: 15),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  PatternDiagnosis _generateDiagnosis() {
    final patternId = answers.map((a) => (a ?? 0).toString()).join('_');
    return PatternDiagnosisGenerator.getDiagnosis(patternId);
  }
}
