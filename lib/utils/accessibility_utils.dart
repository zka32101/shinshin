import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// アクセシビリティ改善ユーティリティ
class AccessibilityUtils {
  /// セマンティック情報を持つボタンのラッパー
  static Widget semanticButton({
    required VoidCallback onPressed,
    required String label,
    required Widget child,
    String? hint,
    bool enabled = true,
  }) {
    return Semantics(
      button: true,
      enabled: enabled,
      onTap: enabled ? onPressed : null,
      label: label,
      hint: hint,
      child: GestureDetector(
        onTap: enabled ? onPressed : null,
        child: child,
      ),
    );
  }

  /// スクリーンリーダー向けテキストラベルを追加
  static Widget withSemanticLabel({
    required Widget child,
    required String label,
    String? hint,
  }) {
    return Semantics(
      label: label,
      hint: hint,
      child: child,
    );
  }

  /// タップ可能な領域を最小サイズにする（推奨: 48x48dp）
  static const double minimumTapSize = 48.0;

  /// タップ領域を拡張するパディング
  static const EdgeInsets tapPadding = EdgeInsets.all(8.0);

  /// コントラスト比が十分であることを確認（WCAG AA基準）
  static const double minimumContrast = 4.5;

  /// フォーカスインジケータのスタイル
  static InputBorder focusBorder([Color? color]) {
    return OutlineInputBorder(
      borderSide: BorderSide(
        color: color ?? const Color(0xFF9B59B6),
        width: 2.0,
      ),
      borderRadius: BorderRadius.circular(8.0),
    );
  }

  /// スクリーンリーダー向けのメッセージを提供
  static void announceMessage(
    BuildContext context,
    String message, {
    Duration duration = const Duration(milliseconds: 1000),
  }) {
    SemanticsService.announce(
      message,
      textDirection: TextDirection.ltr,
    );
  }

  /// コンテンツ説明テキストを自動的に追加
  static Tooltip withTooltip({
    required Widget child,
    required String message,
  }) {
    return Tooltip(
      message: message,
      child: child,
    );
  }
}

/// スクリーンリーダー対応のアイコンボタン
class AccessibleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final String semanticLabel;
  final String? tooltip;
  final Color? color;
  final double size;

  const AccessibleIconButton({
    Key? key,
    required this.icon,
    required this.onPressed,
    required this.semanticLabel,
    this.tooltip,
    this.color,
    this.size = 24.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final button = IconButton(
      icon: Icon(icon, size: size, color: color),
      onPressed: onPressed,
      tooltip: tooltip ?? semanticLabel,
    );

    return Semantics(
      button: true,
      label: semanticLabel,
      enabled: true,
      onTap: onPressed,
      child: button,
    );
  }
}

/// スクリーンリーダー対応のテキストボタン
class AccessibleTextButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final String? hint;
  final bool enabled;

  const AccessibleTextButton({
    Key? key,
    required this.label,
    required this.onPressed,
    this.hint,
    this.enabled = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      hint: hint,
      enabled: enabled,
      onTap: enabled ? onPressed : null,
      child: TextButton(
        onPressed: enabled ? onPressed : null,
        child: Text(label),
      ),
    );
  }
}
