import 'package:flutter/material.dart';

import '../utils/responsive.dart';
import 'start_screen.dart';

class LevelCompletionScreen extends StatelessWidget {
  const LevelCompletionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/finish.png',
            fit: BoxFit.cover,
          ),
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Color(0xAA000000),
                ],
              ),
            ),
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
                    24,
                    min: 16,
                    max: 48,
                  ),
                  maxContentWidth: Responsive.valueForWidth(
                    width,
                    narrow: 560,
                    wide: 720,
                    breakpoint: 900,
                  ),
                );
                final buttonWidth = Responsive.scaledValue(
                  width,
                  220,
                  min: 200,
                  max: 320,
                );
                final buttonPadding = EdgeInsets.symmetric(
                  vertical: Responsive.scaledValue(
                    width,
                    12,
                    min: 10,
                    max: 18,
                  ),
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
                        children: [
                          const Spacer(),
                          SizedBox(
                            width: buttonWidth,
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.home_rounded),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1E6F5C),
                                foregroundColor: Colors.white,
                                padding: buttonPadding,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(28),
                                ),
                                textStyle:
                                    Theme.of(context).textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 20,
                                        ),
                              ),
                              onPressed: () {
                                Navigator.of(context).pushAndRemoveUntil(
                                  MaterialPageRoute(
                                    builder: (_) => const StartScreen(),
                                  ),
                                  (route) => false,
                                );
                              },
                              label: const Padding(
                                padding: EdgeInsets.only(right: 8.0),
                                child: Text('انهاء المستوى'),
                              ),
                            ),
                          ),
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
