import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

import '../utils/responsive.dart';
import 'level_selection_screen.dart';

class StartScreen extends StatefulWidget {
  const StartScreen({super.key});

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> with WidgetsBindingObserver {
  late final AudioPlayer _audioPlayer;
  bool _audioInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _audioPlayer = AudioPlayer();
    unawaited(_playBackgroundAudio());
  }

  Future<void> _playBackgroundAudio() async {
    await _audioPlayer.setReleaseMode(ReleaseMode.loop);
    await _audioPlayer.setVolume(1.0);
    await _audioPlayer.play(AssetSource('sounds/intro.mp3'));
    _audioInitialized = true;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_audioInitialized) return;
    switch (state) {
      case AppLifecycleState.resumed:
        unawaited(_audioPlayer.resume());
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        unawaited(_audioPlayer.pause());
        break;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_audioPlayer.stop());
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: const Color(0xFFEFEFEF), // background similar to image edges
      body: LayoutBuilder(
        builder: (context, constraints) {
          final mq = MediaQuery.of(context);
          final size = mq.size;
          final width = constraints.maxWidth;
          final isTablet = size.shortestSide >= 600;

          // Responsive paddings
          final horizontalPadding = Responsive.horizontalPadding(
            width,
            maxContentWidth: isTablet ? 740 : 520,
          );
          final bottomPadding = Responsive.scaledValue(
            width,
            isTablet ? 80 : 60,
            min: 40,
            max: isTablet ? 140 : 110,
          );
          final buttonWidth = Responsive.scaledValue(
            width,
            isTablet ? 320 : 220,
            min: isTablet ? 260 : 200,
            max: isTablet ? 420 : 320,
          );

          return Stack(
            fit: StackFit.expand,
            children: [
              /// ✅ Background image - scaled to always fit vertically and show FULL content
              Center(
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: SizedBox(
                    height: constraints.maxHeight, // scale based on height
                    child: Image.asset(
                      'assets/images/main.png',
                      fit: BoxFit.contain,
                      alignment: Alignment.center,
                    ),
                  ),
                ),
              ),

              /// ✅ Optional dark overlay to make button visible
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.08),
                ),
              ),

              /// ✅ Bottom button
              SafeArea(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: horizontalPadding,
                      right: horizontalPadding,
                      bottom: bottomPadding,
                    ),
                    child: Directionality(
                      textDirection: TextDirection.rtl,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: buttonWidth),
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.play_arrow_rounded, size: 30),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E6F5C),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                            textStyle: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              fontSize: isTablet ? 22 : 20,
                              color: Colors.white,
                            ),
                            elevation: 6,
                          ),
                          onPressed: () {
                            _audioPlayer.setVolume(0.35);
                            Navigator.of(context)
                                .push(
                              MaterialPageRoute(
                                builder: (_) => const LevelSelectionScreen(),
                              ),
                            )
                                .then((_) {
                              if (!mounted) return;
                              _audioPlayer.setVolume(1.0);
                            });
                          },
                          label: const Padding(
                            padding: EdgeInsets.only(right: 8.0),
                            child: Text('ابدأ اللعب'),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
