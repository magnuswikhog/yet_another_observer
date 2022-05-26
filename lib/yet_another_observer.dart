library yet_another_observer;

import 'package:flutter/widgets.dart';


typedef YAObserverChanged<V> = void Function(YAObserverEvent<V> event);
typedef YAValueGetter<V> = V Function();

/// This class represents a change event in an observer.
class YAObserverEvent<V>{
  final V value;
  final DateTime? changeTime;
  final YAObserverEvent<V>? previous;

  YAObserverEvent(this.value, this.changeTime, this.previous);

  @override
  String toString() {
    return 'YAObserverEvent<$V>{value: $value, changeTime: $changeTime, previous: $previous}';
  }
}

/// This class represents a single observer.
class YAObserver<V>{
  final bool _fireOnFirstUpdate;
  YAObserverEvent<V>? _lastEvent;

  final YAValueGetter<V> getValue;
  final YAObserverChanged<V> onChanged;

  /// Creates an observer that triggers [onChanged] whenever the value returned from [getValue] changes.
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
  YAObserver(this.getValue, {required this.onChanged, bool updateImmediately=true, bool fireOnFirstUpdate=false})
    : _fireOnFirstUpdate = fireOnFirstUpdate
  {
    if( updateImmediately ) {
      _lastEvent = YAObserverEvent<V>(getValue(), null, null);

      if( _fireOnFirstUpdate ){
        onChanged(_lastEvent!);
      }
    }
  }


  /// Updates the value of the observer by executing [getValue]. If the value has changed since the last
  /// call to [update], [onChanged] will be executed.
  ///
  /// See also the constructor for details about how to handle the initial update.
  void update(){
    V value = getValue();

    if( _lastEvent == null || value != _lastEvent!.value ){
      // Remove previous from _lastEvent so we don't end up with a chain of events
      if( _lastEvent?.previous != null ){
        _lastEvent = YAObserverEvent(_lastEvent!.value, _lastEvent?.changeTime, null);
      }

      YAObserverEvent<V> event = YAObserverEvent<V>(value, DateTime.now(), _lastEvent);

      if( _lastEvent != null || _fireOnFirstUpdate ) {
        onChanged(event);
      }

      _lastEvent = YAObserverEvent<V>(event.value, event.changeTime, _lastEvent);
    }
  }
}


/// This class manages multiple [YAObserver] instances.
class YAObserverManager{
  final Map<dynamic, YAObserver> _observers = {};

  /// Adds a new observer. See the constructor of [YAObserver] for details.
  ///
  /// [tag], if provided, should be a unique value that can be used to identify this particular
  /// observer in calls to [update] and [remove].
  ///
  /// Returns the added observer.
  YAObserver<V> add<V>(YAValueGetter<V> getValue, YAObserverChanged<V> onChanged, {dynamic tag, bool updateImmediately=false, bool fireOnFirstUpdate=false}){
    tag ??= getValue;
    YAObserver<V> observer = YAObserver<V>(getValue, onChanged: onChanged, updateImmediately: updateImmediately, fireOnFirstUpdate: fireOnFirstUpdate);
    _observers[tag] = observer;
    return observer;
  }

  /// Removes one or more observers from the manager.
  ///
  /// If [tag] is provided, only the observer with that [tag] will be removed (if it exists).
  /// Otherwise all observers will be removed.
  void remove({dynamic tag}){
    _observers.remove(tag);
  }


  /// Updates one or more observers by running their [getValue] functions.
  ///
  /// If [tag] is provided, only the observer with that [tag] will be updated (if it exists).
  /// Otherwise all observers will be updated.
  void update({dynamic tag}){
    if( tag == null ){
      for(final o in _observers.values){
        o.update();
      }
    }
    else {
      _observers[tag]?.update();
    }
  }
}


/// This mixin makes it easy to manage and update multiple observers from a
/// StatefulWidget.
///
/// **IMPORTANT**: You must call [super.build()] from your [build] method, otherwise
/// the values of the observers will not be automatically updated!
mixin YAObserverStatefulMixin<T extends StatefulWidget> on State<T>{
  final YAObserverManager _observerManager = YAObserverManager();

  /// Adds an observer. See [YAObserver] for more details.
  ///
  /// **IMPORTANT**: You must call [super.build()] from your [build] method, otherwise
  /// the values of the observers will not be automatically updated!
  YAObserver<V> observe<V>(YAValueGetter<V> getValue, {required YAObserverChanged<V> onChanged, dynamic tag, bool updateImmediately=false, bool fireOnFirstUpdate=false}){
    return _observerManager.add(getValue, onChanged, tag: tag, updateImmediately: updateImmediately, fireOnFirstUpdate: fireOnFirstUpdate);
  }

  @override
  void dispose() {
    _observerManager.remove();
    super.dispose();
  }

  @mustCallSuper
  @override
  Widget build(BuildContext context) {
    _observerManager.update();
    return const _NullWidget();
  }
}


/// A Widget that updates an observer whenever it is rebuilt.
class YAObserverWidget extends StatelessWidget{
  final YAObserver _observer;
  final Widget _child;

  /// Creates a widget that updates [observer] whenever the widget is rebuilt.
  /// See [YAObserver] for more details.
  const YAObserverWidget({required YAObserver observer, required Widget child, Key? key})
    : _observer = observer, _child = child,
      super(key: key);

  @override
  Widget build(BuildContext context) {
    _observer.update();
    return _child;
  }
}

/// A Widget that updates one or multiple observers whenever it is rebuilt.
class YAObserverManagerWidget extends StatelessWidget{
  final YAObserverManager _observerManager;
  final Widget _child;

  /// Creates a widget that updates all observers in [observerManager] whenever the
  /// widget is rebuilt.
  /// See [YAObserver] for more details.
  const YAObserverManagerWidget({required YAObserverManager observerManager, required Widget child, Key? key})
    : _observerManager = observerManager, _child = child,
      super(key: key);

  @override
  Widget build(BuildContext context) {
    _observerManager.update();
    return _child;
  }
}


class _NullWidget extends StatelessWidget {
  const _NullWidget();

  @override
  Widget build(BuildContext context) {
    throw FlutterError(
      'Widgets that mix YAObserverStatefulMixin into their State must '
        'call super.build() but must ignore the return value of the superclass.',
    );
  }
}
