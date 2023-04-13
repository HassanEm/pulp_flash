import 'package:flutter/material.dart';
import 'package:pulp_flash/pulp_flash.dart';

void main() =>
    runApp(const PulpFlashProvider(child: MaterialApp(home: ExampleScreen())));

class ExampleScreen extends StatelessWidget {
  const ExampleScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.tips_and_updates_rounded),
        onPressed: () {
          PulpFlash.of(context).showMessage(context,
              inputMessage: Message(
                  status: FlashStatus.tips, title: 'This is a tip message'));
        },
      ),
    );
  }
}
