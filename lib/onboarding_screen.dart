import 'package:flutter/material.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onContinue;

  const OnboardingScreen({super.key, required this.onContinue});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _page = 0;

  void _nextPage() {
    setState(() {
      if (_page < 2) {
        _page += 1;
      } else {
        widget.onContinue();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFAFAF8), Color(0xFFECECEC)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(height: 40),

              // 🔹 Top logo
              Image.asset(
                'assets/shelterfinderlogo.png',
                height: 64,
              ),

              const SizedBox(height: 20),

              // 🔹 Page content
              if (_page == 0)
                Column(
                  children: const [
                    SizedBox(height: 20),
                    Text(
                      "ShelterFinder",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF005D57),
                      ),
                    ),
                    SizedBox(height: 16),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 32.0),
                      child: Text(
                        "Find safe places, fast.\nShelterFinder helps you locate nearby shelters in seconds.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          color: Color(0xFF333333),
                        ),
                      ),
                    ),
                  ],
                )
              else
                Column(
                  children: [
                    // 🔹 Herb avatar
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          )
                        ],
                      ),
                      child: Image.asset(
                        'assets/herb.png',
                        height: 200,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 🔹 Speech bubble
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 6,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Text(
                          _page == 1
                              ? "Hey there! I’m Herb — your shelter-finding guide.\nLet’s get you to a safe place."
                              : "You can use your location or search a city or zip code.\nI’ll handle the rest!",
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 18,
                            color: Color(0xFF333333),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

              const SizedBox(height: 20),

              // 🔹 Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: ElevatedButton(
                  onPressed: _nextPage,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 16),
                    backgroundColor: const Color(0xFF005D57),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _page == 0
                        ? "Meet Herb"
                        : _page == 1
                            ? "Next"
                            : "Get Started",
                    style: const TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ),

              const Padding(
                padding: EdgeInsets.only(bottom: 12.0, top: 20),
                child: Text(
                  "Built by GreatLynxDesigns",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
