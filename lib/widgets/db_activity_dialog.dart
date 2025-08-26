import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

class DbActivityState {
  final String title;
  final String subtitle;
  final double progress; // 0.0..1.0, use -1 for indeterminate
  final List<String> logs;
  final bool isDone;
  final bool isError;

  const DbActivityState({
    required this.title,
    this.subtitle = '',
    this.progress = -1,
    this.logs = const [],
    this.isDone = false,
    this.isError = false,
  });

  DbActivityState copyWith({
    String? title,
    String? subtitle,
    double? progress,
    List<String>? logs,
    bool? isDone,
    bool? isError,
  }) => DbActivityState(
        title: title ?? this.title,
        subtitle: subtitle ?? this.subtitle,
        progress: progress ?? this.progress,
        logs: logs ?? this.logs,
        isDone: isDone ?? this.isDone,
        isError: isError ?? this.isError,
      );
}

class DbActivityController {
  final ValueNotifier<DbActivityState> _state;
  final VoidCallback _close;

  DbActivityController._(this._state, this._close);

  ValueListenable<DbActivityState> get listenable => _state;

  void setSubtitle(String subtitle) {
    _state.value = _state.value.copyWith(subtitle: subtitle);
  }

  void setProgress(double progress) {
    _state.value = _state.value.copyWith(progress: progress);
  }

  void addLog(String log) {
    final updated = List<String>.from(_state.value.logs)..add(log);
    _state.value = _state.value.copyWith(logs: updated);
  }

  void markDone([String? finalLog]) {
    if (finalLog != null) addLog(finalLog);
    _state.value = _state.value.copyWith(isDone: true, progress: 1.0);
  }

  void markError(String error) {
    addLog('Error: $error');
    _state.value = _state.value.copyWith(isError: true);
  }

  void close() => _close();
}

DbActivityController showDbActivityDialog(BuildContext context, {required String title, String subtitle = ''}) {
  final state = ValueNotifier<DbActivityState>(DbActivityState(title: title, subtitle: subtitle));

  void doClose() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      final theme = Theme.of(ctx);
      return PopScope(
        canPop: false,
        child: Dialog(
          insetPadding: const EdgeInsets.all(16),
          backgroundColor: theme.colorScheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ValueListenableBuilder<DbActivityState>(
            valueListenable: state,
            builder: (context, s, _) {
              final progressWidget = s.progress < 0
                  ? const LinearProgressIndicator()
                  : LinearProgressIndicator(value: s.progress);
              return Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: 520,
                  height: 420,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.cloud_sync, color: theme.colorScheme.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  s.title,
                                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (s.subtitle.isNotEmpty)
                                  Text(
                                    s.subtitle,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          if (!s.isDone && !s.isError)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(children: [
                                Icon(Icons.sync, size: 16, color: theme.colorScheme.primary),
                                const SizedBox(width: 6),
                                Text('Working...', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.primary)),
                              ]),
                            ),
                          if (s.isDone)
                            Row(children: [
                              Icon(Icons.check_circle, color: theme.colorScheme.tertiary),
                              const SizedBox(width: 6),
                              Text('Done', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.tertiary)),
                            ]),
                          if (s.isError)
                            Row(children: [
                              Icon(Icons.error, color: theme.colorScheme.error),
                              const SizedBox(width: 6),
                              Text('Error', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.error)),
                            ]),
                        ],
                      ),
                      const SizedBox(height: 16),
                      progressWidget,
                      const SizedBox(height: 12),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.2)),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: ListView.builder(
                              itemCount: s.logs.length,
                              itemBuilder: (context, index) {
                                final line = s.logs[index];
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('> ', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary)),
                                      Expanded(
                                        child: Text(
                                          line,
                                          style: theme.textTheme.bodySmall,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (s.isDone || s.isError)
                            ElevatedButton(
                              onPressed: doClose,
                              child: const Text('Close'),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      );
    },
  );

  return DbActivityController._(state, doClose);
} 