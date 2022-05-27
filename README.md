This package lets you observe changes to any variable or expression without having to 
use any special types or annotations. This makes it easy to retrofit it into an existing
project where you need to observe something without changing existing variable types.

If you have ever found yourself adding something like `_lastValue` and `if(value != _lastValue)`
then this package is for you, and takes care of those details in a nicer way without 
polluting your code with variables and if statements.

## Features

This observer relies on manually calling an update method to check for changes to the 
observed variables or expressions. This makes it suitable for use in Flutter Widgets, 
where the observers can be updated on each build. 

There's also a manager class that can be used to simplify managing and updating multiple 
observers from one place.

To make it even easier, the package includes an observer Widget that can be used to wrap
other widgets and automatically trigger the update, as well as a mixin that simplifies
managing and updating multiple observers from a StatefulWidget. 

## Basic usage


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


## Events

Whenever a change of the observed value is detected, the `onChanged` method of the observer 
will be invoked with an event parameter. The event parameter holds information about the change:

- `value` is the current value of the observed value.
- `changeTime` is the time when the change was detected (not necessarily the exact time
when the variables value was changed - it will be the time when the [update] method of
the observer was executed).
- `history` contains a list of past events. The maximum number of historical events to
keep is defined when constructing the observer. The latest historical event will be at
index `0`, the one before that at index `1`, and so on.

## Observing non-scalar values

### 1. Getting the value

The first problem that could arise is that if you supply an object as the value to be observed, 
that same object instance could will end up being compared to itself! That's because the 
observer stores the previous value and then checks it against the current value on the next
update. 

The solution is to always supply a unique instance to the value function. For example, if you want 
to observe a `List`, instead of writing

```dart
YAObserver(
  () => myList,
  onChanged: (event){
    // Might never be called, because both the old and current value might point  
    // to the same list and thus appear (to the observer) to never change.
  }
)
```

you could write 
```dart
YAObserver(
  () => myList.toList(),
  onChanged: (event){
  }
)
```

The example above uses `toList()` to create a unique instance of the list, which gets stored as 
the old value. The next time `update()` is called, the old value will be different from the
current value. Which brings us to problem nr 2...

### 2. Comparing previous and current value

Some special care needs to be taken when observing non-scalar values, for example a `List`. 
The observer will by default use the `==` operator to compare the previous and the current
observed value.

Consider the following code:

```dart
List<String> myList = ['abc'];

YAObserver observer = YAObserver<List<String>>(
  () => myList.toList(),
  onChanged: (event){
    print('The list changed from ${event.history[0].value} to ${event.value}.');
  },
  maxHistoryLength: 1,
  updateImmediately: true,
  fireOnFirstUpdate: false
);

myList = ['123'];
observer.update();

myList = ['123'];
observer.update();

myList.add('foobar');
observer.update();

```

This will result in 

```
The list changed from [abc] to [123].
The list changed from [123] to [123].
```

You might have expected that the output would be 

```
The list changed from [abc] to [123].
The list changed from [123] to [123, foobar].
```

The problem is that we're comparing `List` instances and not their actual contents. This problem can be 
solved by supplying a custom `hasChanged` function to the observer. To achieve the desired result, there 
are a number of options. 

First, you could convert the `List` into a scalar value, for example by JSON-encoding it or simply
supplying the observer with the value of `myList.toString()`. Then you would be comparing strings, which would work.
The problem with this solution is that two lists with the same contents but in different order will 
result in two different strings, so they will not be equal.

A better option is to use the Dart collection library, which provides some handy functions for 
comparing lists and other collections.

```dart
import 'package:collection/collection.dart';

YAObserver observer = YAObserver<List<String>>(
  () => myList,
  onChanged: (event){
    print('The list changed from ${event.history[0].value} to ${event.value}.');
  },
  hasChanged: (old, current) => ! const ListEquality().equals(old, current),
  maxHistoryLength: 1,
  updateImmediately: true,
  fireOnFirstUpdate: false
);
```

will result in 
```
The list changed from [abc] to [123].
The list changed from [123] to [123, foobar].
```



## Additional information

Check out the example for some more information about what this package can do. Also see the inline
documentation in the code.
