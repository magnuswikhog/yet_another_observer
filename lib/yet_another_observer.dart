library yet_another_observer;

import 'dart:math';

import 'package:flutter/widgets.dart';

typedef YAObserverChanged<V> = void Function(YAObserverEvent<V> event);
typedef YAComparator<V> = bool Function(V previous, V current);
typedef YAValueGetter<V> = V Function();

class YAObserverEventHistoryEntry<V> {
  final V value;
  final DateTime changeTime;

  YAObserverEventHistoryEntry(this.value, this.changeTime);

  @override
  String toString() {
    return 'YAObserverEventHistoryEntry<$V>{value: $value, changeTime: $changeTime}';
  }
}

/// This class represents a change event in an observer.
///
/// [value] is the current value of the observed variable or expression.
///
/// [changeTime] is the time when the change was detected (not necessarily the exact time
/// when the variables value was changed - it will be the time when the [update] method of
/// the observer was executed).
///
/// [history] contains a list of past events. The maximum number of historical events to
/// keep is defined when constructing the observer. The latest historical event will be at
/// index `0`, the one before that at index `1`, and so on.
class YAObserverEvent<V> {
  final V value;
  final DateTime changeTime;
  final List<YAObserverEventHistoryEntry<V>> history;

  YAObserverEvent(this.value, this.changeTime, {this.history = const []});

  @override
  String toString() {
    return 'YAObserverEvent<$V>{value: $value, changeTime: $changeTime, history: $history}';
  }
}

/// This class represents a single observer.
class YAObserver<V> {
  final bool _fireOnFirstUpdate;
  YAObserverEvent<V>? _lastEvent;

  final int maxHistoryLength;
  final YAValueGetter<V> getValue;
  final YAObserverChanged<V> onChanged;
  final YAComparator<V> hasChanged;

  /// Creates an observer that triggers [onChanged] whenever the value returned from [getValue] changes.
  ///
  /// If [hasChanged] is specified and non-null, it will be used by the [update] method to determine
  /// if the value has changed. This is especially useful when comparing objects that can't be properly
  /// compared using the `==` operator, such as `List`'s and other collections. The default behaviour
  /// if [hasChanged] is null is to simply compare the old and new value using `==`.
  ///
  /// If [updateImmediately] is true, [getValue] will be invoked immediately to get the initial value.
  /// If false, [getValue] won't be invoked until you call [update].
  ///
  /// If [fireOnFirstUpdate] is true, [onChanged] will be executed on the first call to [getValue].
  /// If false, the first call to [getValue] will not trigger [onChanged].
  ///
  /// If both [updateImmediately] and [fireOnFirstUpdate] are true, [getValue] will immediately get the
  /// initial value and [onChanged] will be executed with that value. If they are both false, the first
  /// call to [update] will get the initial value, and [onChange] won't be triggered until the second
  /// call to [update] (if the value has changed since the first call).
  ///
  /// [maxHistoryLength] specifies the number of previous events to include in the `history` of the
  /// event passed to [onChanged]. It can be used to keep track of which previous changes have happened
  /// and at which moments in time.
  YAObserver(this.getValue,
      {required this.onChanged,
      YAComparator<V>? hasChanged,
      bool updateImmediately = true,
      bool fireOnFirstUpdate = false,
      this.maxHistoryLength = 0})
      : _fireOnFirstUpdate = fireOnFirstUpdate,
        hasChanged =
            hasChanged ?? ((previous, current) => current != previous) {
    if (updateImmediately) {
      _lastEvent = YAObserverEvent<V>(getValue(), DateTime.now());

      if (_fireOnFirstUpdate) {
        onChanged(_lastEvent!);
      }
    }
  }

  /// Updates the value of the observer by executing [getValue]. If the value has changed since the last
  /// call to [update], [onChanged] will be executed.
  ///
  /// See also the constructor for details about how to handle the initial update.
  void update() {
    V value = getValue();

    if (_lastEvent == null || hasChanged(_lastEvent!.value, value)) {
      List<YAObserverEventHistoryEntry<V>> history =
          _lastEvent?.history ?? List.unmodifiable([]);

      // Add _lastEvent to history and truncate it to maxHistoryLength
      if (_lastEvent != null && maxHistoryLength > 0) {
        history = List<YAObserverEventHistoryEntry<V>>.unmodifiable([
          YAObserverEventHistoryEntry<V>(
              _lastEvent!.value, _lastEvent!.changeTime),
          ...history.getRange(0, min(maxHistoryLength - 1, history.length))
        ]);
      }

      YAObserverEvent<V> event =
          YAObserverEvent<V>(value, DateTime.now(), history: history);

      if (_fireOnFirstUpdate || _lastEvent != null) {
        onChanged(event);
      }

      _lastEvent = event;
    }
  }
}

