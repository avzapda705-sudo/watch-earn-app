import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  bool _claimedReferralBonus = false;
  int _watchedCount = 0;
  final String _myReferralCode = "EARN705";
  List<Map<String, dynamic>> _withdrawals = [];
  final TextEditingController _friendReferralController = TextEditingController();

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
      _claimedReferralBonus = prefs.getBool('claimedReferralBonus') ?? false;
      _watchedCount = prefs.getInt('watchedCount') ?? 0;
      final historyStr = prefs.getString('withdrawals') ?? '[]';
      _withdrawals = List<Map<String, dynamic>>.from(jsonDecode(historyStr));
    });
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('coins', _coins);
    await prefs.setBool('claimedDailyBonus', _claimedDailyBonus);
    await prefs.setBool('claimedReferralBonus', _claimedReferralBonus);
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

  void _redeemReferralCode() {
    final code = _friendReferralController.text.trim().toUpperCase();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a referral code')));
      return;
    }
    if (code == _myReferralCode) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('You cannot use your own referral code!')));
      return;
    }
    if (_claimedReferralBonus) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Referral bonus already claimed!')));
      return;
    }

    setState(() {
      _coins += 100; // 100+ બોનસ કોઈન્સ
      _claimedReferralBonus = true;
    });
    _saveData();
    _friendReferralController.clear();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('🎉 Congratulations! +100 Coins Added!')));
  }

  void _submitWithdrawal(String upi, int coinsToWithdraw) {
    final double rupees = coinsToWithdraw / 10.0;
    setState(() {
      _coins -= coinsToWithdraw;
      _withdrawals.insert(0, {
        'upiId': upi,
        'coins': coinsToWithdraw,
        'amount': rupees,
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
          const SizedBox(height: 24),
          const Text('Refer & Earn Program', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Your Referral Code', style: TextStyle(color: Colors.grey, fontSize: 13)),
                        const SizedBox(height: 4),
                        Text(_myReferralCode, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF03DAC6), letterSpacing: 1.5)),
                      ],
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6C63FF),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: _myReferralCode));
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Referral Code Copied!')));
                      },
                      icon: const Icon(Icons.copy, size: 18),
                      label: const Text('Copy'),
                    )
                  ],
                ),
                const Divider(height: 28, color: Colors.white12),
                const Text('Have a friend\'s code?', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _friendReferralController,
                        enabled: !_claimedReferralBonus,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: _claimedReferralBonus ? 'Code Already Applied' : 'Enter referral code',
                          hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                          filled: true,
                          fillColor: const Color(0xFF121212),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _claimedReferralBonus ? Colors.grey : const Color(0xFF03DAC6),
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: _claimedReferralBonus ? null : _redeemReferralCode,
                      child: Text(_claimedReferralBonus ? 'Applied' : 'Apply (+100)'),
                    ),
                  ],
                ),
              ],
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
                        durationSeconds: 30,
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
    final coinsController = TextEditingController(text: '200');

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
                const Text('10 Coins = ₹1 INR | Minimum Withdrawal: 200 Coins (₹20)', style: TextStyle(fontSize: 12, color: Colors.grey)),
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
          const SizedBox(height: 12),
          TextField(
            controller: coinsController,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Coins to Withdraw (Minimum 200)',
              labelStyle: const TextStyle(color: Colors.grey),
              hintText: 'e.g. 200, 500, 1000',
              hintStyle: const TextStyle(color: Colors.white24),
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
                final int? requestedCoins = int.tryParse(coinsController.text.trim());

                if (upi.isEmpty || !upi.contains('@')) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a valid UPI ID')));
                  return;
                }
                if (requestedCoins == null || requestedCoins < 200) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Minimum withdrawal is 200 Coins (₹20)!')));
                  return;
                }
                if (_coins < requestedCoins) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Insufficient balance! You have $_coins coins.')));
                  return;
                }

                _submitWithdrawal(upi, requestedCoins);
                upiController.clear();
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Withdrawal request of ₹${(requestedCoins / 10).toStringAsFixed(2)} ($requestedCoins coins) submitted!'),
                ));
              },
              child: const Text('Submit Withdrawal Request', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
                    title: Text('₹${item['amount']} (${item['coins']} Coins)', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle
