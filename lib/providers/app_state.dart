import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppState extends ChangeNotifier {
  bool _isDarkMode = false;
  bool _isOnTrip = false;
  DateTime? _tripStartTime;
  String? _currentDestination;

  bool get isDarkMode => _isDarkMode;
  bool get isOnTrip => _isOnTrip;
  DateTime? get tripStartTime => _tripStartTime;
  String? get currentDestination => _currentDestination;

  AppState() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('isDarkMode') ?? false;
    _isOnTrip = prefs.getBool('isOnTrip') ?? false;
    
    final tripStartTimeString = prefs.getString('tripStartTime');
    if (tripStartTimeString != null) {
      _tripStartTime = DateTime.parse(tripStartTimeString);
    }
    
    _currentDestination = prefs.getString('currentDestination');
    notifyListeners();
  }

  Future<void> toggleDarkMode() async {
    _isDarkMode = !_isDarkMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', _isDarkMode);
    notifyListeners();
  }

  Future<void> startTrip(String destination) async {
    _isOnTrip = true;
    _tripStartTime = DateTime.now();
    _currentDestination = destination;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isOnTrip', _isOnTrip);
    await prefs.setString('tripStartTime', _tripStartTime!.toIso8601String());
    await prefs.setString('currentDestination', _currentDestination!);
    
    notifyListeners();
  }

  Future<void> endTrip() async {
    _isOnTrip = false;
    _tripStartTime = null;
    _currentDestination = null;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isOnTrip', _isOnTrip);
    await prefs.remove('tripStartTime');
    await prefs.remove('currentDestination');
    
    notifyListeners();
  }

  String get tripDuration {
    if (_tripStartTime == null) return '00:00:00';
    
    final duration = DateTime.now().difference(_tripStartTime!);
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    
    return '$hours:$minutes:$seconds';
  }
}

