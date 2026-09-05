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
  StreamSubscription<TapperCaptureStatus>? _statusSubscription;
  StreamSubscription<TrebuchetEvent>? _senderEventsSubscription;

  int _pcmChunksReceived = 0;
  int _pcmBytesReceived = 0;
  int _framesEncoded = 0;
  int _packetsSent = 0;

  Future<void> init() async {
    logger.i('Initializing audio client');

    await ForgeInit.ensure();

    logger.i('Forge initialized');

    final format = AudioFormat(
      sampleRate: defaultSampleRate,
      channels: defaultChannels,
    );

    logger.i(
      'Audio format: ${format.sampleRate} Hz, ${format.channels} channel(s)',
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

    _senderEventsSubscription = _sender.events.listen((event) {
      logger.d('[Trebuchet] ${event.message}');
    });

    _statusSubscription = _tapper.statusStream.listen((status) {
      logger.i(
        '[Tapper] status=${status.status}'
        '${status.reason != null ? ' reason=${status.reason}' : ''}',
      );
    });

    _captureSubscription = _tapper.audioStream.listen(
      _handlePcmChunk,
      onError: (Object error, StackTrace stackTrace) {
        logger.e(
          '[Tapper] audio stream error',
          error: error,
          stackTrace: stackTrace,
        );
      },
      onDone: () {
        logger.w('[Tapper] audio stream closed');
      },
    );

    logger.i('Tapper audio/status listeners attached');

    await _sender.start();

    logger.i(
      'UDP sender started: '
      '${_sender.destinationAddress.address}:$defaultPort',
    );

    logger.i('Starting Tapper capture');

    await _tapper.startCapture(
      sampleRate: format.sampleRate,
      channelCount: format.channels,
      streamToDart: true,
    );

    logger.i('Tapper startCapture() completed');

    final capturing = await _tapper.isCapturing();

    logger.i(
      'Tapper isCapturing() = $capturing',
    );
  }

  void _handlePcmChunk(Uint8List chunk) {
    _pcmChunksReceived++;
    _pcmBytesReceived += chunk.length;

    logger.d(
      '[Audio] PCM chunk #$_pcmChunksReceived: '
      '${chunk.length} bytes, '
      'total=$_pcmBytesReceived bytes',
    );

    final frames = _framer.addChunk(chunk);

    logger.d(
      '[Framer] chunk #$_pcmChunksReceived produced '
      '${frames.length} frame(s)',
    );

    for (final frame in frames) {
      _framesEncoded++;

      final opusPacket = _encoder.encode(frame);

      logger.d(
        '[Opus] frame #$_framesEncoded encoded to '
        '${opusPacket.length} bytes',
      );

      _sender.send(opusPacket);

      _packetsSent++;

      logger.d(
        '[UDP] packet #$_packetsSent sent '
        '(${opusPacket.length} byte payload)',
      );
    }
  }

  Future<void> dispose() async {
    logger.i('Disposing audio client');

    await _captureSubscription?.cancel();
    await _statusSubscription?.cancel();
    await _senderEventsSubscription?.cancel();

    await _tapper.stopCapture();

    _encoder.dispose();
    _sender.dispose();

    logger.i(
      'Audio client disposed: '
      'pcmChunks=$_pcmChunksReceived, '
      'pcmBytes=$_pcmBytesReceived, '
      'frames=$_framesEncoded, '
      'packets=$_packetsSent',
    );
  }
}
