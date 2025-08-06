import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationService {
  static final LocationService instance = LocationService._init();
  LocationService._init();

  // 位置情報の権限を確認・要求
  Future<bool> requestLocationPermission() async {
    // アプリレベルの権限確認
    var status = await Permission.location.status;
    
    if (status.isDenied) {
      status = await Permission.location.request();
    }
    
    if (status.isPermanentlyDenied) {
      // 設定画面を開く
      await openAppSettings();
      return false;
    }
    
    if (!status.isGranted) {
      return false;
    }

    // Geolocatorレベルの権限確認
    LocationPermission permission = await Geolocator.checkPermission();
    
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    
    if (permission == LocationPermission.deniedForever) {
      return false;
    }
    
    return permission == LocationPermission.whileInUse || 
           permission == LocationPermission.always;
  }

  // 位置情報サービスが有効かチェック
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  // 現在位置を取得
  Future<Position?> getCurrentPosition() async {
    try {
      // 権限チェック
      if (!await requestLocationPermission()) {
        throw Exception('位置情報の権限が許可されていません');
      }

      // サービス有効性チェック
      if (!await isLocationServiceEnabled()) {
        throw Exception('位置情報サービスが無効です');
      }

      // 現在位置取得
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      return position;
    } catch (e) {
      print('位置情報取得エラー: $e');
      return null;
    }
  }

  // 高精度な現在位置を取得（時間をかけてでも正確な位置を取得）
  Future<Position?> getHighAccuracyPosition() async {
    try {
      if (!await requestLocationPermission()) {
        throw Exception('位置情報の権限が許可されていません');
      }

      if (!await isLocationServiceEnabled()) {
        throw Exception('位置情報サービスが無効です');
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
        timeLimit: const Duration(seconds: 30),
      );

      return position;
    } catch (e) {
      print('高精度位置情報取得エラー: $e');
      return null;
    }
  }

  // 位置情報の変更を監視
  Stream<Position> getPositionStream() {
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // 10メートル移動したら更新
    );

    return Geolocator.getPositionStream(locationSettings: locationSettings);
  }

  // 2点間の距離を計算（メートル単位）
  double calculateDistance(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    return Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }

  // 2点間の方位を計算（度単位）
  double calculateBearing(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    return Geolocator.bearingBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }

  // 位置情報を文字列形式で取得
  String formatPosition(Position position) {
    return '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
  }

  // 位置情報を詳細な文字列形式で取得
  String formatDetailedPosition(Position position) {
    return '''
緯度: ${position.latitude.toStringAsFixed(6)}
経度: ${position.longitude.toStringAsFixed(6)}
精度: ${position.accuracy.toStringAsFixed(1)}m
高度: ${position.altitude.toStringAsFixed(1)}m
速度: ${(position.speed * 3.6).toStringAsFixed(1)}km/h
方位: ${position.heading.toStringAsFixed(1)}°
取得時刻: ${DateTime.fromMillisecondsSinceEpoch(position.timestamp.millisecondsSinceEpoch).toString()}
''';
  }

  // 簡易的な住所取得（緯度経度から大まかな地域を推定）
  String getApproximateAddress(double latitude, double longitude) {
    // 日本の主要都市の緯度経度範囲で大まかな地域を判定
    if (latitude >= 35.5 && latitude <= 35.8 && longitude >= 139.5 && longitude <= 139.9) {
      return '東京都内';
    } else if (latitude >= 34.6 && latitude <= 34.8 && longitude >= 135.4 && longitude <= 135.6) {
      return '大阪府内';
    } else if (latitude >= 35.1 && latitude <= 35.3 && longitude >= 136.8 && longitude <= 137.0) {
      return '愛知県内';
    } else if (latitude >= 35.0 && latitude <= 35.2 && longitude >= 135.7 && longitude <= 135.9) {
      return '京都府内';
    } else if (latitude >= 34.3 && latitude <= 34.5 && longitude >= 132.4 && longitude <= 132.6) {
      return '広島県内';
    } else if (latitude >= 33.5 && latitude <= 33.7 && longitude >= 130.3 && longitude <= 130.5) {
      return '福岡県内';
    } else if (latitude >= 43.0 && latitude <= 43.2 && longitude >= 141.3 && longitude <= 141.5) {
      return '北海道札幌市内';
    } else if (latitude >= 38.2 && latitude <= 38.4 && longitude >= 140.8 && longitude <= 141.0) {
      return '宮城県内';
    } else {
      // 地方別の大まかな判定
      if (latitude >= 41.0) {
        return '北海道地方';
      } else if (latitude >= 38.0) {
        return '東北地方';
      } else if (latitude >= 35.0 && longitude >= 138.0) {
        return '関東地方';
      } else if (latitude >= 35.0 && longitude >= 136.0) {
        return '中部地方';
      } else if (latitude >= 33.0 && longitude >= 134.0) {
        return '関西地方';
      } else if (latitude >= 33.0 && longitude >= 131.0) {
        return '中国地方';
      } else if (latitude >= 32.0) {
        return '九州地方';
      } else {
        return '日本国内';
      }
    }
  }

  // 移動速度を計算（km/h）
  double calculateSpeed(Position position) {
    return position.speed * 3.6; // m/s を km/h に変換
  }

  // 位置情報が有効な範囲内かチェック（日本国内）
  bool isValidJapanPosition(double latitude, double longitude) {
    // 日本の大まかな緯度経度範囲
    return latitude >= 24.0 && latitude <= 46.0 && 
           longitude >= 123.0 && longitude <= 146.0;
  }

  // GPS精度が十分かチェック
  bool isAccuracyGood(Position position) {
    return position.accuracy <= 20.0; // 20メートル以内なら良好
  }

  // 位置情報の設定画面を開く
  Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }

  // アプリの設定画面を開く
  Future<void> openAppSettings() async {
    await openAppSettings();
  }
}

