import 'package:audio_relay_x_client/ui/pages/home.dart';
import 'package:bootstrap/bootstrap.dart';
import 'package:flutter/material.dart';

class AudioRelayClientApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AudioRelayX',
      theme: AppTheme.light,
      home: ClientMainPage(),
    );
  }
}

void main() {
  bootstrap(app: AudioRelayClientApp(), initializeServices: () async {});
}
