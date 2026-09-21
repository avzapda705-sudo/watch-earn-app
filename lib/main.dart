import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:share_plus/share_plus.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await MobileAds.instance.initialize();
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
        scaffoldBackgroundColor: const Color(0xFF0F0F12),
        cardColor: const Color(0xFF1B1C22),
        useMaterial3: true,
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
  int _coins = 100;
  int _adsRemaining = 15;
  bool _claimedDaily = false;
  bool _hasUsedReferral = false;
  late final String _userReferralCode;

  // AdMob IDs
  final String _rewardedAdUnitId = 'ca-app-pub-5150845800087406/3645352028';
  final String _interstitialAdUnitId = 'ca-app-pub-5150845800087406/1725676408';
  final String _bannerAdUnitId = 'ca-app-pub-5150845800087406/8514535326';

  RewardedAd? _rewardedAd;
  InterstitialAd? _interstitialAd;
  BannerAd? _bannerAd;
  bool _isBannerLoaded = false;
  bool _isLoadingReward = false;

  @override
  void initState() {
    super.initState();
    _userReferralCode = 'PRO${Random().nextInt(899999) + 100000}';
    _loadBannerAd();
    _loadInterstitialAd();
    _loadRewardedAd();
  }

  void _loadBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: _bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) => setState(() => _isBannerLoaded = true),
        onAdFailedToLoad: (ad, error) => ad.dispose(),
      ),
    )..load();
  }

  void _loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: _interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => _interstitialAd = ad,
        onAdFailedToLoad: (error) => _interstitialAd = null,
      ),
    );
  }

  void _showInterstitialAd() {
    if (_interstitialAd != null) {
      _interstitialAd!.show();
      _loadInterstitialAd();
    }
  }

  void _loadRewardedAd() {
    RewardedAd.load(
      adUnitId: _rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          if (_isLoadingReward) {
            setState(() => _isLoadingReward = false);
            _playRewardedAd();
          }
        },
        onAdFailedToLoad: (error) {
          _rewardedAd = null;
          if (_isLoadingReward) {
            setState(() => _isLoadingReward = false);
            _showMessage('એડ લોડ કરવામાં ક્ષતિ આવી, ફરી પ્રયત્ન કરો.');
          }
        },
      ),
    );
  }

  void _triggerWatchAd() {
    if (_adsRemaining <= 0) {
      _showMessage('આજની એડ લિમિટ પૂરી થઈ ગઈ છે! આવતીકાલે ફરી આવો.');
      return;
    }
    if (_rewardedAd != null) {
      _playRewardedAd();
    } else {
      setState(() => _isLoadingReward = true);
      _showMessage('જાહેરાત તૈયાર થઈ રહી છે...');
      _loadRewardedAd();
    }
  }

  void _playRewardedAd() {
    _rewardedAd?.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _loadRewardedAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _loadRewardedAd();
      },
    );

    _rewardedAd?.show(onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
      setState(() {
        _coins += 10;
        _adsRemaining--;
      });
      _showMessage('અભિનંદન! ૧૦ કોઈન્સ જમા થયા!');
    });
    _rewardedAd = null;
  }

  void _claimDailyBonus() {
    if (_claimedDaily) {
      _showMessage('આજનો ડેઇલી બોનસ તમે મેળવી લીધો છે!');
      return;
    }
    setState(() {
      _coins += 25;
      _claimedDaily = true;
    });
    _showMessage('અભિનંદન! ડેઇલી બોનસના ૨૫ કોઈન્સ મળ્યા!');
    _showInterstitialAd();
  }

  void _applyReferralCode(String code) {
    if (_hasUsedReferral) {
      _showMessage('તમે પહેલાથી જ રેફરલ કોડ ઉપયોગ કરી લીધો છે!');
      return;
    }
    if (code.trim().isEmpty) {
      _showMessage('કૃપા કરીને સાચો રેફરલ કોડ દાખલ કરો.');
      return;
    }
    if (code.trim().toUpperCase() == _userReferralCode) {
      _showMessage('તમે તમારો પોતાનો રેફરલ કોડ વાપરી ના શકો.');
      return;
    }
    setState(() {
      _coins += 50;
      _hasUsedReferral = true;
    });
    _showMessage('શાનદાર! રેફરલ બોનસના ૫૦ કોઈન્સ મળ્યા!');
    _showInterstitialAd();
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

  @override
  void dispose() {
    _bannerAd?.dispose();
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      _buildHomeView(),
      _buildReferView(),
      _buildWalletView(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Watch & Earn Pro', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5)),
        backgroundColor: const Color(0xFF14151B),
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.amber.withOpacity(0.5)),
            ),
            child: Row(
              children: [
                const Icon(Icons.monetization_on, color: Colors.amber, size: 18),
                const SizedBox(width: 6),
                Text('$_coins', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.amber)),
              ],
            ),
          )
        ],
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isBannerLoaded && _bannerAd != null)
            SizedBox(
              width: _bannerAd!.size.width.toDouble(),
              height: _bannerAd!.size.height.toDouble(),
              child: AdWidget(ad: _bannerAd!),
            ),
          NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: (index) => setState(() => _currentIndex = index),
            backgroundColor: const Color(0xFF14151B),
            indicatorColor: Colors.amber.withOpacity(0.25),
            destinations: const [
              NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home, color: Colors.amber), label: 'Home'),
              NavigationDestination(icon: Icon(Icons.card_giftcard_outlined), selectedIcon: Icon(Icons.card_giftcard, color: Colors.amber), label: 'Refer & Earn'),
              NavigationDestination(icon: Icon(Icons.account_balance_wallet_outlined), selectedIcon: Icon(Icons.account_balance_wallet, color: Colors.amber), label: 'Wallet'),
            ],
          ),
        ],
      ),
      body: pages[_currentIndex],
    );
  }

  Widget _buildHomeView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF2B281B), Color(0xFF1A1915)]),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.amber.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                const Icon(Icons.stars, color: Colors.amber, size: 48),
                const SizedBox(height: 8),
                const Text('કુલ બેલેન્સ', style: TextStyle(color: Colors.grey, fontSize: 14)),
                const SizedBox(height: 4),
                Text('$_coins Coins', style: const TextStyle(fontSize: 34, fontWeight: FontWeight.bold, color: Colors.amber)),
                const SizedBox(height: 4),
                Text('લગભગ ₹${(_coins / 10).toStringAsFixed(1)} બરાબર', style: const TextStyle(color: Colors.greenAccent, fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B1C22),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      const Text('બાકી એડ્સ', style: TextStyle(color: Colors.grey, fontSize: 13)),
                      const SizedBox(height: 6),
                      Text('$_adsRemaining / 15', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.amber)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: InkWell(
                  onTap: _claimDailyBonus,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1B1C22),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _claimedDaily ? Colors.transparent : Colors.greenAccent.withOpacity(0.4)),
                    ),
                    child: Column(
                      children: [
                        const Text('ડેઇલી બોનસ', style: TextStyle(color: Colors.grey, fontSize: 13)),
                        const SizedBox(height: 6),
                        Text(_claimedDaily ? 'મેળવી લીધું' : '+25 મેળવો',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _claimedDaily ? Colors.grey : Colors.greenAccent)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: _isLoadingReward ? null : _triggerWatchAd,
              icon: _isLoadingReward
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                  : const Icon(Icons.play_circle_fill, color: Colors.black, size: 26),
              label: Text(_isLoadingReward ? 'લોડ થઈ રહી છે...' : 'વિડિયો જુઓ અને કમાઓ (+10 Coins)',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReferView() {
    final refController = TextEditingController();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF1E2838), Color(0xFF141923)]),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                const Icon(Icons.people_alt, color: Colors.lightBlueAccent, size: 50),
                const SizedBox(height: 12),
                const Text('મિત્રોને ઇન્વાઇટ કરો અને કમાઓ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 8),
                const Text('દરેક રેફરલ પર તમને અને તમારા મિત્ર બંનેને ૫૦ કોઈન્સ મફત મળશે!',
                    textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 13)),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.black38,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white24, style: BorderStyle.solid),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_userReferralCode, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 2, color: Colors.amber)),
                      IconButton(
                        icon: const Icon(Icons.copy, color: Colors.white70),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: _userReferralCode));
                          _showMessage('રેફરલ કોડ કોપી થઈ ગયો!');
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Share.share(
                        'મિત્ર! Watch & Earn Pro એપ ડાઉનલોડ કર અને ઘરે બેઠા પૈસા કમાઓ.\nમારો રેફરલ કોડ વાપરીને ૫૦ કોઈન્સ ફ્રી મેળવો: $_userReferralCode\nડાઉનલોડ લિંક: https://example.com/app',
                      );
                    },
                    icon: const Icon(Icons.share, color: Colors.black),
                    label: const Text('WhatsApp પર શેર કરો', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.greenAccent, padding: const EdgeInsets.symmetric(vertical: 14)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1B1C22),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('રેફરલ કોડ છે?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 6),
                const Text('મિત્રનો રેફરલ કોડ દાખલ કરો અને તરત જ ૫૦ કોઈન્સ મેળવો:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: refController,
                        textCapitalization: TextCapitalization.characters,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'દા.ત. PRO12345',
                          hintStyle: const TextStyle(color: Colors.grey),
                          filled: true,
                          fillColor: const Color(0xFF14151B),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: _hasUsedReferral ? null : () => _applyReferralCode(refController.text),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text(_hasUsedReferral ? 'વપરાઈ ગયું' : 'Apply', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
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

  Widget _buildWalletView() {
    final upiCtrl = TextEditingController();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1B1C22),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('UPI વિડ્રોઅલ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 6),
                const Text('નિયમ: ૧૦૦ Coins = ₹૧૦ (ઓછામાં ઓછા ૧૦૦ કોઈન્સ)', style: TextStyle(color: Colors.grey, fontSize: 13)),
                const SizedBox(height: 18),
                TextField(
                  controller: upiCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'તમારો UPI ID (દા.ત. user@okaxis)',
                    hintStyle: const TextStyle(color: Colors.grey),
                    filled: true,
                    fillColor: const Color(0xFF14151B),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_coins < 100) {
                        _showMessage('વિડ્રોઅલ માટે ઓછામાં ઓછા ૧૦૦ કોઈન્સ જરૂરી છે!');
                      } else if (upiCtrl.text.trim().isEmpty) {
                        _showMessage('કૃપા કરીને સાચો UPI ID દાખલ કરો.');
                      } else {
                        setState(() => _coins -= 100);
                        _showMessage('વિડ્રોઅલ રિક્વેસ્ટ સફળતાપૂર્વક સબમિટ થઈ ગઈ!');
                        _showInterstitialAd();
                      }
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                    child: const Text('પૈસા ઉપાડો (Withdraw)', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
