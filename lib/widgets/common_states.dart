import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_styles.dart';

/// 共通のローディング状態ウィジェット
class CommonLoadingState extends StatelessWidget {
  final String? message;

  const CommonLoadingState({
    Key? key,
    this.message,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            color: AppColors.primary,
          ),
          if (message != null) ...[
            const SizedBox(height: AppStyles.paddingMedium),
            Text(
              message!,
              style: AppStyles.bodyMedium,
            ),
          ],
        ],
      ),
    );
  }
}

/// 共通のエラー状態ウィジェット
class CommonErrorState extends StatelessWidget {
  final String error;
  final VoidCallback? onRetry;
  final String? actionLabel;

  const CommonErrorState({
    Key? key,
    required this.error,
    this.onRetry,
    this.actionLabel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppStyles.paddingLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: AppColors.error.withAlpha(200),
            ),
            const SizedBox(height: AppStyles.paddingLarge),
            Text(
              'エラーが発生しました',
              style: AppStyles.headingMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppStyles.paddingSmall),
            Text(
              error,
              style: AppStyles.bodySmall,
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppStyles.paddingLarge),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: Text(actionLabel ?? '再試行'),
                style: AppStyles.primaryButtonStyle(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 共通の空状態ウィジェット
class CommonEmptyState extends StatelessWidget {
  final String message;
  final IconData? icon;
  final VoidCallback? onAction;
  final String? actionLabel;

  const CommonEmptyState({
    Key? key,
    required this.message,
    this.icon,
    this.onAction,
    this.actionLabel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppStyles.paddingLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 48,
                color: AppColors.textTertiary,
              ),
              const SizedBox(height: AppStyles.paddingMedium),
            ],
            Text(
              message,
              style: AppStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
            if (onAction != null) ...[
              const SizedBox(height: AppStyles.paddingLarge),
              ElevatedButton(
                onPressed: onAction,
                style: AppStyles.primaryButtonStyle(),
                child: Text(actionLabel ?? 'アクション'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// AsyncValue ヘルパーウィジェット - Riverpod AsyncValue を処理
class AsyncValueBuilder<T> extends StatelessWidget {
  final AsyncValue<T> value;
  final Widget Function(T data) onData;
  final Widget Function()? onLoading;
  final Widget Function(Object error)? onError;

  const AsyncValueBuilder({
    Key? key,
    required this.value,
    required this.onData,
    this.onLoading,
    this.onError,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return value.when(
      data: onData,
      loading: () => onLoading?.call() ?? const CommonLoadingState(),
      error: (error, _) =>
          onError?.call(error) ??
          CommonErrorState(
            error: error.toString(),
          ),
    );
  }
}
