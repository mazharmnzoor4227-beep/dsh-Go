// Kokoro-82M: an offline voice that runs on the phone (sherpa-onnx).
// The model is downloaded once into the app's own folder; after that,
// spoken replies need no internet. Until the model is in place, asking
// for a Kokoro sentence fails and the phone's own voice takes over
// (companion_voice.dart), so nothing goes silent.

import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa;

/// The multi-language int8 Kokoro model (about 132 MB to download).
const kokoroModelUrl =
    'https://github.com/k2-fsa/sherpa-onnx/releases/download/tts-models/kokoro-int8-multi-lang-v1_0.tar.bz2';
const kokoroArchiveBytes = 132353410;

/// The voices offered: Hindi first (this app's person speaks Hindi/Urdu),
/// then an English one. The number is the model's speaker id.
const kokoroVoices = <(int, String)>[
  (31, 'Hindi female 1'),
  (32, 'Hindi female 2'),
  (33, 'Hindi male 1'),
  (34, 'Hindi male 2'),
  (0, 'English female'),
];

const _modelFile = 'model.int8.onnx';
const _voicesFile = 'voices.bin';
const _tokensFile = 'tokens.txt';
const _dataDir = 'espeak-ng-data';

/// The folder the model lives in.
Future<Directory> kokoroFolder() async {
  final base = await getApplicationSupportDirectory();
  return Directory('${base.path}/kokoro');
}

/// Whether every file synthesis needs is in place.
Future<bool> kokoroModelReady() async {
  final dir = await kokoroFolder();
  for (final name in [_modelFile, _voicesFile, _tokensFile]) {
    if (!await File('${dir.path}/$name').exists()) return false;
  }
  return Directory('${dir.path}/$_dataDir').exists();
}

/// Downloads and unpacks the model. [onProgress] hears 0–1 of the download;
/// unpacking is reported as 1. Throws on any failure, leaving no half model
/// behind (the partial archive is kept so a retry can resume the download).
Future<void> downloadKokoroModel(void Function(double fraction) onProgress) async {
  final dir = await kokoroFolder();
  await dir.create(recursive: true);
  final archive = File('${dir.path}/model.tar.bz2');
  final client = http.Client();
  try {
    var done = await archive.exists() ? await archive.length() : 0;
    final request = http.Request('GET', Uri.parse(kokoroModelUrl));
    if (done > 0) request.headers['range'] = 'bytes=$done-';
    final response = await client.send(request);
    if (response.statusCode != 200 && response.statusCode != 206) {
      throw StateError('HTTP ${response.statusCode}');
    }
    if (response.statusCode == 200) done = 0; // The server ignored the range: start over.
    final total = done + (response.contentLength ?? 0);
    final sink = archive.openWrite(mode: done > 0 ? FileMode.append : FileMode.write);
    try {
      await for (final chunk in response.stream) {
        sink.add(chunk);
        done += chunk.length;
        if (total > 0) onProgress((done / total).clamp(0.0, 1.0));
      }
    } finally {
      await sink.close();
    }
  } finally {
    client.close();
  }
  onProgress(1);
  await Isolate.run(() => _unpackKokoro(archive.path, dir.path));
  await archive.delete();
  if (!await kokoroModelReady()) throw StateError('model incomplete after unpacking');
}

/// Unpacks only the files synthesis needs (the archive also carries
/// Chinese/Japanese lexicons this English build never uses).
void _unpackKokoro(String archivePath, String folderPath) {
  final bytes = File(archivePath).readAsBytesSync();
  final tar = BZip2Decoder().decodeBytes(bytes);
  final decoded = TarDecoder().decodeBytes(tar);
  for (final entry in decoded) {
    if (!entry.isFile) continue;
    // Entries live under one top folder; keep the part after it.
    final slash = entry.name.indexOf('/');
    if (slash < 0) continue;
    final name = entry.name.substring(slash + 1);
    final wanted =
        name == _modelFile || name == _voicesFile || name == _tokensFile || name.startsWith('$_dataDir/');
    if (!wanted) continue;
    final out = File('$folderPath/$name');
    out.parent.createSync(recursive: true);
    out.writeAsBytesSync(entry.content as List<int>);
  }
}

/// Removes the downloaded model.
Future<void> deleteKokoroModel() async {
  final dir = await kokoroFolder();
  if (await dir.exists()) await dir.delete(recursive: true);
  _worker?.send(const _KokoroReset());
}

// ── Synthesis ──────────────────────────────────────────────────────────────

/// Which language Kokoro should read [text] as, or null when it cannot
/// (Urdu script): the caller then falls back to the phone's voice.
String? kokoroLangFor(String text) {
  var devanagari = false;
  for (final unit in text.codeUnits) {
    if (unit >= 0x0900 && unit <= 0x097F) devanagari = true;
    if (unit >= 0x0600 && unit <= 0x06FF) return null; // Urdu/Arabic script.
  }
  return devanagari ? 'hi' : 'en-us';
}

