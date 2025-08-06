import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';

class VoiceService {
  static final VoiceService instance = VoiceService._init();
  VoiceService._init();

  final SpeechToText _speechToText = SpeechToText();
  bool _isInitialized = false;
  bool _isListening = false;

  bool get isInitialized => _isInitialized;
  bool get isListening => _isListening;

  // 音声認識の初期化
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      // マイクの権限を確認・要求
      var status = await Permission.microphone.status;
      if (status.isDenied) {
        status = await Permission.microphone.request();
      }

      if (!status.isGranted) {
        throw Exception('マイクの権限が許可されていません');
      }

      // SpeechToTextの初期化
      _isInitialized = await _speechToText.initialize(
        onError: (error) => print('音声認識エラー: $error'),
        onStatus: (status) => print('音声認識ステータス: $status'),
      );

      return _isInitialized;
    } catch (e) {
      print('音声認識初期化エラー: $e');
      return false;
    }
  }

  // 音声認識開始
  Future<void> startListening({
    required Function(String) onResult,
    String localeId = 'ja_JP',
  }) async {
    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) {
        throw Exception('音声認識の初期化に失敗しました');
      }
    }

    if (_isListening) {
      await stopListening();
    }

    try {
      await _speechToText.listen(
        onResult: (result) {
          onResult(result.recognizedWords);
        },
        localeId: localeId,
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        partialResults: true,
        cancelOnError: true,
      );
      _isListening = true;
    } catch (e) {
      print('音声認識開始エラー: $e');
      throw Exception('音声認識の開始に失敗しました: $e');
    }
  }

  // 音声認識停止
  Future<void> stopListening() async {
    if (_isListening) {
      await _speechToText.stop();
      _isListening = false;
    }
  }

  // 利用可能な言語一覧を取得
  Future<List<LocaleName>> getAvailableLocales() async {
    if (!_isInitialized) {
      await initialize();
    }
    return await _speechToText.locales();
  }

  // 音声認識が利用可能かチェック
  Future<bool> isAvailable() async {
    return await _speechToText.initialize();
  }

  // 音声コマンドを解析
  VoiceCommand? parseVoiceCommand(String text) {
    final lowerText = text.toLowerCase();
    
    // 給油関連
    if (lowerText.contains('給油') || lowerText.contains('ガソリン') || lowerText.contains('燃料')) {
      return VoiceCommand(
        type: VoiceCommandType.fuel,
        originalText: text,
        confidence: _calculateConfidence(lowerText, ['給油', 'ガソリン', '燃料']),
      );
    }
    
    // 休憩関連
    if (lowerText.contains('休憩') || lowerText.contains('仮眠') || lowerText.contains('食事')) {
      BreakType? breakType;
      if (lowerText.contains('仮眠')) {
        breakType = BreakType.sleep;
      } else if (lowerText.contains('食事')) {
        breakType = BreakType.meal;
      } else {
        breakType = BreakType.rest;
      }
      
      return VoiceCommand(
        type: VoiceCommandType.breakStart,
        originalText: text,
        confidence: _calculateConfidence(lowerText, ['休憩', '仮眠', '食事']),
        data: {'breakType': breakType},
      );
    }
    
    // 休憩終了
    if (lowerText.contains('終了') || lowerText.contains('おわり')) {
      return VoiceCommand(
        type: VoiceCommandType.breakEnd,
        originalText: text,
        confidence: _calculateConfidence(lowerText, ['終了', 'おわり']),
      );
    }
    
    // 出発関連
    if (lowerText.contains('出発') || lowerText.contains('スタート')) {
      return VoiceCommand(
        type: VoiceCommandType.departure,
        originalText: text,
        confidence: _calculateConfidence(lowerText, ['出発', 'スタート']),
      );
    }
    
    // 到着関連
    if (lowerText.contains('到着') || lowerText.contains('着いた')) {
      return VoiceCommand(
        type: VoiceCommandType.arrival,
        originalText: text,
        confidence: _calculateConfidence(lowerText, ['到着', '着いた']),
      );
    }
    
    return null;
  }

  double _calculateConfidence(String text, List<String> keywords) {
    int matches = 0;
    for (String keyword in keywords) {
      if (text.contains(keyword)) {
        matches++;
      }
    }
    return matches / keywords.length;
  }

  void dispose() {
    _speechToText.cancel();
  }
}

enum VoiceCommandType {
  fuel,
  breakStart,
  breakEnd,
  departure,
  arrival,
  expense,
  cargo,
}

class VoiceCommand {
  final VoiceCommandType type;
  final String originalText;
  final double confidence;
  final Map<String, dynamic>? data;

  VoiceCommand({
    required this.type,
    required this.originalText,
    required this.confidence,
    this.data,
  });

  String get displayName {
    switch (type) {
      case VoiceCommandType.fuel:
        return '給油記録';
      case VoiceCommandType.breakStart:
        return '休憩開始';
      case VoiceCommandType.breakEnd:
        return '休憩終了';
      case VoiceCommandType.departure:
        return '出発記録';
      case VoiceCommandType.arrival:
        return '到着記録';
      case VoiceCommandType.expense:
        return '経費記録';
      case VoiceCommandType.cargo:
        return '荷物記録';
    }
  }
}

// BreakTypeの定義（他のファイルからインポートする場合は削除）
enum BreakType {
  rest('休憩'),
  sleep('仮眠'),
  meal('食事'),
  other('その他');

  const BreakType(this.displayName);
  final String displayName;
}

