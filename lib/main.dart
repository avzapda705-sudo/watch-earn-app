import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const WatchEarnApp());
}

class WatchEarnApp extends StatelessWidget {
  const WatchEarnApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Watch & Earn Pro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF6C63FF),
        scaffoldBackgroundColor: const Color(0xFF121212),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF6C63FF),
          secondary: Color(0xFF03DAC6),
          surface: Color(0xFF1E1E1E),
        ),
      ),
      home: const MainNavigationScreen(),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  int _coins = 150;
  bool _claimedDailyBonus = false;
  int _watchedCount = 0;
  List<Map<String, dynamic>> _withdrawals = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _coins = prefs.getInt('coins') ?? 150;
      _claimedDailyBonus = prefs.getBool('claimedDailyBonus') ?? false;
      _watchedCount = prefs.getInt('watchedCount') ?? 0;
      final historyStr = prefs.getString('withdrawals') ?? '[]';
      _withdrawals = List<Map<String, dynamic>>.from(jsonDecode(historyStr));
    });
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('coins', _coins);
    await prefs.setBool('claimedDailyBonus', _claimedDailyBonus);
    await prefs.setInt('watchedCount', _watchedCount);
    await prefs.setString('withdrawals', jsonEncode(_withdrawals));
  }

  void _addCoins(int amount) {
    setState(() {
      _coins += amount;
      _watchedCount += 1;
    });
    _saveData();
  }

  void _claimDailyBonus() {
    setState(() {
      _coins += 50;
      _claimedDailyBonus = true;
    });
    _saveData();
  }

  void _submitWithdrawal(String upi, double amount) {
    final deduct = (amount * 10).toInt();
    setState(() {
      _coins -= deduct;
      _withdrawals.insert(0, {
        'upiId': upi,
        'amount': amount,
        'status': 'Processing',
        'date': DateTime.now().toString().substring(0, 16),
      });
    });
    _saveData();
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      _buildHome(),
      _buildTasks(),
      _buildWallet(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Watch & Earn Pro', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16, top: 10, bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.amber, width: 1.5),
            ),
            child: Row(
              children: [
                const Icon(Icons.monetization_on, color: Colors.amber, size: 20),
                const SizedBox(width: 6),
                Text('$_coins', style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
          )
        ],
      ),
      body: pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        backgroundColor: const Color(0xFF1E1E1E),
        selectedItemColor: const Color(0xFF6C63FF),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.play_circle_filled), label: 'Watch & Earn'),
          BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet), label: 'Wallet'),
        ],
      ),
    );
  }

  Widget _buildHome() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6C63FF), Color(0xFF3F3D56)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Available Balance', style: TextStyle(color: Colors.white70, fontSize: 14)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.monetization_on, color: Colors.amber, size: 32),
                    const SizedBox(width: 8),
                    Text('$_coins Coins', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                  ],
                ),
                const SizedBox(height: 8),
                Text('≈ ₹${(_coins / 10).toStringAsFixed(2)} INR', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text('Daily Rewards', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Card(
            color: const Color(0xFF1E1E1E),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: const Icon(Icons.card_giftcard, color: Colors.pinkAccent, size: 36),
              title: const Text('Daily Check-in Bonus', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Claim +50 coins everyday!'),
              trailing: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: _claimedDailyBonus ? Colors.grey : const Color(0xFF6C63FF), foregroundColor: Colors.white),
                onPressed: _claimedDailyBonus ? null : () {
                  _claimDailyBonus();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('🎉 Claimed 50 Daily Coins!')));
                },
                child: Text(_claimedDailyBonus ? 'Claimed' : 'Claim'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTasks() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF6C63FF), width: 3),
              ),
              child: const Icon(Icons.play_circle_fill_rounded, size: 80, color: Color(0xFF03DAC6)),
            ),
            const SizedBox(height: 24),
            const Text('Watch Video & Earn', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Watch a 30s video and earn +10 coins instantly!', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            Text('Videos Watched Today: $_watchedCount', style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6C63FF), foregroundColor: Colors.white),
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Watch Video (+10 Coins)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (ctx) => VideoPlayerScreen(
                        videoTitle: 'Sponsored Ad Stream',
                        rewardCoins: 10,
                        durationSeconds: 30, // ૩૦ સેકન્ડ પર સેટ કર્યું
                        onComplete: () => _addCoins(10),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWallet() {
    final upiController = TextEditingController();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Current Balance', style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 8),
                Text('$_coins Coins (₹${(_coins / 10).toStringAsFixed(2)})', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.amber)),
                const SizedBox(height: 8),
                const Text('10 Coins = ₹1 INR | Minimum: 100 Coins (₹10)', style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text('Withdraw Funds via UPI', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          TextField(
            controller: upiController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Enter UPI ID (e.g. mobile@upi)',
              hintStyle: const TextStyle(color: Colors.grey),
              filled: true,
              fillColor: const Color(0xFF1E1E1E),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6C63FF), foregroundColor: Colors.white),
              onPressed: () {
                final upi = upiController.text.trim();
                if (upi.isEmpty || !upi.contains('@')) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a valid UPI ID')));
                  return;
                }
                if (_coins < 100) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Minimum 100 Coins required!')));
                  return;
                }
                _submitWithdrawal(upi, 10.0);
                upiController.clear();
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Withdrawal request of ₹10 submitted for $upi!')));
              },
              child: const Text('Withdraw ₹10 (100 Coins)', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 28),
          const Text('Withdrawal History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          if (_withdrawals.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(12)),
              child: const Center(child: Text('No withdrawal history yet.', style: TextStyle(color: Colors.grey))),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _withdrawals.length,
              itemBuilder: (context, index) {
                final item = _withdrawals[index];
                return Card(
                  color: const Color(0xFF1E1E1E),
                  child: ListTile(
                    leading: const CircleAvatar(backgroundColor: Colors.amber, child: Icon(Icons.currency_rupee, color: Colors.black)),
                    title: Text('₹${item['amount']} to ${item['upiId']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(item['date'] ?? '', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    trailing: Text(item['status'] ?? 'Processing', style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class VideoPlayerScreen extends StatefulWidget {
  final String videoTitle;
  final int rewardCoins;
  final int durationSeconds;
  final VoidCallback onComplete;

  const VideoPlayerScreen({
    super.key,
    required this.videoTitle,
    required this.rewardCoins,
    required this.durationSeconds,
    required this.onComplete,
  });

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late int _remaining;
  Timer? _timer;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _remaining = widget.durationSeconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remaining > 1) {
        setState(() => _remaining--);
      } else {
        _timer?.cancel();
        setState(() {
          _remaining = 0;
          _finished = true;
        });
        widget.onComplete();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = (widget.durationSeconds - _remaining) / widget.durationSeconds;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: Text(widget.videoTitle), backgroundColor: Colors.transparent, elevation: 0, automaticallyImplyLeading: _finished),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            height: 200,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(color: const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF6C63FF), width: 2)),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(_finished ? Icons.check_circle_outline : Icons.play_circle_fill, size: 60, color: _finished ? Colors.greenAccent : const Color(0xFF6C63FF)),
                    const SizedBox(height: 10),
                    Text(_finished ? 'Video Complete!' : 'Watching Sponsored Video...', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(_finished ? '+${widget.rewardCoins} Coins Earned!' : 'Please wait till timer ends', style: TextStyle(color: _finished ? Colors.amber : Colors.grey)),
                  ],
                ),
                Positioned(top: 10, right: 10, child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(10)), child: Text(_finished ? 'Done' : '${_remaining}s', style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)))),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: LinearProgressIndicator(value: progress, backgroundColor: Colors.grey.shade800, color: const Color(0xFF03DAC6)),
          ),
          const SizedBox(height: 25),
          if (_finished)
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6C63FF), foregroundColor: Colors.white),
              onPressed: () => Navigator.pop(context),
              child: const Text('Back & Claim Coins', style: TextStyle(fontWeight: FontWeight.bold)),
            )
          else
            const Text('Do not close the screen', style: TextStyle(color: Colors.white38, fontSize: 12)),
        ],
      ),
    );
  }
}
