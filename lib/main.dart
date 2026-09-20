import 'package:flutter/material.dart';
import 'package:unity_ads_plugin/unity_ads_plugin.dart';

void main() {
  runApp(const WatchEarnApp());
}

class WatchEarnApp extends StatelessWidget {
  const WatchEarnApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Watch & Earn',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
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
  bool _isAdLoaded = false;

  final String _gameId = '800377040';
  final String _rewardedPlacementId = 'BP_Rewarded_Android';
  final String _interstitialPlacementId = 'BP_Interstitial_Android';

  @override
  void initState() {
    super.initState();
    _initUnityAds();
  }

  void _initUnityAds() {
    UnityAds.init(
      gameId: _gameId,
      testMode: true, // એપ ટેસ્ટિંગ માટે true રાખ્યું છે, લાઇવ કરવા false કરવું
      onComplete: () {
        _loadRewardedAd();
      },
      onFailed: (error, message) {
        debugPrint('Unity Ads Init Failed: $error $message');
      },
    );
  }

  void _loadRewardedAd() {
    UnityAds.load(
      placementId: _rewardedPlacementId,
      onComplete: (placementId) {
        setState(() {
          _isAdLoaded = true;
        });
      },
      onFailed: (placementId, error, message) {
        setState(() {
          _isAdLoaded = false;
        });
      },
    );
  }

  void _showRewardedAd() {
    if (!_isAdLoaded) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('જાહેરાત લોડ થઈ રહી છે, કૃપા કરી થોડી સેકન્ડ રાહ જુઓ...')),
      );
      _loadRewardedAd();
      return;
    }

    UnityAds.showVideoAd(
      placementId: _rewardedPlacementId,
      onComplete: (placementId) {
        setState(() {
          _coins += 10;
          _isAdLoaded = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('અભિનંદન! તમને ૧૦ કોઈન મળ્યા!')),
        );
        _loadRewardedAd();
      },
      onFailed: (placementId, error, message) {
        _loadRewardedAd();
      },
      onSkipped: (placementId) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('જાહેરાત અધૂરી છોડી દીધી, કોઈન મળ્યા નહીં.')),
        );
        _loadRewardedAd();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Watch & Earn'),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.monetization_on, size: 80, color: Colors.amber),
              const SizedBox(height: 16),
              const Text(
                'તમારું બેલેન્સ',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Text(
                '$_coins Coins',
                style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.green),
              ),
              const SizedBox(height: 40),
              ElevatedButton.icon(
                onPressed: _showRewardedAd,
                icon: const Icon(Icons.play_circle_fill),
                label: const Text('વિડિયો જુઓ અને કમાઓ'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  textStyle: const TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
