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

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _referralController.dispose();
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
        const SnackBar(content: Text('આજનો ડેઇલી બોનસ ક્લેમ થઈ ગયો છે!')),
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
          title: const Text('વિડિયો ચાલી રહ્યો છે...'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('પૂરો વિડિયો જોવા પર 20 કોઈન્સ મળશે.'),
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
              child: const Text('ક્લેમ કરો'),
            ),
          ],
        );
      },
    );
  }

  void _applyReferral() {
    if (_appliedReferral) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('રેફરલ કોડ પહેલેથી ઉપયોગ કરેલો છે!')),
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
      const SnackBar(content: Text('રેફરલ બોનસ +100 સફળતાપૂર્વક મળ્યું!')),
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
            // Balance Card
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
                        Text('કુલ બેલેન્સ', style: TextStyle(fontSize: 16, color: Colors.grey)),
                        SizedBox(height: 4),
                        Text('તમારા કોઈન્સ', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Text('$_balance 🪙', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Daily Bonus Button
            ElevatedButton.icon(
              onPressed: _claimDaily,
              icon: const Icon(Icons.card_giftcard),
              label: Text(_claimedDaily ? 'Daily Bonus Claimed' : 'Daily Bonus Claim કરો (+50)'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                backgroundColor: _claimedDaily ? Colors.grey : Colors.deepPurple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),

            // Watch Video Task
            ElevatedButton.icon(
              onPressed: _watchAdTask,
              icon: const Icon(Icons.play_circle_fill),
              label: const Text('વિડિયો જુઓ અને કમાઓ (+20)'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 20),

            // Referral Code Box
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('મિત્રનો રેફરલ કોડ નાખો (+100)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _referralController,
                            enabled: !_appliedReferral,
                            decoration: InputDecoration(
                              hintText: _appliedReferral ? 'પહેલેથી ઉપયોગ કરેલો છે' : 'રેફરલ કોડ લખો',
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
                        const Text('તમારો રેફરલ કોડ:', style: TextStyle(color: Colors.grey)),
                        SelectableText(_myReferralCode, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Earnings History
            const Text('કમાણીનો ઇતિહાસ:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _history.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24.0),
                    child: Center(child: Text('હજુ સુધી કોઈ કમાણી થઈ નથી.', style: TextStyle(color: Colors.grey))),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _history.length,
                    itemBuilder: (context, index) {
                      final item = _history[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: const Icon(Icons.monetization_on, color: Colors.amber),
                          title: Text(item['title']),
                          subtitle: Text(item['time']),
                          trailing: Text(item['coins'], style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16)),
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
