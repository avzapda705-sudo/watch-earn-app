import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

bool isFirebaseReady = false;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
    await FirebaseAuth.instance.signInAnonymously();
    isFirebaseReady = true;
  } catch (e) {
    isFirebaseReady = false;
    debugPrint('Firebase init error: $e');
  }
  runApp(const WatchAndEarnApp());
}

class WatchAndEarnApp extends StatelessWidget {
  const WatchAndEarnApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Watch & Earn Pro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F1015),
        primaryColor: const Color(0xFFF5B300),
        cardColor: const Color(0xFF1B1D24),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0F1015),
          elevation: 0,
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
  int _balance = 0;
  bool _claimedDaily = false;
  bool _appliedReferral = false;
  int _remainingAds = 15;
  final String _myReferralCode = "PRO708058";
  final List<Map<String, dynamic>> _history = [];
  String? _userId;

  final TextEditingController _referralInputController = TextEditingController();
  final TextEditingController _upiController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _referralInputController.dispose();
    _upiController.dispose();
    super.dispose();
  }

  void _loadUserData() async {
    if (!isFirebaseReady) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _userId = user.uid;
      final doc = await FirebaseFirestore.instance.collection('users').doc(_userId).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        setState(() {
          _balance = data['balance'] ?? 0;
          _claimedDaily = data['claimedDaily'] ?? false;
          _appliedReferral = data['appliedReferral'] ?? false;
          _remainingAds = data['remainingAds'] ?? 15;
        });
      } else {
        await FirebaseFirestore.instance.collection('users').doc(_userId).set({
          'balance': 0,
          'claimedDaily': false,
          'appliedReferral': false,
          'remainingAds': 15,
        });
      }
    }
  }

  void _syncFirebase() async {
    if (isFirebaseReady && _userId != null) {
      await FirebaseFirestore.instance.collection('users').doc(_userId).set({
        'balance': _balance,
        'claimedDaily': _claimedDaily,
        'appliedReferral': _appliedReferral,
        'remainingAds': _remainingAds,
      }, SetOptions(merge: true));
    }
  }

  void _claimDailyBonus() {
    if (_claimedDaily) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Daily bonus already claimed for today!')),
      );
      return;
    }
    setState(() {
      _balance += 25;
      _claimedDaily = true;
      _history.insert(0, {'title': 'Daily Bonus', 'coins': '+25', 'time': 'Just now'});
    });
    _syncFirebase();
  }

  void _watchVideoAd() {
    if (_remainingAds <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Daily ad limit reached. Come back tomorrow!')),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E2029),
          title: const Text('Playing Video Ad', style: TextStyle(color: Colors.white)),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Color(0xFFF5B300)),
              SizedBox(height: 16),
              Text('Watch the complete video to claim 10 coins.', style: TextStyle(color: Colors.white70)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  _balance += 10;
                  _remainingAds -= 1;
                  _history.insert(0, {'title': 'Watched Video Ad', 'coins': '+10', 'time': 'Just now'});
                });
                _syncFirebase();
              },
              child: const Text('Claim Reward', style: TextStyle(color: Color(0xFFF5B300))),
            ),
          ],
        );
      },
    );
  }

  void _applyReferralCode() {
    if (_appliedReferral) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Referral code already claimed!')),
      );
      return;
    }
    final code = _referralInputController.text.trim();
    if (code.isEmpty) return;

    setState(() {
      _balance += 50;
      _appliedReferral = true;
      _history.insert(0, {'title': 'Referral Bonus', 'coins': '+50', 'time': 'Just now'});
    });
    _referralInputController.clear();
    _syncFirebase();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Success! 50 Coins added.')),
    );
  }

  void _submitWithdrawal() async {
    final upi = _upiController.text.trim();
    if (upi.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid UPI ID!')),
      );
      return;
    }

    if (_balance < 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Minimum withdrawal is 100 Coins (₹10)!')),
      );
      return;
    }

    const coinsToWithdraw = 100;
    setState(() {
      _balance -= coinsToWithdraw;
      _history.insert(0, {
        'title': 'Withdrawal ($upi)',
        'coins': '-$coinsToWithdraw',
        'time': 'Just now',
      });
    });

    _syncFirebase();

    if (isFirebaseReady && _userId != null) {
      await FirebaseFirestore.instance.collection('withdrawals').add({
        'userId': _userId,
        'upi': upi,
        'coins': coinsToWithdraw,
        'inrAmount': 10.0,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    _upiController.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Withdrawal request submitted successfully!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      _buildHomeScreen(),
      _buildReferScreen(),
      _buildWalletScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Watch & Earn Pro', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF262111),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF8A6C1A)),
            ),
            child: Row(
              children: [
                const Icon(Icons.monetization_on, color: Color(0xFFF5B300), size: 18),
                const SizedBox(width: 6),
                Text(
                  '$_balance',
                  style: const TextStyle(color: Color(0xFFF5B300), fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ],
            ),
          )
        ],
      ),
      body: screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        backgroundColor: const Color(0xFF0F1015),
        selectedItemColor: const Color(0xFFF5B300),
        unselectedItemColor: Colors.white54,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.card_giftcard), label: 'Refer & Earn'),
          BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet), label: 'Wallet'),
        ],
      ),
    );
  }

  Widget _buildHomeScreen() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF1B1D24),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF5B300),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.star, color: Colors.black, size: 28),
                ),
                const SizedBox(height: 12),
                const Text('Total Balance', style: TextStyle(color: Colors.white60, fontSize: 14)),
                const SizedBox(height: 6),
                Text('$_balance Coins', style: const TextStyle(color: Color(0xFFF5B300), fontSize: 26, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('Approx ₹${(_balance / 10).toStringAsFixed(1)} Value', style: const TextStyle(color: Colors.white54, fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B1D24),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    children: [
                      const Text('Remaining Ads', style: TextStyle(color: Colors.white60, fontSize: 13)),
                      const SizedBox(height: 8),
                      Text('$_remainingAds / 15', style: const TextStyle(color: Color(0xFFF5B300), fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: _claimDailyBonus,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1B1D24),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      children: [
                        const Text('Daily Bonus', style: TextStyle(color: Colors.white60, fontSize: 13)),
                        const SizedBox(height: 8),
                        Text(
                          _claimedDaily ? 'Claimed' : '+25 Claim',
                          style: TextStyle(
                            color: _claimedDaily ? Colors.grey : const Color(0xFF38E54D),
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _watchVideoAd,
              icon: const Icon(Icons.play_circle_fill, color: Colors.black),
              label: const Text('Watch Video & Earn (+10 Coins)', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 15)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF5B300),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReferScreen() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1B1D24),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              children: [
                const Icon(Icons.group, color: Color(0xFF4CA5FF), size: 48),
                const SizedBox(height: 12),
                const Text('Invite Friends & Earn', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 6),
                const Text('Both you and your friend get 50 free coins on every referral!', textAlign: TextAlign.center, style: TextStyle(color: Colors.white60, fontSize: 13)),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF12141A),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_myReferralCode, style: const TextStyle(color: Color(0xFFF5B300), fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                      IconButton(
                        icon: const Icon(Icons.copy, color: Colors.white70),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: _myReferralCode));
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Referral code copied!')));
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Share link copied to clipboard!')));
                    },
                    icon: const Icon(Icons.share, color: Colors.black),
                    label: const Text('Share on WhatsApp', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF25D366),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1B1D24),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Have a Referral Code?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                const SizedBox(height: 6),
                const Text('Enter friend\'s referral code to instantly get 50 coins:', style: TextStyle(color: Colors.white60, fontSize: 13)),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _referralInputController,
                        enabled: !_appliedReferral,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: _appliedReferral ? 'Already Applied' : 'e.g. PRO12345',
                          hintStyle: const TextStyle(color: Colors.white30),
                          filled: true,
                          fillColor: const Color(0xFF12141A),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: _appliedReferral ? null : _applyReferralCode,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF5B300),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      ),
                      child: const Text('Apply', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
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

  Widget _buildWalletScreen() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1B1D24),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('UPI Withdrawal', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 4),
                const Text('Rule: 100 Coins = ₹10 (Minimum withdrawal 100 coins)', style: TextStyle(color: Colors.white54, fontSize: 12)),
                const SizedBox(height: 16),
                TextField(
                  controller: _upiController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Your UPI ID (e.g. user@okaxis)',
                    hintStyle: const TextStyle(color: Colors.white30),
                    filled: true,
                    fillColor: const Color(0xFF12141A),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
           
