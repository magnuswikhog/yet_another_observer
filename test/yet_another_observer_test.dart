import 'package:flutter_test/flutter_test.dart';

import 'package:yet_another_observer/yet_another_observer.dart';

void main() {

  group('group1', (){
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


  group('group2', (){
    late int value;
    late int result;


    setUp((){
      value = 1;
      result = 0;
    });



    test('The onChange event contains the previous event, unless it is the first time onChange is invoked, in which case the previous event is null', () {
      void onChanged(YAObserverEvent event) {
        if( value == 1 ){
          expect(event.previous, null);
        }
        else if( value == 2 ){
          expect(event.previous!.value, 1);
        }

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


    test('The event chain is only 1 level deep', () {
      void onChanged(YAObserverEvent event) {
        if( value == 1 ){
          expect(event.previous, null);
        }
        else if( value == 2 ){
          expect(event.previous!.value, 1);
        }
        else if( value == 3 ){
          expect(event.previous!.previous, null);
        }

        result = event.value;
      }

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

  });
}
