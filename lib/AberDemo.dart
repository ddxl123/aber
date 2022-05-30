import 'package:flutter/material.dart';

import 'Aber.dart';

class DemoController extends AbController {
  final number = 0.ab;
}

class AberDemo extends StatelessWidget {
  const AberDemo({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('first page')),
      body: Center(
        child: Column(
          children: [
            AbBuilder<DemoController>(
              controller: DemoController(),
              builder: (controller, abw) {
                print(controller.number.value);
                return Text('builder 1: ${controller.number.get(abw)}');
              },
            ),
            AbBuilder<DemoController>(
              builder: (controller, abw) {
                return Text('builder 2: ${controller.number.get(abw)}');
              },
            ),
            TextButton(
              child: const Text('increase'),
              onPressed: () {
                Aber.find<DemoController>().number.refreshEasy((oldValue) => oldValue + 1);
              },
            ),
            TextButton(
              child: const Text('second page'),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (ctx) => const SecondPage()));
              },
            ),
          ],
        ),
      ),
    );
  }
}

class SecondPage extends StatelessWidget {
  const SecondPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('first page')),
      body: Center(
        child: Column(
          children: [
            AbBuilder<DemoController>(
              builder: (controller, abw) {
                return Text('builder 3: ${controller.number.get(abw)}');
              },
            ),
            TextButton(
              child: const Text('increase'),
              onPressed: () {
                Aber.find<DemoController>().number.refreshEasy((oldValue) => oldValue + 1);
              },
            ),
            TextButton(
              child: const Text('back'),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
