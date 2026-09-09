import 'package:flutter/material.dart';
import 'package:shared_core/widgets/components/app_card.dart';
import 'package:shared_core/widgets/components/app_button.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/feedback_report.dart';
import '../../providers/feedback_provider.dart';

/// 「バグ報告・ご意見」フォーム画面。
/// 種別選択・タイトル・詳細を入力して Firestore の `feedback` コレクションへ送信する。
class FeedbackFormScreen extends ConsumerStatefulWidget {
  const FeedbackFormScreen({super.key});

  @override
  ConsumerState<FeedbackFormScreen> createState() => _FeedbackFormScreenState();
}

class _FeedbackFormScreenState extends ConsumerState<FeedbackFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  FeedbackType _type = FeedbackType.bug;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    await ref.read(feedbackProvider.notifier).submitFeedback(
          type: _type,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
        );

    if (!mounted) return;
    final result = ref.read(feedbackProvider);

    if (result.status == FeedbackSubmitStatus.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('送信しました。ありがとうございます！')),
      );
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('送信に失敗しました。時間をおいて再度お試しください。')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final submitState = ref.watch(feedbackProvider);
    final isSubmitting = submitState.status == FeedbackSubmitStatus.submitting;

    return Scaffold(
      appBar: AppBar(
        title: const Text('バグ報告・ご意見'),
        elevation: 0,
        backgroundColor: const Color(0xFF9B59B6),
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              '種別',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF2C2C2C)),
            ),
            const SizedBox(height: 8),
            SegmentedButton<FeedbackType>(
              segments: const [
                ButtonSegment(value: FeedbackType.bug, label: Text('不具合報告')),
                ButtonSegment(value: FeedbackType.feature, label: Text('改善要望')),
                ButtonSegment(value: FeedbackType.other, label: Text('その他')),
              ],
              selected: {_type},
              onSelectionChanged: isSubmitting
                  ? null
                  : (selection) => setState(() => _type = selection.first),
            ),
            const SizedBox(height: 20),
            const Text(
              'タイトル',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF2C2C2C)),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _titleController,
              enabled: !isSubmitting,
              decoration: const InputDecoration(
                hintText: '例：〇〇画面でボタンが反応しない',
                border: OutlineInputBorder(),
              ),
              validator: (value) =>
                  (value == null || value.trim().isEmpty) ? 'タイトルを入力してください' : null,
            ),
            const SizedBox(height: 20),
            const Text(
              '詳細',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF2C2C2C)),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descriptionController,
              enabled: !isSubmitting,
              minLines: 5,
              maxLines: 10,
              decoration: const InputDecoration(
                hintText: 'できるだけ詳しく状況を教えてください',
                border: OutlineInputBorder(),
              ),
              validator: (value) =>
                  (value == null || value.trim().isEmpty) ? '詳細を入力してください' : null,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: AppButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF9B59B6),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: isSubmitting ? null : _submit,
                child: isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('送信する'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
