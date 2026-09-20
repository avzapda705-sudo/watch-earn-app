import 'package:flutter/material.dart';
import 'package:unity_ads_plugin/unity_ads_plugin.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Watch & Earn Pro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.amber,
        scaffoldBackgroundColor: const Color(0xFF121212),
        cardColor: const Color(0xFF1E1E1E),
        useMaterial3: true,
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
  int _coins = 0;
  int _adsRemaining = 15;
  bool _claimedDaily = false;
  bool _isAdLoaded = false;

  final String _gameId = '5739818';
  final String _adUnitId = 'Rewarded_Android';

  @override
  void initState() {
    super.initState();
    _initUnityAds();
  }

  void _initUnityAds() {
    UnityAds.init(
      gameId: _gameId,
      testMode: true,
      onComplete: () {
        _loadRewardAd();
      },
      onFailed: (error, message) {},
    );
  }

  void _loadRewardAd() {
    UnityAds.load(
      placementId: _adUnitId,
      onComplete: (placementId) {
        setState(() => _isAdLoaded = true);
      },
      onFailed: (placementId, error, message) {
        setState(() => _isAdLoaded = false);
      },
    );
  }

  void _showRewardAd() {
    if (_adsRemaining <= 0) {
      _showMessage('આજની એડ લિમિટ પૂરી થઈ ગઈ છે! કાલે ફરી પ્રયાસ કરો.');
      return;
    }

    UnityAds.showVideoAd(
      placementId: _adUnitId,
      onComplete: (placementId) {
        setState(() {
          _coins += 10;
          _adsRemaining--;
        });
        _showMessage('અભિનંદન! તમને ૧૦ કોઈન્સ મળ્યા!');
        _loadRewardAd();
      },
      onFailed: (placementId, error, message) {
        _showMessage('એડ લોડ કરવામાં ભૂલ આવી. ફરી પ્રયાસ કરો.');
        _loadRewardAd();
      },
      onSkipped: (placementId) {
        _showMessage('એડ સ્કીપ કરી દેવાઈ, કોઈન્સ મળ્યા નહીં.');
        _loadRewardAd();
      },
    );
  }

  void _claimDailyBonus() {
    if (_claimedDaily) {
      _showMessage('તમે આજનો બોનસ પહેલેથી લઈ લીધો છે!');
      return;
    }
    setState(() {
      _coins += 25;
      _claimedDaily = true;
    });
    _showMessage('અભિનંદન! ડેઇલી બોનસના ૨૫ કોઈન્સ મળ્યા!');
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.amber[800],
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _openWithdrawDialog() {
    final upiController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF222222),
          title: const Text('UPI વિડ્રોઅલ', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('હાજર બેલેન્સ: $_coins Coins', style: const TextStyle(color: Colors.amberAccent)),
              const SizedBox(height: 8),
              const Text('નિયમ: ૧૦૦ Coins = ₹૧૦ (લઘુત્તમ ૧૦૦ કોઈન્સ)', style: TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 16),
              TextField(
                controller: upiController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'તમારો UPI ID દાખલ કરો',
                  hintStyle: const TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: const Color(0xFF333333),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('રદ કરો', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
              onPressed: () {
                if (_coins < 100) {
                  Navigator.pop(context);
                  _showMessage('વિડ્રોઅલ માટે ઓછામાં ઓછા ૧૦૦ કોઈન્સ જરૂરી છે.');
                } else if (upiController.text.trim().isEmpty) {
                  _showMessage('કૃપા કરીને સાચો UPI ID દાખલ કરો.');
                } else {
                  Navigator.pop(context);
                  setState(() => _coins -= 100);
                  _showMessage('વિડ્રોઅલ વિનંતી સબમિટ થઈ ગઈ છે!');
                }
              },
              child: const Text('રિડીમ કરો', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
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
        title: const Text('Watch & Earn Pro', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.account_balance_wallet, color: Colors.amber),
            onPressed: _openWithdrawDialog,
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Container(
                padding: const EdgeInsets.all(24),
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2C2C2C), Color(0xFF1E1E1E)],
                  ),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.monetization_on, size: 55, color: Colors.amber),
                    const SizedBox(height: 10),
                    const Text('તમારું બેલેન્સ', style: TextStyle(fontSize: 16, color: Colors.grey)),
                    const SizedBox(height: 6),
                    Text(
                      '$_coins Coins',
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.greenAccent),
                    ),
                    const SizedBox(height: 14),
                    ElevatedButton.icon(
                      onPressed: _openWithdrawDialog,
                      icon: const Icon(Icons.payment, color: Colors.black),
                      label: const Text('પૈસા ઉપાડો (Withdraw)', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
                    )
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          const Text('બાકી એડ્સ', style: TextStyle(color: Colors.grey, fontSize: 13)),
                          const SizedBox(height: 4),
                          Text('$_adsRemaining / 15', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.amber)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: InkWell(
                      onTap: _claimDailyBonus,
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            const Text('ડેઇલી બોનસ', style: TextStyle(color: Colors.grey, fontSize: 13)),
                            const SizedBox(height: 4),
                            Text(_claimedDaily ? 'મેળવી લીધું' : '+25 મેળવો',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _claimedDaily ? Colors.grey : Colors.greenAccent)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _showRewardAd,
                icon: const Icon(Icons.play_circle_fill, size: 28, color: Colors.black),
                label: const Text('વિડિયો જુઓ અને કમાઓ (+10)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
