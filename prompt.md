when developing loader states in flutter apps it is customary to show a shimmer / visual shimmer as a loading state and then show the 
UI. This leaves some perceived performance on the table

When loading, loading elements make the interaction feel slower for interactions that take less than 1s. this is where staggered loader comes in --
* starts with blank space
* waits one second before showing the loader (this deadline is a configurable parameter, someone might want to keep it 500ms)
* shows the loader if the future has returned this could be a Future<Widget> to simplify things
* shows the loader only if time has passed and future is returned


lets test this theory by building this package, building a sample app, and testing it using integration tests with different api response times in the mock
