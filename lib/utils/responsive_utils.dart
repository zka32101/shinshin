import 'package:flutter/material.dart';

/// 画面サイズのカテゴリ
enum ScreenSize { mobile, tablet, desktop }

/// レスポンシブデザイン用ユーティリティ
class ResponsiveUtils {
  /// デバイスの画面サイズを取得
  static ScreenSize getScreenSize(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 600) return ScreenSize.mobile;
    if (width < 1200) return ScreenSize.tablet;
    return ScreenSize.desktop;
  }

  /// デバイスが小画面 (mobile) かどうか
  static bool isMobile(BuildContext context) {
    return getScreenSize(context) == ScreenSize.mobile;
  }

  /// デバイスが中画面 (tablet) かどうか
  static bool isTablet(BuildContext context) {
    return getScreenSize(context) == ScreenSize.tablet;
  }

  /// デバイスが大画面 (desktop) かどうか
  static bool isDesktop(BuildContext context) {
    return getScreenSize(context) == ScreenSize.desktop;
  }

  /// 横向きかどうか
  static bool isLandscape(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.landscape;
  }

  /// 縦向きかどうか
  static bool isPortrait(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.portrait;
  }

  /// レスポンシブパディングを取得
  static EdgeInsets getResponsivePadding(BuildContext context) {
    final size = getScreenSize(context);
    switch (size) {
      case ScreenSize.mobile:
        return const EdgeInsets.all(12);
      case ScreenSize.tablet:
        return const EdgeInsets.all(16);
      case ScreenSize.desktop:
        return const EdgeInsets.all(24);
    }
  }

  /// レスポンシブフォントサイズを取得
  static double getResponsiveFontSize(
    BuildContext context, {
    required double mobile,
    required double tablet,
    required double desktop,
  }) {
    final size = getScreenSize(context);
    switch (size) {
      case ScreenSize.mobile:
        return mobile;
      case ScreenSize.tablet:
        return tablet;
      case ScreenSize.desktop:
        return desktop;
    }
  }

  /// レスポンシブグリッドの列数を取得
  static int getGridCrossAxisCount(BuildContext context) {
    final size = getScreenSize(context);
    switch (size) {
      case ScreenSize.mobile:
        return 2;
      case ScreenSize.tablet:
        return 3;
      case ScreenSize.desktop:
        return 4;
    }
  }

  /// 最大幅を持つレスポンシブコンテナ
  static Widget responsiveContainer({
    required BuildContext context,
    required Widget child,
    double maxWidth = 1200,
    EdgeInsets? padding,
  }) {
    final screenSize = getScreenSize(context);
    final defaultPadding = padding ?? ResponsiveUtils.getResponsivePadding(context);

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: defaultPadding,
          child: child,
        ),
      ),
    );
  }

  /// 画面幅を取得
  static double screenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  /// 画面高さを取得
  static double screenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  /// デバイスピクセル比を取得
  static double devicePixelRatio(BuildContext context) {
    return MediaQuery.of(context).devicePixelRatio;
  }

  /// ステータスバーの高さを取得
  static double statusBarHeight(BuildContext context) {
    return MediaQuery.of(context).padding.top;
  }

  /// ナビゲーションバーの高さを取得（Android）
  static double navigationBarHeight(BuildContext context) {
    return MediaQuery.of(context).padding.bottom;
  }

  /// セーフエリアを考慮した有効な高さを取得
  static double usableScreenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height -
        statusBarHeight(context) -
        navigationBarHeight(context);
  }

  /// キーボードが表示されているかどうか
  static bool isKeyboardVisible(BuildContext context) {
    return MediaQuery.of(context).viewInsets.bottom > 0;
  }

  /// キーボードの高さを取得
  static double keyboardHeight(BuildContext context) {
    return MediaQuery.of(context).viewInsets.bottom;
  }

  /// タッチデバイスかどうか
  static bool isTouchDevice() {
    // Flutter では常にタッチデバイスとして扱うが、実装可能
    return true;
  }
}

/// レスポンシブテンプレートウィジェット
class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext) mobile;
  final Widget Function(BuildContext)? tablet;
  final Widget Function(BuildContext)? desktop;

  const ResponsiveBuilder({
    Key? key,
    required this.mobile,
    this.tablet,
    this.desktop,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final size = ResponsiveUtils.getScreenSize(context);

    switch (size) {
      case ScreenSize.mobile:
        return mobile(context);
      case ScreenSize.tablet:
        return tablet?.call(context) ?? mobile(context);
      case ScreenSize.desktop:
        return desktop?.call(context) ?? tablet?.call(context) ?? mobile(context);
    }
  }
}
