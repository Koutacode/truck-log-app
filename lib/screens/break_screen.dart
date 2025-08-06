import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/break_record.dart';
import '../services/database_service.dart';
import '../services/location_service.dart';
import '../providers/app_state.dart';
import 'package:geolocator/geolocator.dart';

class BreakScreen extends StatefulWidget {
  const BreakScreen({super.key});

  @override
  State<BreakScreen> createState() => _BreakScreenState();
}

class _BreakScreenState extends State<BreakScreen> {
  List<BreakRecord> _breakRecords = [];
  BreakRecord? _activeBreak;
  bool _isLoading = false;
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _loadBreakRecords();
    _loadActiveBreak();
  }

  Future<void> _loadBreakRecords() async {
    setState(() => _isLoading = true);
    try {
      final records = await DatabaseService.instance.getAllBreakRecords();
      setState(() => _breakRecords = records);
    } catch (e) {
      _showErrorSnackBar('休憩記録の読み込みに失敗しました: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadActiveBreak() async {
    try {
      final activeBreak = await DatabaseService.instance.getActiveBreakRecord();
      setState(() => _activeBreak = activeBreak);
    } catch (e) {
      print('アクティブな休憩記録の読み込みエラー: $e');
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await LocationService.instance.getCurrentPosition();
      setState(() => _currentPosition = position);
    } catch (e) {
      print('位置情報取得エラー: $e');
    }
  }

  Future<void> _startBreak(BreakType breakType) async {
    if (_activeBreak != null) {
      _showErrorSnackBar('既に休憩中です。先に現在の休憩を終了してください。');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _getCurrentLocation();
      
      final currentTrip = await DatabaseService.instance.getCurrentTrip();
      String? location;
      
      if (_currentPosition != null) {
        location = LocationService.instance.getApproximateAddress(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
        );
      }

      final record = BreakRecord(
        tripId: currentTrip?.id,
        startTime: DateTime.now(),
        breakType: breakType,
        location: location,
      );

      await DatabaseService.instance.insertBreakRecord(record);
      await _loadActiveBreak();
      await _loadBreakRecords();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${breakType.displayName}を開始しました')),
      );
    } catch (e) {
      _showErrorSnackBar('休憩開始に失敗しました: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _endBreak() async {
    if (_activeBreak == null) {
      _showErrorSnackBar('アクティブな休憩がありません');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final updatedBreak = _activeBreak!.copyWith(endTime: DateTime.now());
      await DatabaseService.instance.updateBreakRecord(updatedBreak);
      
      setState(() => _activeBreak = null);
      await _loadBreakRecords();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${_activeBreak!.breakType.displayName}を終了しました')),
      );
    } catch (e) {
      _showErrorSnackBar('休憩終了に失敗しました: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> _deleteBreakRecord(BreakRecord record) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('削除確認'),
        content: const Text('この休憩記録を削除しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('削除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await DatabaseService.instance.deleteBreakRecord(record.id!);
        await _loadBreakRecords();
        if (record.id == _activeBreak?.id) {
          setState(() => _activeBreak = null);
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('休憩記録を削除しました')),
        );
      } catch (e) {
        _showErrorSnackBar('削除に失敗しました: $e');
      }
    }
  }

  Widget _buildBreakTypeButton(BreakType breakType, IconData icon, Color color) {
    return Expanded(
      child: Card(
        child: InkWell(
          onTap: _isLoading || _activeBreak != null 
              ? null 
              : () => _startBreak(breakType),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Icon(icon, size: 32, color: color),
                const SizedBox(height: 8),
                Text(
                  breakType.displayName,
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // アクティブな休憩表示
          if (_activeBreak != null)
            Card(
              margin: const EdgeInsets.all(16),
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.coffee,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${_activeBreak!.breakType.displayName}中',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '開始時刻: ${DateFormat('HH:mm').format(_activeBreak!.startTime)}',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    if (_activeBreak!.location != null)
                      Text(
                        '場所: ${_activeBreak!.location}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _endBreak,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text('${_activeBreak!.breakType.displayName}終了'),
                    ),
                  ],
                ),
              ),
            ),

          // 休憩開始ボタン
          if (_activeBreak == null)
            Card(
              margin: const EdgeInsets.all(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      '休憩開始',
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _buildBreakTypeButton(BreakType.rest, Icons.coffee, Colors.orange),
                        const SizedBox(width: 8),
                        _buildBreakTypeButton(BreakType.sleep, Icons.bed, Colors.blue),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildBreakTypeButton(BreakType.meal, Icons.restaurant, Colors.green),
                        const SizedBox(width: 8),
                        _buildBreakTypeButton(BreakType.other, Icons.more_horiz, Colors.grey),
                      ],
                    ),
                  ],
                ),
              ),
            ),

          // 休憩記録一覧
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _breakRecords.isEmpty
                    ? const Center(
                        child: Text(
                          '休憩記録がありません',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _breakRecords.length,
                        itemBuilder: (context, index) {
                          final record = _breakRecords[index];
                          final isActive = record.isActive;
                          
                          return Card(
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: isActive 
                                    ? Colors.orange 
                                    : Colors.grey,
                                child: Icon(
                                  _getBreakTypeIcon(record.breakType),
                                  color: Colors.white,
                                ),
                              ),
                              title: Text(
                                '${record.breakType.displayName} - ${record.formattedDuration}',
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '開始: ${DateFormat('MM/dd HH:mm').format(record.startTime)}',
                                  ),
                                  if (record.endTime != null)
                                    Text(
                                      '終了: ${DateFormat('MM/dd HH:mm').format(record.endTime!)}',
                                    ),
                                  if (record.location != null)
                                    Text('場所: ${record.location}'),
                                ],
                              ),
                              trailing: isActive 
                                  ? const Icon(Icons.access_time, color: Colors.orange)
                                  : IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      onPressed: () => _deleteBreakRecord(record),
                                    ),
                              isThreeLine: true,
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  IconData _getBreakTypeIcon(BreakType breakType) {
    switch (breakType) {
      case BreakType.rest:
        return Icons.coffee;
      case BreakType.sleep:
        return Icons.bed;
      case BreakType.meal:
        return Icons.restaurant;
      case BreakType.other:
        return Icons.more_horiz;
    }
  }
}

