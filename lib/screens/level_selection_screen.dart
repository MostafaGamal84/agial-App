import 'package:flutter/material.dart';

import '../utils/responsive.dart';
import 'level_one_screen.dart';
import 'level_two_intro_screen.dart';
import 'level_three_intro_screen.dart';

class LevelSelectionScreen extends StatelessWidget {
  const LevelSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/levelBackground.png',
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
                    max: 64,
                  ),
                  maxContentWidth: Responsive.valueForWidth(
                    width,
                    narrow: 560,
                    wide: 720,
                    breakpoint: 900,
                  ),
                );
                final textScale = Responsive.scaleForWidth(
                  width,
                  baseWidth: 390,
                  minScale: 0.95,
                  maxScale: 1.2,
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
                final headerSpacing = Responsive.scaledValue(
                  width,
                  12,
                  min: 10,
                  max: 24,
                );
                final sectionSpacing = Responsive.scaledValue(
                  width,
                  50,
                  min: 36,
                  max: 72,
                );
                final buttonSpacing = Responsive.scaledValue(
                  width,
                  20,
                  min: 16,
                  max: 28,
                );

                return MediaQuery(
                  data: mediaQuery.copyWith(textScaleFactor: textScale),
                  child: Padding(
                    padding: padding,
                    child: Directionality(
                      textDirection: TextDirection.rtl,
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 720),
                          child: SingleChildScrollView(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  'حدد المستوى',
                                  textAlign: TextAlign.center,
                                  style: textTheme.displaySmall?.copyWith(
                                    fontSize: 40,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(height: headerSpacing),
                                Text(
                                  'اختر المغامرة المناسبة لك وابدأ اللعب!',
                                  textAlign: TextAlign.center,
                                  style: textTheme.titleMedium?.copyWith(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(height: sectionSpacing),

                                // أزرار المستويات
                                for (var index = 0; index < 3; index++)
                                  Padding(
                                    padding:
                                        EdgeInsets.symmetric(vertical: buttonSpacing / 2),
                                    child: TweenAnimationBuilder<double>(
                                      duration: Duration(milliseconds: 700 + index * 120),
                                      curve: Curves.easeOutBack,
                                      tween: Tween<double>(begin: 0, end: 1),
                                      builder: (context, value, child) {
                                        return Transform.translate(
                                          offset: Offset(0, (1 - value) * 40),
                                          child: Transform.scale(
                                            scale: value,
                                            child: child,
                                          ),
                                        );
                                      },
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
                                            shadowColor: const Color(0xFF1E6F5C).withOpacity(0.35),
                                            textStyle: textTheme.titleMedium?.copyWith(
                                              fontSize: 22,
                                              fontWeight: FontWeight.w800,
                                              color: Colors.white,
                                            ),
                                          ),
                                          onPressed: () {
                                            if (index == 0) {
                                              Navigator.of(context).push(
                                                MaterialPageRoute(
                                                  builder: (_) => const LevelOneScreen(),
                                                ),
                                              );
                                            } else if (index == 1) {
                                              Navigator.of(context).push(
                                                MaterialPageRoute(
                                                  builder: (_) => const LevelTwoIntroScreen(),
                                                ),
                                              );
                                            } else {
                                              Navigator.of(context).push(
                                                MaterialPageRoute(
                                                  builder: (_) => const LevelThreeIntroScreen(),
                                                ),
                                              );
                                            }
                                          },
                                          child: Text(
                                            [
                                              'المستوى 1',
                                              'المستوى 2',
                                              'المستوى 3',
                                            ][index],
                                            style: textTheme.titleMedium?.copyWith(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w800,
                                              fontSize: 22,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
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
