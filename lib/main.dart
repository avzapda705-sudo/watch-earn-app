import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
    if (FirebaseAuth.instance.currentUser == null) {
      await FirebaseAuth.instance.signInAnonymously();
    }
  } catch (e) {
    debugPrint("Firebase init error: $e");
  }
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
  String? _userId;

  @override
  void initState() {
    super.initState();
    _initUserData();
  }

  void _initUserData() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _userId = user.uid;
      FirebaseFirestore.instance.collection('users').doc(_userId).snapshots().listen((doc) {
        if (doc.exists && mounted) {
          final data = doc.data();
          setState(() {
            _coins = data?['coins'] ?? 150;
            _claimedDailyBonus = data?['claimedDailyBonus'] ?? false;
            _watchedCount = data?['watchedCount'] ?? 0;
          });
        } else if (!doc.exists) {
          FirebaseFirestore.instance.collection('users').doc(_userId).set({
            'coins': 150,
            'claimedDailyBonus': false,
            'watchedCount': 0,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      });
    }
  }

  void _addCoins(int amount) {
    if (_userId != null) {
      FirebaseFirestore.instance.collection('users').doc(_userId).update({
        'coins': FieldValue.increment(amount),
        'watchedCount': FieldValue.increment(1),
      });
    } else {
      setState(() {
        _coins += amount;
        _watchedCount += 1;
      });
    }
  }

  void _claimDailyBonus() {
    if (_userId != null) {
      FirebaseFirestore.instance.collection('users').doc(_userId).update({
        'coins': FieldValue.increment(50),
        'claimedDailyBonus': true,
      });
    } else {
      setState(() {
        _coins += 50;
        _claimedDailyBonus = true;
      });
    }
  }

  void _submitWithdrawal(String upi, double amount) {
    final coinsToDeduct = (amount * 10).toInt();
    if (_userId != null) {
      FirebaseFirestore.instance.collection('users').doc(_userId).update({
        'coins': FieldValue.increment(-coinsToDeduct),
      });

      FirebaseFirestore.instance.collection('withdrawals').add({
        'userId': _userId,
        'upiId': upi,
        'amount': amount,
        'status': 'Processing',
        'timestamp': FieldValue.serverTimestamp(),
      });
    } else {
      setState(() {
        _coins -= coinsToDeduct;
      });
    }
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
          BottomNavigationBarItem(icon: Icon(Icons.play_circle_filled), label: 'Watch & Earn'),
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
                const Text('Available Balance', style: TextStyle(color: Colors.white70, fontSize: 14)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.monetization_on, color: Colors.amber, size: 32),
                    const SizedBox(width: 8),
                    Text(
                      '$_coins Coins',
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
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
                  foregroundColor: Colors.white,
                ),
                onPressed: _claimedDailyBonus
                    ? null
                    : () {
                        _claimDailyBonus();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('🎉 Claimed 50 Daily Coins!')),
                        );
                      },
                child: Text(_claimedDailyBonus ? 'Claimed' : 'Claim', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTasksScreen() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
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
            const Text(
              'Watch Video & Earn',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Watch a short video completely and earn +10 coins instantly!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white12),
              ),
              child: Text(
                'Videos Watched Today: $_watchedCount',
                style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C63FF),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 4,
                ),
                icon: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 28),
                label: const Text(
                  'Watch Video (+10 Coins)',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => VideoPlayerScreen(
                        videoTitle: 'Sponsored Ad Stream',
                        rewardCoins: 10,
                        durationSeconds: 15,
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
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Enter UPI ID (e.g. mobile@upi)',
              hintStyle: const TextStyle(color: Colors.grey),
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
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C63FF),
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                final upi = upiController.text.trim();
                if (upi.isEmpty || !upi.contains('@')) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a valid UPI ID (e.g. name@upi)')),
                  );
                  return;
                }
                if (_coins < 100) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Minimum 100 Coins (₹10) required to withdraw!')),
                  );
                  return;
                }
                _submitWithdrawal(upi, 10.0);
                upiController.clear();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('✅ Withdrawal request of ₹10 submitted for $upi!')),
                );
              },
              child: const Text('Withdraw ₹10 (100 Coins)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ),
          const SizedBox(height: 28),
          const Text('Withdrawal History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          if (_userId == null)
            const Center(child: Text('Loading History...', style: TextStyle(color: Colors.grey)))
          else
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('withdrawals')
                  .where('userId', isEqualTo: _userId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Text('No withdrawal history yet.', style: TextStyle(color: Colors.grey)),
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final item = snapshot.data!.docs[index].data() as Map<String, dynamic>;
                    return Card(
                      color: const Color(0xFF1E1E1E),
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Colors.amber,
                          child: Icon(Icons.currency_rupee, color: Colors.black),
                        ),
                        title: Text('₹${item['amount']} to ${item['upiId']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(item['status'] ?? 'Processing', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.orange),
                          ),
                          child: Text(
                            item['status'] ?? 'Processing',
                            style: const TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    );
                  },
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
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remaining > 1) {
        setState(() {
          _remaining--;
        });
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
      appBar: AppBar(
        title: Text(widget.videoTitle),
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: _finished,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            height: 220,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF6C63FF), width: 2)               ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _finished ? Icons.check_circle_outline : Icons.play_circle_fill,
                      size: 64,
                      color: _finished ? Colors.greenAccent : const Color(0xFF6C63FF),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _finished ? 'Video Complete!' : 'Watching Sponsored Video Stream...',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _finished ? '+${widget.rewardCoins} Coins Earned!' : 'Please watch till end to claim coins',
                      style: TextStyle(color: _finished ? Colors.amber : Colors.grey),
                    ),
                  ],
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _finished ? 'Done' : 'Reward in: ${_remaining}s',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.amber),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey.shade800,
              color: const Color(0xFF03DAC6),
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 30),
          if (_finished)
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C63FF),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text('Back & Claim Coins', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            )
          else
            const Text('Do not close the video or reward will be lost', style: TextStyle(color: Colors.white38, fontSize: 12)),
        ],
      ),
    );
  }
}
