import 'package:flutter/material.dart';

void main() {
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

  void _addCoins(int amount) {
    setState(() {
      _coins += amount;
    });
  }

  bool _deductCoins(int amount) {
    if (_coins >= amount) {
      setState(() {
        _coins -= amount;
      });
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      _buildHomeScreen(),
      _buildTasksScreen(),
      _buildWalletScreen(),
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
                Text(
                  '$_coins',
                  style: const TextStyle(
                    color: Colors.amber,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          )
        ],
      ),
      body: pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        backgroundColor: const Color(0xFF1E1E1E),
        selectedItemColor: const Color(0xFF6C63FF),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.play_circle_filled), label: 'Watch & Tasks'),
          BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet), label: 'Wallet'),
        ],
      ),
    );
  }

  Widget _buildHomeScreen() {
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
                const Text(
                  'Available Balance',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.monetization_on, color: Colors.amber, size: 32),
                    const SizedBox(width: 8),
                    Text(
                      '$_coins Coins',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '≈ ₹${(_coins / 10).toStringAsFixed(2)} INR',
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
                ),
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: _claimedDailyBonus ? Colors.grey : const Color(0xFF6C63FF),
                ),
                onPressed: _claimedDailyBonus
                    ? null
                    : () {
                        setState(() {
                          _claimedDailyBonus = true;
                          _coins += 50;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('🎉 Claimed 50 Daily Coins!')),
                        );
                      },
                child: Text(_claimedDailyBonus ? 'Claimed' : 'Claim'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTasksScreen() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Watch Videos & Earn', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        _buildTaskTile(
          icon: Icons.video_collection,
          title: 'Watch Sponsored Ad 1',
          subtitle: 'Watch full 30s video to earn',
          reward: '+20 Coins',
          onTap: () => _simulateWatchVideo(20),
        ),
        _buildTaskTile(
          icon: Icons.video_collection,
          title: 'Watch Sponsored Ad 2',
          subtitle: 'Watch short clip to earn',
          reward: '+15 Coins',
          onTap: () => _simulateWatchVideo(15),
        ),
        _buildTaskTile(
          icon: Icons.play_arrow,
          title: 'Watch Promotional Trailer',
          subtitle: 'Complete video stream',
          reward: '+30 Coins',
          onTap: () => _simulateWatchVideo(30),
        ),
      ],
    );
  }

  Widget _buildTaskTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required String reward,
    required VoidCallback onTap,
  }) {
    return Card(
      color: const Color(0xFF1E1E1E),
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF03DAC6), size: 32),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6C63FF)),
          onPressed: onTap,
          child: Text(reward),
        ),
      ),
    );
  }

  void _simulateWatchVideo(int reward) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Playing Video Ad...'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Simulating ad stream. Please wait 3 seconds...'),
          ],
        ),
      ),
    );

    Future.delayed(const Duration(seconds: 3), () {
      Navigator.pop(context);
      _addCoins(reward);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('🎉 Video completed! You earned $reward coins!')),
      );
    });
  }

  Widget _buildWalletScreen() {
    final TextEditingController upiController = TextEditingController();

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
                Text(
                  '$_coins Coins (₹${(_coins / 10).toStringAsFixed(2)})',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.amber),
                ),
                const SizedBox(height: 8),
                const Text('10 Coins = ₹1 INR | Minimum Withdraw: 100 Coins (₹10)', style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text('Withdraw Funds via UPI', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          TextField(
            controller: upiController,
            decoration: InputDecoration(
              hintText: 'Enter UPI ID (e.g. mobile@upi)',
              filled: true,
              fillColor: const Color(0xFF1E1E1E),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6C63FF)),
              onPressed: () {
                if (upiController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a valid UPI ID')),
                  );
                  return;
                }
                if (_coins < 100) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Insufficient balance! Minimum 100 coins required.')),
                  );
                  return;
                }
                _deductCoins(100);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('✅ Withdrawal of ₹10 initiated to ${upiController.text}!')),
                );
                upiController.clear();
              },
              child: const Text('Withdraw ₹10 (100 Coins)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
