import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

class SharedMediaPayload {
  final List<SharedMediaFile> files;
  final String? text;

  SharedMediaPayload({required this.files, this.text});
}

class ShareIntentService extends ChangeNotifier {
  static final ShareIntentService instance = ShareIntentService._internal();
  ShareIntentService._internal();

  StreamSubscription? _intentSub;
  SharedMediaPayload? _pendingPayload;
  SharedMediaPayload? get pendingPayload => _pendingPayload;

  void init() {
    // Listen to media shared while app is in memory
    _intentSub = ReceiveSharingIntent.instance.getMediaStream().listen(
      (List<SharedMediaFile> value) {
        if (value.isNotEmpty) {
          _pendingPayload = SharedMediaPayload(files: value);
          notifyListeners();
        }
      },
      onError: (err) {
        debugPrint('ReceiveSharingIntent getMediaStream error: $err');
      },
    );

    // Get the media shared when app is opened from closed state
    ReceiveSharingIntent.instance.getInitialMedia().then((List<SharedMediaFile> value) {
      if (value.isNotEmpty) {
        _pendingPayload = SharedMediaPayload(files: value);
        notifyListeners();
      }
    }).catchError((err) {
      debugPrint('ReceiveSharingIntent getInitialMedia error: $err');
    });
  }

  void clearPendingPayload() {
    _pendingPayload = null;
    ReceiveSharingIntent.instance.reset();
    notifyListeners();
  }

  @override
  void dispose() {
    _intentSub?.cancel();
    super.dispose();
  }
}
