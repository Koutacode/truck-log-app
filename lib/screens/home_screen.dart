import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import 'fuel_screen.dart';
import 'break_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('長距離トラック運行ログ'),
        actions: [
          Consumer<AppState>(
            builder: (context, appState, child) {
              return IconButton(
                icon: Icon(
                  appState.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                ),
                onPressed: () => appState.toggleDarkMode(),
              );
            },
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'ホーム',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_gas_station),
            label: '給油',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.coffee),
            label: '休憩',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory),
            label: '荷物',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt),
            label: '経費',
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return _buildHomeTab();
      case 1:
        return const FuelScreen();
      case 2:
        return const BreakScreen();
      case 3:
        return _buildCargoTab();
      case 4:
        return _buildExpenseTab();
      default:
        return _buildHomeTab();
    }
  }

  Widget _buildHomeTab() {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 運行状況カード
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '運行状況',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      if (appState.isOnTrip) ...[
                        Text('目的地: ${appState.currentDestination ?? "未設定"}'),
                        Text('運行時間: ${appState.tripDuration}'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => _showEndTripDialog(context, appState),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('運行終了'),
                        ),
                      ] else ...[
                        const Text('運行中ではありません'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => _showStartTripDialog(context, appState),
                          child: const Text('運行開始'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // クイックアクションボタン
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  children: [
                    _buildQuickActionCard(
                      context,
                      '出発記録',
                      Icons.play_arrow,
                      Colors.green,
                      () => _recordDeparture(),
                    ),
                    _buildQuickActionCard(
                      context,
                      '到着記録',
                      Icons.stop,
                      Colors.red,
                      () => _recordArrival(),
                    ),
                    _buildQuickActionCard(
                      context,
                      '給油記録',
                      Icons.local_gas_station,
                      Colors.blue,
                      () => setState(() => _selectedIndex = 1),
                    ),
                    _buildQuickActionCard(
                      context,
                      '休憩開始',
                      Icons.coffee,
                      Colors.orange,
                      () => setState(() => _selectedIndex = 2),
                    ),
                    _buildQuickActionCard(
                      context,
                      '音声入力',
                      Icons.mic,
                      Colors.purple,
                      () => _startVoiceInput(),
                    ),
                    _buildQuickActionCard(
                      context,
                      'レポート',
                      Icons.assessment,
                      Colors.teal,
                      () => _showReports(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickActionCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 48,
                color: color,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCargoTab() {
    return const Center(
      child: Text('荷物記録画面（実装予定）'),
    );
  }

  Widget _buildExpenseTab() {
    return const Center(
      child: Text('経費記録画面（実装予定）'),
    );
  }

  void _showStartTripDialog(BuildContext context, AppState appState) {
    final controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('運行開始'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: '目的地',
            hintText: '例: 大阪府大阪市',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                appState.startTrip(controller.text);
                Navigator.pop(context);
              }
            },
            child: const Text('開始'),
          ),
        ],
      ),
    );
  }

  void _showEndTripDialog(BuildContext context, AppState appState) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('運行終了'),
        content: const Text('運行を終了しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () {
              appState.endTrip();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('終了'),
          ),
        ],
      ),
    );
  }

  void _recordDeparture() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('出発記録機能（実装予定）')),
    );
  }

  void _recordArrival() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('到着記録機能（実装予定）')),
    );
  }

  void _startVoiceInput() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('音声入力機能（実装予定）')),
    );
  }

  void _showReports() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('レポート機能（実装予定）')),
    );
  }
}

