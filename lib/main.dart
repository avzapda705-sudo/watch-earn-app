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
      title: 'Watch & Earn',
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

  @override
  void initState() {
    super.initState();
    _loadUserData();
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

  void _claimDaily() async {
    if (_claimedDaily) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('આજનો બોનસ પહેલેથી ક્લેમ કરેલો છે!')),
      );
      return;
    }
    setState(() {
      _balance += 50;
      _claimedDaily = true;
      _history.insert(0, {'title': 'Daily Bonus', 'coins': '+50', 'time': 'Just now'});
    });
    if (isFirebaseReady && _userId != null) {
      await FirebaseFirestore.instance.collection('users').doc(_userId).update({
        'balance': _balance,
        'claimedDaily': true,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Watch & Earn Pro'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('તમારા કોઈન્સ:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text('$_balance 🪙', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _claimDaily,
              icon: const Icon(Icons.card_giftcard),
              label: Text(_claimedDaily ? 'Claimed' : 'Daily Bonus Claim કરો (+50)'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                backgroundColor: _claimedDaily ? Colors.grey : Colors.deepPurple,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('ઇતિહાસ:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            Expanded(
              child: _history.isEmpty
                  ? const Center(child: Text('હજુ સુધી કોઈ કમાણી થઈ નથી.'))
                  : ListView.builder(
                      itemCount: _history.length,
                      itemBuilder: (context, index) {
                        final item = _history[index];
                        return ListTile(
                          title: Text(item['title']),
                          subtitle: Text(item['time']),
                          trailing: Text(item['coins'], style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
