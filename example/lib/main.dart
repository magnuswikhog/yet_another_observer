import 'dart:async';

import 'package:flutter/material.dart';
import 'package:yet_another_observer/yet_another_observer.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Yet Another Observer example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Yet Another Observer example'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

void test<V>(V value, Function(V value) doStuff){
  doStuff(value);
}


class _MyHomePageState extends State<MyHomePage> with YAObserverStatefulMixin{
  int _animationStep = 0;
  final List<String> _animationSequence = ['.', '..', '...', ' ...', '  ...', '   ..', '    .', '     '];

  int _counter = 0;

  late final YAObserver _counterObserver;


  @override
  void initState() {
    super.initState();

    _counterObserver = observe<int>(
        ()=>_counter,
        maxHistoryLength: 1,
        updateImmediately: true,
        fireOnFirstUpdate: false,
        onChanged: (event){
          if( event.value == 3 ){
            scheduleMicrotask(
              () => showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text('${event.history[0].value} ---> ${event.value}'),
                  content: const Text(
                    'This dialog was shown from an observer that '
                    'observes the number on every rebuild. When the observed number '
                    'is 3 but was previously something else (i.e. it changed), the '
                    'observer function was triggered.\n\n'
                    'If you had simply shown the dialog from the build function every '
                    'time the number is 3, you would have ended up adding a new dialog '
                    'on each rebuild due to the build function being triggered by other '
                    'things than just the +/- buttons (i.e. the animation).'
                  ),
                  actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('OK'))],
                )
              )
            );
          }
        },
    );

    Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if( mounted ) {
        setState(() {
          _animationStep++;
          if(_animationStep >= _animationSequence.length) _animationStep = 0;
        });
      }
    });
  }


  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text( _animationSequence[_animationStep], textScaleFactor: 5, ),
              const SizedBox(height: 40),
              const Text('3 is the magic number...'),
              Text('$_counter', textScaleFactor: 3),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            FloatingActionButton(
              onPressed: () => setState(() => _counter-- ),
              child: const Icon(Icons.remove),
            ),
            const SizedBox(width: 20),
            FloatingActionButton(
              onPressed: () => setState(() => _counter++ ),
              child: const Icon(Icons.add),
            ),
          ],
        ),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
