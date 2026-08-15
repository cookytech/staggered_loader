## 0.0.1

* Initial release: `StaggeredLoader<T>` widget that delays loader rendering
  until a configurable deadline elapses, skipping loader visuals entirely
  when the underlying future resolves sooner.
* Example app with configurable mock API delays and loader deadlines.
* Integration tests covering fast, slow, and borderline API response times.
