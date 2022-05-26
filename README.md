This package lets you observe changes to any variable or expression without having to 
use any special types or annotations. This makes it easy to retrofit it into an existing
project where you need to observe something without changing existing variable types.

If you have ever found yourself adding something like `_lastValue` and `if(value != _lastValue)`
then this package is for you, and takes care of those details in a nicer way without 
polluting your code with variables and if statements.

## Features

This observer relies on manually calling an update method to check for changes to the 
observed variables or expressions. This makes it suitable for use in Widgets, where the 
observers can be updated on each build. 

There's also a manager class that can be used to simplify managing and updateing multiple 
observers fro mone place.

To make it even easier, the package includes an observer Widget that can be used to wrap
other widgets and automatically trigger the update, as well as a mixin that simplifies
managing and updating multiple observers from a StatefulWidget. 

## Usage


```dart
int value = 1;

YAObserver observer = YAObserver(
  () => value, 
  onChanged: (event){
    print('value=${event.value}');
  },
  updateImmediately: true
);

value = 2;
observer.update(); // Prints "value=2"
```

The example above simply checks the result of invoking `() => value`, compares it to the 
previous value, and triggers `onChanged` if the value was changed. 




## Additional information

Check out the example for some more information about what this package can do.
