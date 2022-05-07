import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pulp_flash/pulp_flash.dart';

void main() => runApp(ChangeNotifierProvider<PulpFlash>(
    builder: (context, child) => child!,
    create: (context) => PulpFlash(),
    child: const MaterialApp(home: ExampleScreen())));

class ExampleScreen extends StatelessWidget {
  const ExampleScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.tips_and_updates_rounded),
        onPressed: () {
          Provider.of<PulpFlash>(context, listen: false).showMessage(context,
              inputMessage: Message(
                  status: FlashStatus.tips, title: 'This is a tip message'));
        },
      ),
    );
  }
}
