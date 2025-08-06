import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/fuel_record.dart';
import '../services/database_service.dart';
import '../services/location_service.dart';
import '../providers/app_state.dart';
import 'package:geolocator/geolocator.dart';

class FuelScreen extends StatefulWidget {
  const FuelScreen({super.key});

  @override
  State<FuelScreen> createState() => _FuelScreenState();
}

class _FuelScreenState extends State<FuelScreen> {
  final _formKey = GlobalKey<FormState>();
  final _litersController = TextEditingController();
  final _amountController = TextEditingController();
  final _locationController = TextEditingController();
  
  List<FuelRecord> _fuelRecords = [];
  bool _isLoading = false;
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _loadFuelRecords();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _litersController.dispose();
    _amountController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _loadFuelRecords() async {
    setState(() => _isLoading = true);
    try {
      final records = await DatabaseService.instance.getAllFuelRecords();
      setState(() => _fuelRecords = records);
    } catch (e) {
      _showErrorSnackBar('給油記録の読み込みに失敗しました: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await LocationService.instance.getCurrentPosition();
      if (position != null) {
        setState(() => _currentPosition = position);
        final address = LocationService.instance.getApproximateAddress(
          position.latitude,
          position.longitude,
        );
        _locationController.text = address;
      }
    } catch (e) {
      print('位置情報取得エラー: $e');
    }
  }

  Future<void> _saveFuelRecord() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final appState = Provider.of<AppState>(context, listen: false);
      final currentTrip = await DatabaseService.instance.getCurrentTrip();
      
      final record = FuelRecord(
        tripId: currentTrip?.id,
        timestamp: DateTime.now(),
        location: _locationController.text.isEmpty ? null : _locationController.text,
        liters: double.parse(_litersController.text),
        amount: double.parse(_amountController.text),
      );

      await DatabaseService.instance.insertFuelRecord(record);
      
      _clearForm();
      await _loadFuelRecords();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('給油記録を保存しました')),
      );
    } catch (e) {
      _showErrorSnackBar('給油記録の保存に失敗しました: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _clearForm() {
    _litersController.clear();
    _amountController.clear();
    _locationController.clear();
    _getCurrentLocation();
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> _deleteFuelRecord(FuelRecord record) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('削除確認'),
        content: const Text('この給油記録を削除しますか？'),
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
        await DatabaseService.instance.deleteFuelRecord(record.id!);
        await _loadFuelRecords();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('給油記録を削除しました')),
        );
      } catch (e) {
        _showErrorSnackBar('削除に失敗しました: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // 給油記録入力フォーム
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      '給油記録',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    
                    // 給油量入力
                    TextFormField(
                      controller: _litersController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: '給油量 (L)',
                        hintText: '例: 50.5',
                        prefixIcon: Icon(Icons.local_gas_station),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '給油量を入力してください';
                        }
                        final liters = double.tryParse(value);
                        if (liters == null || liters <= 0) {
                          return '正しい給油量を入力してください';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // 金額入力
                    TextFormField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: '金額 (円)',
                        hintText: '例: 8500',
                        prefixIcon: Icon(Icons.attach_money),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '金額を入力してください';
                        }
                        final amount = double.tryParse(value);
                        if (amount == null || amount <= 0) {
                          return '正しい金額を入力してください';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // 場所入力
                    TextFormField(
                      controller: _locationController,
                      decoration: InputDecoration(
                        labelText: '場所',
                        hintText: '例: 東名高速道路 海老名SA',
                        prefixIcon: const Icon(Icons.location_on),
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.my_location),
                          onPressed: _getCurrentLocation,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // 単価表示
                    if (_litersController.text.isNotEmpty && _amountController.text.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '単価: ${_calculatePricePerLiter().toStringAsFixed(1)}円/L',
                          style: Theme.of(context).textTheme.titleMedium,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    const SizedBox(height: 16),
                    
                    // 保存ボタン
                    ElevatedButton(
                      onPressed: _isLoading ? null : _saveFuelRecord,
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('記録保存'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // 給油記録一覧
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _fuelRecords.isEmpty
                    ? const Center(
                        child: Text(
                          '給油記録がありません',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _fuelRecords.length,
                        itemBuilder: (context, index) {
                          final record = _fuelRecords[index];
                          return Card(
                            child: ListTile(
                              leading: const CircleAvatar(
                                child: Icon(Icons.local_gas_station),
                              ),
                              title: Text(
                                '${record.liters.toStringAsFixed(1)}L - ${NumberFormat('#,###').format(record.amount)}円',
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '単価: ${record.pricePerLiter.toStringAsFixed(1)}円/L',
                                  ),
                                  if (record.location != null)
                                    Text('場所: ${record.location}'),
                                  Text(
                                    DateFormat('yyyy/MM/dd HH:mm').format(record.timestamp),
                                  ),
                                ],
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deleteFuelRecord(record),
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

  double _calculatePricePerLiter() {
    final liters = double.tryParse(_litersController.text) ?? 0;
    final amount = double.tryParse(_amountController.text) ?? 0;
    if (liters > 0 && amount > 0) {
      return amount / liters;
    }
    return 0;
  }
}

