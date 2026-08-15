import 'package:flutter/material.dart';
import 'package:staggered_loader/staggered_loader.dart';

import 'mock_api.dart';

void main() {
  runApp(const DemoApp(api: null));
}

class DemoApp extends StatelessWidget {
  const DemoApp({super.key, this.api});

  final MockApi? api;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'StaggeredLoader Demo',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo),
      home: DemoHome(api: api ?? MockApi()),
    );
  }
}

class DemoHome extends StatefulWidget {
  const DemoHome({required this.api, super.key});

  final MockApi api;

  @override
  State<DemoHome> createState() => _DemoHomeState();
}

class _DemoHomeState extends State<DemoHome> {
  Future<List<String>>? _future;
  Duration _delay = const Duration(seconds: 1);

  static const _apiDurations = <Duration>[
    Duration(milliseconds: 200),
    Duration(milliseconds: 800),
    Duration(milliseconds: 1500),
    Duration(milliseconds: 3000),
  ];

  // 0ms (instant) through 2000ms in 100ms steps.
  static final List<Duration> _loaderDelays = List.generate(
    21,
    (i) => Duration(milliseconds: i * 100),
  );

  void _load() {
    setState(() {
      _future = widget.api.fetchItems();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('StaggeredLoader Demo')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ControlRow(
              apiDurations: _apiDurations,
              currentApiDuration: widget.api.responseDelay,
              onApiDurationChanged: (d) {
                setState(() => widget.api.responseDelay = d);
              },
              loaderDelays: _loaderDelays,
              loaderDelay: _delay,
              onLoaderDelayChanged: (d) => setState(() => _delay = d),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              key: const ValueKey('loadButton'),
              onPressed: _load,
              child: const Text('Load items'),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: _future == null
                  ? const Center(
                      key: ValueKey('idle'),
                      child: Text('Press "Load items" to start.'),
                    )
                  : StaggeredLoader<List<String>>(
                      key: ValueKey('${widget.api.responseDelay.inMilliseconds}'
                          ':${_delay.inMilliseconds}'),
                      future: _future!,
                      delay: _delay,
                      placeholder: const SizedBox.expand(
                        key: ValueKey('placeholder'),
                      ),
                      loader: const _ShimmerLoader(key: ValueKey('loader')),
                      errorBuilder: (context, error, _) => Center(
                        key: const ValueKey('error'),
                        child: Text('Error: $error'),
                      ),
                      builder: (context, items) => ListView(
                        key: const ValueKey('items'),
                        children: [
                          for (final item in items)
                            ListTile(
                              leading: const Icon(Icons.check_circle_outline),
                              title: Text(item),
                            ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

String _labelFor(Duration d) =>
    d == Duration.zero ? 'instant' : '${d.inMilliseconds}ms';

class _ControlRow extends StatelessWidget {
  const _ControlRow({
    required this.apiDurations,
    required this.currentApiDuration,
    required this.onApiDurationChanged,
    required this.loaderDelays,
    required this.loaderDelay,
    required this.onLoaderDelayChanged,
  });

  final List<Duration> apiDurations;
  final Duration currentApiDuration;
  final ValueChanged<Duration> onApiDurationChanged;
  final List<Duration> loaderDelays;
  final Duration loaderDelay;
  final ValueChanged<Duration> onLoaderDelayChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Mock API response time:',
            style: Theme.of(context).textTheme.labelLarge),
        Wrap(
          spacing: 8,
          children: [
            for (final d in apiDurations)
              ChoiceChip(
                key: ValueKey('api-${d.inMilliseconds}'),
                label: Text('${d.inMilliseconds}ms'),
                selected: d == currentApiDuration,
                onSelected: (_) => onApiDurationChanged(d),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text('Loader appears after:',
            style: Theme.of(context).textTheme.labelLarge),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            for (final d in loaderDelays)
              ChoiceChip(
                key: ValueKey('delay-${d.inMilliseconds}'),
                label: Text(_labelFor(d)),
                selected: d == loaderDelay,
                onSelected: (_) => onLoaderDelayChanged(d),
              ),
          ],
        ),
      ],
    );
  }
}

class _ShimmerLoader extends StatefulWidget {
  const _ShimmerLoader({super.key});

  @override
  State<_ShimmerLoader> createState() => _ShimmerLoaderState();
}

class _ShimmerLoaderState extends State<_ShimmerLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: 5,
      separatorBuilder: (_, i) => const SizedBox(height: 8),
      itemBuilder: (_, index) => AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final t = _controller.value;
          return Container(
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              gradient: LinearGradient(
                colors: [
                  Colors.grey.shade300,
                  Colors.grey.shade100,
                  Colors.grey.shade300,
                ],
                stops: [
                  (t - 0.3).clamp(0.0, 1.0),
                  t.clamp(0.0, 1.0),
                  (t + 0.3).clamp(0.0, 1.0),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
