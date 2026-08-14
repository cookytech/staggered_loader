# staggered_loader

A tiny Flutter widget that avoids the flash-of-shimmer for fast futures.

Loading spinners and shimmers make sub-second UIs feel slower than they are.
`StaggeredLoader` renders **nothing** for a configurable deadline and only
shows a loader if the future is still pending when the deadline elapses. If
the future resolves before the deadline, the loader is skipped entirely and
the content appears immediately.

## Behavior

| Time                          | Future state | Widget shown         |
|-------------------------------|--------------|----------------------|
| `t < delay`                   | pending      | `placeholder` (blank)|
| `t < delay`                   | resolved     | `builder(data)`      |
| `t >= delay`                  | pending      | `loader`             |
| `t >= delay`                  | resolved     | `builder(data)`      |
| any                           | rejected     | `errorBuilder(err)`  |

Default `delay` is `1s`. Configure per widget.

## Usage

```dart
StaggeredLoader<List<String>>(
  future: api.fetchItems(),
  delay: const Duration(seconds: 1),
  placeholder: const SizedBox.shrink(),
  loader: const CircularProgressIndicator(),
  errorBuilder: (context, error, _) => Text('$error'),
  builder: (context, items) => ListView(
    children: [for (final s in items) Text(s)],
  ),
)
```

## Example

See [`example/`](example/) for a full demo app with configurable mock API
delays and loader deadlines. Integration tests in
[`example/integration_test/`](example/integration_test/) prove the widget
behavior across fast, slow, and borderline API response times.

Run:

```bash
cd example
flutter run                            # interactive demo
flutter test integration_test -d macos # integration suite
```

## Tests

```bash
flutter test           # widget tests for StaggeredLoader
```
