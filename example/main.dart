import 'package:flutter/material.dart';
import 'package:pointer_manger/pointer_manger.dart';

/// Toggle it to see the difference afterwards.
const _withNegativeError = false;

const _noNegativeGroupTag = "no-negative";

void main() => runApp(
  const MaterialApp(
    home: Scaffold(
      body: Center(
        child: MyApp(),
      ),
    ),
  ));


class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  int _n = 0;

  Widget _buildWithNegativeError(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      ElevatedButton(
        onPressed: _n <= 1 ? null : () => setState(() => _n = _n - 2), 
        child: const Text("-2"),
      ),
      ElevatedButton(
        onPressed: _n <= 0 ? null : () => setState(() => --_n), 
        child: const Text("-1"),
      ),
      Text(_n.toString()),
      ElevatedButton(
        onPressed: () => setState(() => ++_n), 
        child: const Text("+1"),
      ),
    ],
  );

  Widget _buildWithoutNegativeError(BuildContext context) => PointerGroupHandler(
    groupTag: _noNegativeGroupTag,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        PointerMangerWidget.withAll(
          child: ElevatedButton(
            onPressed: _n <= 1 ? null : () => setState(() => _n = _n - 2), 
            child: const Text("-2"),
          ),
        ),
        PointerMangerWidget.withAll(
          child: ElevatedButton(
            onPressed: _n <= 0 ? null : () => setState(() => --_n), 
            child: const Text("-1"),
          ),
        ),
        Text(_n.toString()),
        ElevatedButton(
          onPressed: () => setState(() => ++_n), 
          child: const Text("+1"),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) => _withNegativeError 
    ? _buildWithNegativeError(context) 
    : _buildWithoutNegativeError(context);
}
