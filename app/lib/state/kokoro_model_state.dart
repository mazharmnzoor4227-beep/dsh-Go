// The Kokoro offline voice model: whether it is on the phone, and the
// one-time download that puts it there (companion/kokoro_voice.dart).

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../companion/kokoro_voice.dart';

enum KokoroModelStatus { absent, downloading, preparing, ready, failed }

@immutable
class KokoroModelState {
  const KokoroModelState({this.status = KokoroModelStatus.absent, this.fraction = 0});

  final KokoroModelStatus status;

  /// Download progress 0–1 while [status] is downloading.
  final double fraction;

  bool get busy => status == KokoroModelStatus.downloading || status == KokoroModelStatus.preparing;

  KokoroModelState copyWith({KokoroModelStatus? status, double? fraction}) =>
      KokoroModelState(status: status ?? this.status, fraction: fraction ?? this.fraction);
}

class KokoroModelController extends Notifier<KokoroModelState> {
  @override
  KokoroModelState build() {
    Future.microtask(refresh);
    return const KokoroModelState();
  }

  Future<void> refresh() async {
    if (state.busy) return;
    state = KokoroModelState(
      status: await kokoroModelReady() ? KokoroModelStatus.ready : KokoroModelStatus.absent,
    );
  }

  Future<void> download() async {
    if (state.busy) return;
    state = const KokoroModelState(status: KokoroModelStatus.downloading);
    try {
      await downloadKokoroModel((fraction) {
        state = KokoroModelState(
          status: fraction >= 1 ? KokoroModelStatus.preparing : KokoroModelStatus.downloading,
          fraction: fraction,
        );
      });
      state = const KokoroModelState(status: KokoroModelStatus.ready, fraction: 1);
    } catch (_) {
      state = const KokoroModelState(status: KokoroModelStatus.failed);
    }
  }

  Future<void> delete() async {
    if (state.busy) return;
    await deleteKokoroModel();
    state = const KokoroModelState();
  }
}

final kokoroModelProvider = NotifierProvider<KokoroModelController, KokoroModelState>(KokoroModelController.new);
