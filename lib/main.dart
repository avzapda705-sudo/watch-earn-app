import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
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
        scaffoldBackgroundColor: const Color(0xFFF7F8FA),
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
  final String _myReferralCode = 'EARN705';
  static const int minWithdraw = 100;
  final List<Map<String, dynamic>> _history = [];

  void _watchVideo() {
    setState(() => _balance += 10);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🎉 +10 Coins earned!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _claimDailyBonus() {
    if (_claimedDaily) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Already claimed today!')),
      );
      return;
    }
    setState(() {
      _balance += 25;
      _claimedDaily = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🎁 Daily Bonus: +25 Coins added!'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _showReferralDialog() {
    final refCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Refer & Earn'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your Referral Code:',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.deepPurple.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.deepPurple.shade200),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _myReferralCode,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      letterSpacing: 1.2,
                      color: Colors.deepPurple,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy, size: 20, color: Colors.deepPurple),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: _myReferralCode));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Code copied to clipboard!')),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Have a Friend\'s Code? Enter below for +50 Coins:',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: refCtrl,
              decoration: const InputDecoration(
                hintText: 'Enter Referral Code',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_appliedReferral) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('You have already redeemed a code!')),
                );
                return;
              }
              final code = refCtrl.text.trim().toUpperCase();
              if (code.isEmpty) return;
              if (code == _myReferralCode) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('You cannot use your own referral code!'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              Navigator.pop(ctx);
              setState(() {
                _balance += 50;
                _appliedReferral = true;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('🌟 Referral Bonus Applied! +50 Coins!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Apply Code'),
          ),
        ],
      ),
    );
  }

  void _showWithdrawDialog() {
    final upiCtrl = TextEditingController();
    final coinCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Withdraw Money'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Minimum withdrawal: 100 Coins', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 12),
            TextField(
              controller: upiCtrl,
              decoration: const InputDecoration(labelText: 'UPI ID (e.g. name@upi)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: coinCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Number of Coins', border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
            onPressed: () {
              final upi = upiCtrl.text.trim();
              final coins = int.tryParse(coinCtrl.text.trim()) ?? 0;

              if (upi.isEmpty || coins <= 0) return;
              if (coins < minWithdraw) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Minimum withdrawal is 100 Coins!'), backgroundColor: Colors.red),
                );
                return;
              }
              if (coins > _balance) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Insufficient Coins in wallet!'), backgroundColor: Colors.red),
                );
                return;
              }

              Navigator.pop(ctx);
              setState(() {
                _balance -= coins;
                _history.insert(0, {'coins': coins, 'upi': upi, 'status': 'Pending'});
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Withdrawal request submitted!'), backgroundColor: Colors.green),
              );
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Watch & Earn', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Refer & Earn',
            onPressed: _showReferralDialog,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Wallet Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF6A11CB), Color(0xFF2575FC)]),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Colors.deepPurple.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text('Total Balance', style: TextStyle(color: Colors.white70, fontSize: 16)),
                  const SizedBox(height: 8),
                  Text('$_balance Coins', style: const TextStyle(color: Colors.white, fontSize: 38, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Text('100 Coins = ₹10', style: TextStyle(color: Colors.white, fontSize: 13)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Daily Check-in Card
            Card(
              elevation: 0,
              color: Colors.amber.shade50,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.amber.shade200),
              ),
              child: ListTile(
                leading: const Icon(Icons.card_giftcard, color: Colors.amber, size: 36),
                title: const Text('Daily Check-in Bonus', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Get +25 Free Coins every day'),
                trailing: ElevatedButton(
                  onPressed: _claimedDaily ? null : _claimDailyBonus,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber.shade700,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(_claimedDaily ? 'Claimed' : 'Claim'),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Refer & Earn Banner Card
            Card(
              elevation: 0,
              color: Colors.blue.shade50,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.blue.shade200),
              ),
              child: ListTile(
                leading: const Icon(Icons.group_add, color: Colors.blueAccent, size: 36),
                title: const Text('Refer & Earn (+50 Coins)', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Invite friends to earn together'),
                trailing: ElevatedButton(
                  onPressed: _showReferralDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Invite'),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Watch Video Button
            ElevatedButton.icon(
              onPressed: _watchVideo,
              icon: const Icon(Icons.play_circle_fill, size: 24),
              label: const Text('Watch Video (+10 Coins)', style: TextStyle(fontSize: 16)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
            const SizedBox(height: 10),

            // Withdraw Button
            ElevatedButton.icon(
              onPressed: _showWithdrawDialog,
              icon: const Icon(Icons.account_balance_wallet, size: 24),
              label: const Text('Withdraw Money (Min. 100 Coins)', style: TextStyle(fontSize: 15)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
            const SizedBox(height: 24),

            // History Section
            const Text('Withdrawal History', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const Divider(),
            _history.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(child: Text('No withdrawals yet', style: TextStyle(color: Colors.grey))),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _history.length,
                    itemBuilder: (context, i) {
                      final item = _history[i];
                      return Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          leading: const Icon(Icons.history, color: Colors.deepPurple),
                          title: Text('${item['coins']} Coins', style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('UPI: ${item['upi']}'),
                          trailing: Chip(
                            label: Text(item['status']),
                            backgroundColor: Colors.orange.shade100,
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
