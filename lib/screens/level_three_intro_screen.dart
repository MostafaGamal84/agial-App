import 'package:flutter/material.dart';

import '../utils/responsive.dart';
import 'level_three_game_screen.dart';

class LevelThreeIntroScreen extends StatelessWidget {
  const LevelThreeIntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final baseTitleStyle =
        textTheme.displayLarge ?? textTheme.headlineLarge ?? const TextStyle(fontSize: 48);

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/LevelThree/levelThreeBackground.jpg',
            fit: BoxFit.cover,
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final mediaQuery = MediaQuery.of(context);
                final padding = Responsive.symmetricPadding(
                  width,
                  horizontal: 24,
                  vertical: Responsive.scaledValue(
                    width,
                    32,
                    min: 20,
                    max: 56,
                  ),
                  maxContentWidth: Responsive.valueForWidth(
                    width,
                    narrow: 560,
                    wide: 720,
                    breakpoint: 900,
                  ),
                );
                final headerSpacing = Responsive.scaledValue(
                  width,
                  24,
                  min: 20,
                  max: 48,
                );
                final footerSpacing = Responsive.scaledValue(
                  width,
                  24,
                  min: 16,
                  max: 40,
                );
                final buttonWidth = Responsive.scaledValue(
                  width,
                  220,
                  min: 200,
                  max: 320,
                );
                final buttonHeight = Responsive.scaledValue(
                  width,
                  60,
                  min: 56,
                  max: 80,
                );
                final textScale = Responsive.scaleForWidth(
                  width,
                  baseWidth: 390,
                  minScale: 0.95,
                  maxScale: 1.2,
                );

                return MediaQuery(
                  data: mediaQuery.copyWith(textScaleFactor: textScale),
                  child: Directionality(
                    textDirection: TextDirection.rtl,
                    child: Padding(
                      padding: padding,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Align(
                            alignment: Alignment.centerRight,
                            child: IconButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              icon: const Icon(Icons.arrow_back_ios_new_rounded),
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: headerSpacing),
                          Align(
                            alignment: Alignment.center,
                            child: Text(
                              'لعبة\nالسلوك الصحيح',
                              textAlign: TextAlign.center,
                              style: baseTitleStyle.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 48,
                                height: 1.2,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Center(
                            child: SizedBox(
                              width: buttonWidth,
                              height: buttonHeight,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1E6F5C),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(28),
                                  ),
                                  elevation: 6,
                                  shadowColor:
                                      const Color(0xFF1E6F5C).withOpacity(0.35),
                                  textStyle: textTheme.titleMedium?.copyWith(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => const LevelThreeGameScreen(),
                                    ),
                                  );
                                },
                                child: const Text('ابدأ اللعب'),
                              ),
                            ),
                          ),
                          SizedBox(height: footerSpacing),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
