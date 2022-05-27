import 'package:flutter_test/flutter_test.dart';
import 'package:yet_another_observer/yet_another_observer.dart';
import 'package:collection/collection.dart';

void main() async {

  group('Changes', (){
    late int value;
    late int result;

    void onChanged(YAObserverEvent event) {
      result = event.value;
    }

    setUp((){
      value = 1;
      result = 0;
    });


    test('onChange is not triggered by the first value if fireOnFirstUpdate is false and updateImmediately is false', () {
      var _onChanged = expectAsync1(onChanged, count: 0);
      YAObserver observer = YAObserver(()=>value, onChanged: _onChanged, fireOnFirstUpdate: false, updateImmediately: false);
      observer.update();
      expect(result, 0);
    });


    test('onChange is triggered by the first value if fireOnFirstUpdate is true and updateImmediately is false', () {
      var _onChanged = expectAsync1(onChanged, count: 1);
      YAObserver observer = YAObserver(()=>value, onChanged: _onChanged, fireOnFirstUpdate: true, updateImmediately: false);
      observer.update();
      expect(result, 1);
    });


    test('onChange is not triggered by the first value if fireOnFirstUpdate is false and updateImmediately is true', () {
      var _onChanged = expectAsync1(onChanged, count: 0);
      YAObserver observer = YAObserver(()=>value, onChanged: _onChanged, fireOnFirstUpdate: false, updateImmediately: true);
      observer.update();
      expect(result, 0);
    });


    test('onChange is not triggered by the first value if fireOnFirstUpdate is true and updateImmediately is true', () {
      var _onChanged = expectAsync1(onChanged, count: 1);
      YAObserver observer = YAObserver(()=>value, onChanged: _onChanged, fireOnFirstUpdate: true, updateImmediately: true);
      observer.update();
      expect(result, 1);
    });


    test('onChange is triggered on every change', () {
      var _onChanged = expectAsync1(onChanged, count: 3);
      YAObserver observer = YAObserver(()=>value, onChanged: _onChanged, fireOnFirstUpdate: true);
      observer.update();
      expect(result, 1);

      value = 2;
      observer.update();
      expect(result, 2);

      value = 3;
      observer.update();
      expect(result, 3);
    });


    test('onChange is only triggered by changes', () {
      var _onChanged = expectAsync1(onChanged, count: 2);
      YAObserver observer = YAObserver(()=>value, onChanged: _onChanged, fireOnFirstUpdate: true);
      observer.update();
      expect(result, 1);
      observer.update();
      expect(result, 1);

      value = 2;
      observer.update();
      expect(result, 2);
    });

  });


  group('History', (){
    late int value;
    late int result;


    setUp((){
      value = 1;
      result = 0;
    });



    test('The onChange event history contains the previous events, unless it is the first time onChange is invoked, in which case the event history is empty', () {
      void onChanged(YAObserverEvent event) {
        if( value == 1 ){
          expect(event.history.isEmpty, true);
        }
        else if( value == 2 ){
          expect(event.history.length, 1);
          expect(event.history[0].value, 1);
        }
        else if( value == 3 ){
          expect(event.history.length, 2);
          expect(event.history[0].value, 2);
          expect(event.history[1].value, 1);
        }
        else if( value == 4 ){
          expect(event.history.length, 2);
          expect(event.history[0].value, 3);
          expect(event.history[1].value, 2);
        }

        result = event.value;
      }

      var _onChanged = expectAsync1(onChanged, count: 4);
      YAObserver observer = YAObserver(()=>value, onChanged: _onChanged, fireOnFirstUpdate: true, maxHistoryLength: 2);
      observer.update();
      expect(result, 1);

      value = 2;
      observer.update();
      expect(result, 2);

      value = 3;
      observer.update();
      expect(result, 3);

      value = 4;
      observer.update();
      expect(result, 4);
    });



    test('The history depth defaults to zero', () {
      void onChanged(YAObserverEvent event) {
        expect(event.history.isEmpty, true);
        result = event.value;
      }

      var _onChanged = expectAsync1(onChanged, count: 2);
      YAObserver observer = YAObserver(()=>value, onChanged: _onChanged, fireOnFirstUpdate: true);
      observer.update();
      expect(result, 1);

      value = 2;
      observer.update();
      expect(result, 2);
    });


    test('The event history is unmodifiable', () async {
      void onChanged(YAObserverEvent event) async {
        expect(event.history, isA<List>());

        expect(
          () => event.history.add(YAObserverEventHistoryEntry(99, DateTime.now())),
          throwsA(isA<TypeError>())
        );

        result = event.value;
      }

      YAObserver observer = YAObserver(()=>value, onChanged: onChanged, fireOnFirstUpdate: true);
      observer.update();
      expect(result, 1);
    });

  });


  group('Observed types', (){


    setUp((){
    });



    test('int', () {
      int value = 1;
      int result = 0;

      var onChanged = expectAsync1((YAObserverEvent event) {
        result = event.value;
      }, count: 1);

      YAObserver observer = YAObserver(()=>value, onChanged: onChanged, fireOnFirstUpdate: true);
      observer.update();
      expect(result, 1);

      observer.update();
      expect(result, 1);
    });



    test('String', () {
      String value = 'abc';
      String result = '';

      var onChanged = expectAsync1((YAObserverEvent event) {
        result = event.value;
      }, count: 1);

      YAObserver observer = YAObserver(()=>value, onChanged: onChanged, fireOnFirstUpdate: true);
      observer.update();
      expect(result, 'abc');

      observer.update();
      expect(result, 'abc');
    });


    /// When comparing a non-scalar value, special care must be taken so that the hasChanged function compares the
    /// values for equality and not identity!
    test('List<String> doesn\'t work without a custom hasChanged', () {
      List<String> value = ['abc'];
      List<String> result = [];

      var onChanged = expectAsync1((YAObserverEvent event) {
        result = event.value;
      }, count: 1);

      YAObserver observer = YAObserver(()=>value, onChanged: onChanged, fireOnFirstUpdate: true);
      observer.update();
      expect(result == ['abc'], false);

      // result should now point to the same object as value - not good!
      expect(result == value, true);
      value.add('123');
      expect(result.length == 2, true);

      value == ['123'];
      observer.update();
      expect(result == ['123'], false);
    });


    /// When comparing a non-scalar value, special care must be taken so that the hasChanged function compares the
    /// values for equality and not identity!
    test('List<String> works with a custom hasChanged and toList()', () {
      List<String> value = ['abc'];
      List<String> result = [];

      var onChanged = expectAsync1((YAObserverEvent<List<String>> event) {
        result = event.value.toList();
      }, count: 2);

      YAObserver observer = YAObserver<List<String>>(
          ()=>value,
        hasChanged: (old, current) => !const ListEquality().equals(old, current),
        onChanged: onChanged,
        fireOnFirstUpdate: true
      );
      observer.update();
      expect(const ListEquality().equals(result, ['abc']), true);

      // result should NOT point to the same object as value
      expect(result == value, false);
      value.add('123');
      expect(result.length == 1, true);

      value = ['123'];
      observer.update();
      expect(const ListEquality().equals(result, ['123']), true);
    });
  });

  test('README example 1', () {
    String output = '';
    List<String> myList = ['abc'];

    YAObserver observer = YAObserver<List<String>>(
        () => myList,
      onChanged: (event){
        output += 'The list changed from ${event.history[0].value} to ${event.value}.\n';
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

    expect(output, 'The list changed from [abc] to [123].\nThe list changed from [123] to [123].\n');
  });

  test('README example 2', () {
    String output = '';
    List<String> myList = ['abc'];

    YAObserver observer = YAObserver<List<String>>(
        () => myList,
      onChanged: (event){
        output += 'The list changed from ${event.history[0].value} to ${event.value}.\n';
      },
      hasChanged: (old, current) => !const ListEquality().equals(old, current),
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

    expect(output, 'The list changed from [abc] to [123].\nThe list changed from [123] to [123, foobar].\n');
  });


}
