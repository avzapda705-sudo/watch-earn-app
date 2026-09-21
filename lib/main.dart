import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase safely so the app never freezes on the splash screen
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint("Firebase initialization note: $e");
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
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasData && snapshot.data != null) {
            return HomeScreen(user: snapshot.data!);
          }
          return const LoginScreen();
        },
      ),
    );
  }
}

// ---------------- LOGIN SCREEN (PHONE OTP) ----------------
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();

  String? _verificationId;
  bool _isOtpSent = false;
  bool _isLoading = false;

  void _sendOtp() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty || phone.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('કૃપા કરીને માન્ય 10 અંકનો નંબર દાખલ કરો')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: '+91$phone',
        verificationCompleted: (PhoneAuthCredential credential) async {
          await FirebaseAuth.instance.signInWithCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('વેરિફિકેશન નિષ્ફળ: ${e.message}')),
          );
        },
        codeSent: (String verificationId, int? resendToken) {
          setState(() {
            _verificationId = verificationId;
            _isOtpSent = true;
            _isLoading = false;
          });
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
      );
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('OTP મોકલવામાં એરર: $e')),
      );
    }
  }

  void _verifyOtp() async {
    final otp = _otpController.text.trim();
    if (otp.length != 6 || _verificationId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('કૃપા કરીને 6 અંકનો OTP દાખલ કરો')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: otp,
      );
      UserCredential userCred =
          await FirebaseAuth.instance.signInWithCredential(credential);

      // Initialize Firestore document for new user
      if (userCred.user != null) {
        final userDoc = FirebaseFirestore.instance
            .collection('users')
            .doc(userCred.user!.uid);

        final docSnapshot = await userDoc.get();
        if (!docSnapshot.exists) {
          await userDoc.set({
            'phone': userCred.user!.phoneNumber,
            'balance': 0,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('OTP અમાન્ય છે: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login / રજીસ્ટ્રેશન')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.monetization_on, size: 80, color: Colors.deepPurple),
            const SizedBox(height: 20),
            if (!_isOtpSent) ...[
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                decoration: const InputDecoration(
                  prefixText: '+91 ',
                  labelText: 'મોબાઈલ નંબર',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _sendOtp,
                      child: const Text('OTP મોકલો'),
                    ),
            ] else ...[
              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: const InputDecoration(
                  labelText: '૬ અંકનો OTP દાખલ કરો',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _verifyOtp,
                      child: const Text('OTP વેરિફાય કરો'),
                    ),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------- HOME SCREEN ----------------
class HomeScreen extends StatelessWidget {
  final User user;
  const HomeScreen({super.key, required this.user});

  void _addRewardCoins(BuildContext context) async {
    try {
      final userDoc =
          FirebaseFirestore.instance.collection('users').doc(user.uid);
      await userDoc.update({'balance': FieldValue.increment(10)});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('+10 સિક્કા મળ્યા!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('સિક્કા ઉમેરવામાં નિષ્ફળ: $e')),
      );
    }
  }

  void _showWithdrawDialog(BuildContext context, int currentBalance) {
    final TextEditingController upiController = TextEditingController();
    final TextEditingController coinsController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ઉપાડ (Withdrawal) રિક્વેસ્ટ'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: upiController,
              decoration: const InputDecoration(labelText: 'UPI ID દાખલ કરો'),
            ),
            TextField(
              controller: coinsController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'સિક્કા (Coins) દાખલ કરો'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('રદ કરો'),
          ),
          ElevatedButton(
            onPressed: () async {
              final upi = upiController.text.trim();
              final coins = int.tryParse(coinsController.text.trim()) ?? 0;

              if (upi.isEmpty || coins <= 0) return;
              if (coins > currentBalance) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('ખાતામાં પૂરતું બેલેન્સ નથી!')),
                );
                return;
              }

              Navigator.pop(ctx);

              try {
                // Deduct coins & create withdrawal record
                final batch = FirebaseFirestore.instance.batch();
                final userDoc =
                    FirebaseFirestore.instance.collection('users').doc(user.uid);
                final withdrawDoc =
                    FirebaseFirestore.instance.collection('withdrawals').doc();

                batch.update(userDoc, {'balance': FieldValue.increment(-coins)});
                batch.set(withdrawDoc, {
                  'userId': user.uid,
                  'phone': user.phoneNumber,
                  'upiId': upi,
                  'coins': coins,
                  'status': 'Pending',
                  'timestamp': FieldValue.serverTimestamp(),
                });

                await batch.commit();

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('રિક્વેસ્ટ સફળતાપૂર્વક સબમિટ થઈ ગઈ!')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('રિક્વેસ્ટ નિષ્ફળ: $e')),
                );
              }
            },
            child: const Text('સબમિટ કરો'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userDoc =
        FirebaseFirestore.instance.collection('users').doc(user.uid);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Watch & Earn'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => FirebaseAuth.instance.signOut(),
          )
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: userDoc.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data?.data() as Map<String, dynamic>? ?? {};
          final balance = data['balance'] ?? 0;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        const Text('તમારું બેલેન્સ', style: TextStyle(fontSize: 18)),
                        const SizedBox(height: 8),
                        Text(
                          '$balance સિક્કા',
                          style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.deepPurple),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () => _addRewardCoins(context),
                  icon: const Icon(Icons.play_circle_fill),
                  label: const Text('વીડિયો જુઓ (+10 સિક્કા)'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () => _showWithdrawDialog(context, balance),
                  icon: const Icon(Icons.account_balance_wallet),
                  label: const Text('પૈસા ઉપાડો (Withdraw)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'તમારો ઉપાડ ઇતિહાસ (Withdrawal History)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Divider(),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('withdrawals')
                        .where('userId', isEqualTo: user.uid)
                        .snapshots(),
                    builder: (context, withdrawSnapshot) {
                      if (!withdrawSnapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final docs = withdrawSnapshot.data!.docs;
                      if (docs.isEmpty) {
                        return const Center(child: Text('કોઈ રેકોર્ડ ઉપલબ્ધ નથી'));
                      }
                      return ListView.builder(
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          final item =
                              docs[index].data() as Map<String, dynamic>;
                          return Card(
                            child: ListTile(
                              leading: const Icon(Icons.history),
                              title: Text('${item['coins']} સિક્કા'),
                              subtitle: Text('UPI: ${item['upiId']}'),
                              trailing: Chip(
                                label: Text(item['status'] ?? 'Pending'),
                                backgroundColor: item['status'] == 'Approved'
                                    ? Colors.green.shade100
                                    : Colors.orange.shade100,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

