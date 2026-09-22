import 'package:flutter/material.dart';
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
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.deepPurple,
        scaffoldBackgroundColor: const Color(0xFFF7F6FA),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _balance = 0;
  bool _claimedDaily = false;
  bool _appliedReferral = false;
  final String _myReferralCode = "EARN705";
  final List<Map<String, dynamic>> _history = [];
  String? _userId;

  final TextEditingController _referralController = TextEditingController();
  final TextEditingController _upiController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _referralController.dispose();
    _upiController.dispose();
    _amountController.dispose();
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
        });
      } else {
        await FirebaseFirestore.instance.collection('users').doc(_userId).set({
          'balance': 0,
          'claimedDaily': false,
          'appliedReferral': false,
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
      }, SetOptions(merge: true));
    }
  }

  void _claimDaily() {
    if (_claimedDaily) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Daily bonus has already been claimed!')),
      );
      return;
    }
    setState(() {
      _balance += 50;
      _claimedDaily = true;
      _history.insert(0, {'title': 'Daily Bonus', 'coins': '+50', 'time': 'Just now'});
    });
    _syncFirebase();
  }

  void _watchAdTask() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('Playing Video Ad...'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Watch the complete video to earn 20 coins.'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  _balance += 20;
                  _history.insert(0, {'title': 'Watch Video Ad', 'coins': '+20', 'time': 'Just now'});
                });
                _syncFirebase();
              },
              child: const Text('Claim Reward'),
            ),
          ],
        );
      },
    );
  }

  void _applyReferral() {
    if (_appliedReferral) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Referral code has already been applied!')),
      );
      return;
    }
    final code = _referralController.text.trim();
    if (code.isEmpty) return;

    setState(() {
      _balance += 100;
      _appliedReferral = true;
      _history.insert(0, {'title': 'Referral Bonus', 'coins': '+100', 'time': 'Just now'});
    });
    _referralController.clear();
    _syncFirebase();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Referral bonus +100 coins credited successfully!')),
    );
  }

  void _showWithdrawDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Withdraw Funds'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Available Balance: $_balance coins (100 coins = ₹10)'),
                const SizedBox(height: 16),
                TextField(
                  controller: _upiController,
                  decoration: const InputDecoration(
                    labelText: 'UPI ID / Paytm Number',
                    hintText: 'user@upi',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Coins to Withdraw',
                    hintText: 'e.g. 100',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final upi = _upiController.text.trim();
                final coinsToWithdraw = int.tryParse(_amountController.text.trim()) ?? 0;

                if (upi.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a valid UPI ID or Paytm number!')),
                  );
                  return;
                }

                if (coinsToWithdraw < 100) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Minimum withdrawal is 100 coins!')),
                  );
                  return;
                }

                if (coinsToWithdraw > _balance) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Insufficient balance!')),
                  );
                  return;
                }

                Navigator.pop(context);

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
                    'inrAmount': (coinsToWithdraw / 10),
                    'status': 'pending',
                    'createdAt': FieldValue.serverTimestamp(),
                  });
                }

                _upiController.clear();
                _amountController.clear();

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Withdrawal request submitted successfully!')),
                );
              },
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Watch & Earn Pro'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Total Balance', style: TextStyle(fontSize: 16, color: Colors.grey)),
                        SizedBox(height: 4),
                        Text('Your Coins', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Text('$_balance 🪙', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _claimDaily,
              icon: const Icon(Icons.card_giftcard),
              label: Text(_claimedDaily ? 'Daily Bonus Claimed' : 'Claim Daily Bonus (+50)'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                backgroundColor: _claimedDaily ? Colors.grey : Colors.deepPurple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _watchAdTask,
              icon: const Icon(Icons.play_circle_fill),
              label: const Text('Watch Video & Earn (+20)'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _showWithdrawDialog,
              icon: const Icon(Icons.account_balance_wallet),
              label: const Text('Withdraw Funds'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                backgroundColor: Colors.green.shade700,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 20),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Enter Referral Code (+100)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _referralController,
                            enabled: !_appliedReferral,
                            decoration: InputDecoration(
                              hintText: _appliedReferral ? 'Already Applied' : 'Referral code',
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              border: const OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _appliedReferral ? null : _applyReferral,
                          child: const Text('Apply'),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Your Referral Code:', style: TextStyle(color: Colors.grey)),
                        SelectableText(_myReferralCode, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Activity History:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _history.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24.0),
                    child: Center(child: Text('No activity yet.', style: TextStyle(color: Colors.grey))),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _history.length,
                    itemBuilder: (context, index) {
                      final item = _history[index];
                      final isMinus = item['coins'].toString().startsWith('-');
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: Icon(
                            isMinus ? Icons.call_made : Icons.monetization_on,
                            color: isMinus ? Colors.red : Colors.amber,
                          ),
                          title: Text(item['title']),
                          subtitle: Text(item['time']),
                          trailing: Text(
                            item['coins'],
                            style: TextStyle(
                              color: isMinus ? Colors.red : Colors.green,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }
}