/// One sentence of [text] as WAV bytes, spoken by Kokoro voice [sid].
/// Throws when the model is not downloaded or the script is unsupported.
Future<Uint8List> synthesizeKokoro(String text, int sid) async {
  final lang = kokoroLangFor(text);
  if (lang == null) throw StateError('kokoro: unsupported script');
  if (!await kokoroModelReady()) throw StateError('kokoro: model not downloaded');
  final dir = await kokoroFolder();
  final worker = await _ensureWorker();
  final id = ++_nextId;
  final reply = Completer<Uint8List>();
  _pending[id] = reply;
  worker.send(_KokoroJob(id, text, sid, lang, dir.path));
  return reply.future.timeout(const Duration(seconds: 30), onTimeout: () {
    _pending.remove(id);
    throw TimeoutException('kokoro synthesis timed out');
  });
}

class _KokoroJob {
  const _KokoroJob(this.id, this.text, this.sid, this.lang, this.folder);
  final int id;
  final String text;
  final int sid;
  final String lang;
  final String folder;
}

class _KokoroReset {
  const _KokoroReset();
}

SendPort? _worker;
Future<SendPort>? _starting;
var _nextId = 0;
final _pending = <int, Completer<Uint8List>>{};

Future<SendPort> _ensureWorker() {
  final ready = _worker;
  if (ready != null) return Future.value(ready);
  return _starting ??= () async {
    final port = ReceivePort();
    final started = Completer<SendPort>();
    port.listen((message) {
      if (message is SendPort) {
        _worker = message;
        if (!started.isCompleted) started.complete(message);
        return;
      }
      if (message is (int, Object)) {
        final (id, result) = message;
        final reply = _pending.remove(id);
        if (reply == null || reply.isCompleted) return;
        if (result is Uint8List) {
          reply.complete(result);
        } else {
          reply.completeError(StateError('kokoro: $result'));
        }
      }
    });
    await Isolate.spawn(_kokoroWorkerMain, port.sendPort);
    return started.future;
  }();
}

void _kokoroWorkerMain(SendPort replyTo) {
  sherpa.initBindings();
  final inbox = ReceivePort();
  replyTo.send(inbox.sendPort);
  final engines = <String, sherpa.OfflineTts>{};
  inbox.listen((message) {
    if (message is _KokoroReset) {
      for (final engine in engines.values) {
        engine.free();
      }
      engines.clear();
      return;
    }
    if (message is! _KokoroJob) return;
    try {
      final engine = engines.putIfAbsent(message.lang, () {
        final config = sherpa.OfflineTtsConfig(
          model: sherpa.OfflineTtsModelConfig(
            kokoro: sherpa.OfflineTtsKokoroModelConfig(
              model: '${message.folder}/$_modelFile',
              voices: '${message.folder}/$_voicesFile',
              tokens: '${message.folder}/$_tokensFile',
              dataDir: '${message.folder}/$_dataDir',
              lang: message.lang,
            ),
            numThreads: 2,
          ),
        );
        return sherpa.OfflineTts(config);
      });
      final audio = engine.generate(text: message.text, sid: message.sid);
      replyTo.send((message.id, _wav16(audio.samples, audio.sampleRate)));
    } catch (error) {
      replyTo.send((message.id, error.toString()));
    }
  });
}

/// 16-bit mono WAV from float samples in [-1, 1].
Uint8List _wav16(Float32List samples, int sampleRate) {
  final data = ByteData(44 + samples.length * 2);
  void text(int offset, String value) {
    for (var i = 0; i < value.length; i++) {
      data.setUint8(offset + i, value.codeUnitAt(i));
    }
  }

  text(0, 'RIFF');
  data.setUint32(4, 36 + samples.length * 2, Endian.little);
  text(8, 'WAVE');
  text(12, 'fmt ');
  data.setUint32(16, 16, Endian.little);
  data.setUint16(20, 1, Endian.little);
  data.setUint16(22, 1, Endian.little);
  data.setUint32(24, sampleRate, Endian.little);
  data.setUint32(28, sampleRate * 2, Endian.little);
  data.setUint16(32, 2, Endian.little);
  data.setUint16(34, 16, Endian.little);
  text(36, 'data');
  data.setUint32(40, samples.length * 2, Endian.little);
  for (var i = 0; i < samples.length; i++) {
    data.setInt16(44 + i * 2, (samples[i].clamp(-1.0, 1.0) * 32767).round(), Endian.little);
  }
  return data.buffer.asUint8List();
}
