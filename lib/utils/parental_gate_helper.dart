import 'package:flutter/material.dart';

import '../widgets/parental_gate_dialog.dart';

/// [ParentalGateDialog] を表示し、正解した場合のみ `true` を返すヘルパー。
///
/// 課金操作（購入・サブスクリプション解約）や全データ削除など、保護者の
/// 確認が必要な操作の前に呼び出す。キャンセル・不正解・ダイアログを
/// 閉じた場合は `false`。
///
/// 使い方:
/// ```dart
/// Future<void> _buyMonthly() async {
///   final passedGate = await requireParentalGate(context);
///   if (!passedGate || !context.mounted) return;
///   // 実際の購入処理へ
/// }
/// ```
Future<bool> requireParentalGate(
  BuildContext context, {
  String? title,
  String? description,
  String? okLabel,
  String? cancelLabel,
  Color? primaryColor,
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => ParentalGateDialog(
      title: title,
      description: description,
      okLabel: okLabel,
      cancelLabel: cancelLabel,
      primaryColor: primaryColor,
    ),
  );
  return result ?? false;
}