/// This class manages multiple [YAObserver] instances.
class YAObserverManager {
  final Map<dynamic, YAObserver> _observers = {};

  /// Adds a new observer. See the constructor of [YAObserver] for details.
  ///
  /// [tag], if provided, should be a unique value that can be used to identify this particular
  /// observer in calls to [update] and [remove].
  ///
  /// Returns the added observer.
  YAObserver<V> add<V>(
      YAValueGetter<V> getValue,
      {required YAObserverChanged<V> onChanged,
      dynamic tag,
      YAComparator<V>? hasChanged,
      bool updateImmediately = true,
      bool fireOnFirstUpdate = false,
      int maxHistoryLength = 0}) {
    tag ??= getValue;
    YAObserver<V> observer = YAObserver<V>(getValue,
        onChanged: onChanged,
        hasChanged: hasChanged,
        updateImmediately: updateImmediately,
        fireOnFirstUpdate: fireOnFirstUpdate,
        maxHistoryLength: maxHistoryLength);
    _observers[tag] = observer;
    return observer;
  }

  /// Removes one or more observers from the manager.
  ///
  /// If [tag] is provided, only the observer with that [tag] will be removed (if it exists).
  /// Otherwise all observers will be removed.
  void remove({dynamic tag}) {
    _observers.remove(tag);
  }

  /// Updates one or more observers by running their [getValue] functions.
  ///
  /// If [tag] is provided, only the observer with that [tag] will be updated (if it exists).
  /// Otherwise all observers will be updated.
  void update({dynamic tag}) {
    if (tag == null) {
      for (final o in _observers.values) {
        o.update();
      }
    } else {
      _observers[tag]?.update();
    }
  }
}

/// This mixin makes it easy to manage and update multiple observers from a
/// StatefulWidget.
///
/// **IMPORTANT**: You must call [updateObservers] from your [build] method, otherwise
/// the values of the observers will not be automatically updated!
mixin YAObserverStatefulMixin<T extends StatefulWidget> on State<T> {
  final YAObserverManager _observerManager = YAObserverManager();

  /// Adds an observer. See [YAObserver] for more details.
  ///
  /// **IMPORTANT**: You must call [super.build()] from your [build] method, otherwise
  /// the values of the observers will not be automatically updated!
  YAObserver<V> observe<V>(YAValueGetter<V> getValue,
      {required YAObserverChanged<V> onChanged,
      dynamic tag,
      YAComparator<V>? hasChanged,
      bool updateImmediately = true,
      bool fireOnFirstUpdate = false,
      int maxHistoryLength = 0}) {
    return _observerManager.add(getValue,
        onChanged: onChanged,
        hasChanged: hasChanged,
        tag: tag,
        updateImmediately: updateImmediately,
        fireOnFirstUpdate: fireOnFirstUpdate,
        maxHistoryLength: maxHistoryLength);
  }

  void updateObservers(){
    _observerManager.update();
  }

  @override
  void dispose() {
    _observerManager.remove();
    super.dispose();
  }

}

/// A Widget that updates an observer whenever it is rebuilt.
class YAObserverWidget extends StatelessWidget {
  final YAObserver _observer;
  final Widget _child;

  /// Creates a widget that updates [observer] whenever the widget is rebuilt.
  /// See [YAObserver] for more details.
  const YAObserverWidget(
      {required YAObserver observer, required Widget child, Key? key})
      : _observer = observer,
        _child = child,
        super(key: key);

  @override
  Widget build(BuildContext context) {
    _observer.update();
    return _child;
  }
}

/// A Widget that updates one or multiple observers whenever it is rebuilt.
class YAObserverManagerWidget extends StatelessWidget {
  final YAObserverManager _observerManager;
  final Widget _child;

  /// Creates a widget that updates all observers in [observerManager] whenever the
  /// widget is rebuilt.
  /// See [YAObserver] for more details.
  const YAObserverManagerWidget(
      {required YAObserverManager observerManager,
      required Widget child,
      Key? key})
      : _observerManager = observerManager,
        _child = child,
        super(key: key);

  @override
  Widget build(BuildContext context) {
    _observerManager.update();
    return _child;
  }
}
