import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:bootstrap/bootstrap.dart';
import 'package:forge/forge.dart';
import 'package:framer/framer.dart';
import 'package:tapper/tapper.dart';
import 'package:trebuchet/trebuchet.dart';

class AudioClient {
  AudioClient({
    required String destinationAddress,
  }) : _sender = TrebuchetSender(
          destinationAddress: InternetAddress(destinationAddress),
          destinationPort: defaultPort,
        );

  final Tapper _tapper = Tapper();
  late final PcmFramer _framer;
  late final ForgeEncoder _encoder;
  final TrebuchetSender _sender;

  StreamSubscription<Uint8List>? _captureSubscription;

  Future<void> init() async {
    await ForgeInit.ensure();

    final format = AudioFormat(
      sampleRate: defaultSampleRate,
      channels: defaultChannels,
    );

    _framer = PcmFramer.forDuration(
      format: format,
      frameDuration: const Duration(milliseconds: 20),
    );

    _encoder = ForgeEncoder(
      sampleRate: format.sampleRate,
      channels: format.channels,
      samplesPerChannel: format.sampleRate ~/ 50,
      application: Application.audio,
    );

    _captureSubscription = _tapper.audioStream.listen(_handlePcmChunk);

    await _tapper.startCapture(
      sampleRate: format.sampleRate,
      channelCount: format.channels,
      streamToDart: true,
    );
    _sender.start();
  }

  void _handlePcmChunk(Uint8List chunk) {
    for (final frame in _framer.addChunk(chunk)) {
      final Uint8List opusPacket = _encoder.encode(frame);
      _sender.send(opusPacket);
    }
  }

  Future<void> dispose() async {
    await _captureSubscription?.cancel();
    await _tapper.stopCapture();
    _encoder.dispose();
  }
}
