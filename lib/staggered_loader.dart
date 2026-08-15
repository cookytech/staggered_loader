import 'dart:async';

import 'package:flutter/material.dart';

/// Signature for building the content widget once the future resolves.
typedef StaggeredDataBuilder<T> = Widget Function(BuildContext context, T data);

/// Signature for building an error widget when the future rejects.
typedef StaggeredErrorBuilder = Widget Function(
  BuildContext context,
  Object error,
  StackTrace? stackTrace,
);

/// A loader that avoids the flash-of-shimmer for fast futures.
///
/// Behavior:
/// * While waiting under [delay], render [placeholder] (defaults to blank).
/// * If the future has not resolved by [delay], render [loader].
/// * When the future resolves, render [builder]'s result (skipping the loader
///   entirely when the future resolved before [delay] elapsed).
class StaggeredLoader<T> extends StatefulWidget {
  const StaggeredLoader({
    required this.future,
    required this.builder,
    this.loader,
    this.placeholder,
    this.errorBuilder,
    this.delay = const Duration(seconds: 1),
    super.key,
  });

  final Future<T> future;
  final StaggeredDataBuilder<T> builder;
  final Widget? loader;
  final Widget? placeholder;
  final StaggeredErrorBuilder? errorBuilder;
  final Duration delay;

  @override
  State<StaggeredLoader<T>> createState() => _StaggeredLoaderState<T>();
}

enum _Phase { waiting, loading, done, error }

class _StaggeredLoaderState<T> extends State<StaggeredLoader<T>> {
  _Phase _phase = _Phase.waiting;
  T? _data;
  Object? _error;
  StackTrace? _stackTrace;
  Timer? _delayTimer;
  bool _resolved = false;

  @override
  void initState() {
    super.initState();
    _subscribe(widget.future);
    _startDelay();
  }

  @override
  void didUpdateWidget(covariant StaggeredLoader<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.future, widget.future)) {
      _reset();
      _subscribe(widget.future);
      _startDelay();
    }
  }

  void _reset() {
    _delayTimer?.cancel();
    _delayTimer = null;
    _resolved = false;
    _phase = _Phase.waiting;
    _data = null;
    _error = null;
    _stackTrace = null;
  }

  void _startDelay() {
    if (widget.delay <= Duration.zero) {
      if (!_resolved && mounted) {
        setState(() => _phase = _Phase.loading);
      }
      return;
    }
    _delayTimer = Timer(widget.delay, () {
      if (!mounted || _resolved) return;
      setState(() => _phase = _Phase.loading);
    });
  }

  void _subscribe(Future<T> future) {
    future.then((value) {
      if (!mounted) return;
      _resolved = true;
      _delayTimer?.cancel();
      setState(() {
        _data = value;
        _phase = _Phase.done;
      });
    }, onError: (Object error, StackTrace stackTrace) {
      if (!mounted) return;
      _resolved = true;
      _delayTimer?.cancel();
      setState(() {
        _error = error;
        _stackTrace = stackTrace;
        _phase = _Phase.error;
      });
    });
  }

  @override
  void dispose() {
    _delayTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    switch (_phase) {
      case _Phase.waiting:
        return widget.placeholder ?? const SizedBox.shrink();
      case _Phase.loading:
        return widget.loader ??
            const Center(child: CircularProgressIndicator());
      case _Phase.done:
        return widget.builder(context, _data as T);
      case _Phase.error:
        final builder = widget.errorBuilder;
        if (builder != null) {
          return builder(context, _error!, _stackTrace);
        }
        return Center(child: Text('Error: $_error'));
    }
  }
}
