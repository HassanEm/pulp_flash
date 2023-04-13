# pulp_flash

`pulp_flash` is a Flutter package for displaying flash messages in your application. Flash messages are temporary messages that are typically used to provide feedback or notifications to users after an action has been performed. This package provides a simple and customizable way to show flash messages in your Flutter app.

## Features

- Display flash messages with customizable title, description, color, icon, and duration.
- Supports multiple flash messages at the same time.
- Allows pinning messages to display them indefinitely.
- Automatically handles overflow by removing older messages when the maximum number of messages is reached.
- Can be easily used in combination with the Flutter `Provider` package for state management.

![screenshot](assets/screenshot.png)

> More features are coming. It will be a pleasure to receive reports about any bugs or features that you think will help improve the package 💖. [Repository (GitHub)](https://github.com/HassanEm/pulp_flash)
## Usage

To use `pulp_flash` in your Flutter application, follow these steps:




## Usage

You just need to set up a `PulpFlashProvider` (I recommend placing it above the `MaterialApp` widget so that you don't have to worry about contexts and can easily use it wherever you need) and call it like this:
```dart
PulpFlash.of(context)
                .showMessage(context,messageThatYouWantToShow);
```
Message:
```dart
Message({
  String? title,
  String? description,
  required MessageStatus status,
  String? actionLabel,
  void Function()? onActionPressed,
  bool pinned = false,
  Duration displayDuration = const Duration(seconds: 10),
})
```


## Example

```dart
void main() => runApp(const PulpFlashProvider(
    child: MaterialApp(
      home: MyApp()));

    class MyApp extends StatelessWidget {
  const MyApp({ Key? key }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(floatingActionButton: FloatingActionButton(
      onPressed: (){
          PulpFlash.of(context)
                .showMessage(context,
                    inputMessage:Message(
                        status: MessageStatus.successful,
                        actionLabel: 'Upload new one',
                        onActionPressed: (){
                          //TODO: 
                        },
                        title: 'Hurayyyy!',
                        description:
                            "Your file successfully uploaded. you can change whenever you want in the account section.",
                      ),
                    );
      },
    ),
      
    );
  }
}
```