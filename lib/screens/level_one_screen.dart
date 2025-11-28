import 'package:flutter/material.dart';
import 'package:said_alakhtha/screens/level_one_photo_screen.dart';

import 'package:said_alakhtha/utils/responsive.dart';
class LevelOneScreen extends StatelessWidget {
  const LevelOneScreen({super.key});

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
                    max: 56,
                  ),
                  maxContentWidth: Responsive.valueForWidth(
                    width,
                    narrow: 560,
                    wide: 720,
                    breakpoint: 900,
                  ),
                );
                final topSpacing = Responsive.scaledValue(
                  width,
                  48,
                  min: 28,
                  max: 72,
                );
                final betweenSpacing = Responsive.scaledValue(
                  width,
                  32,
                  min: 24,
                  max: 48,
                );
                final footerSpacing = Responsive.scaledValue(
                  width,
                  28,
                  min: 20,
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
                  max: 78,
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
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 720),
                          child: SingleChildScrollView(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                SizedBox(height: topSpacing),
                                Text(
                                  'لعبة خمن الصورة',
                                  textAlign: TextAlign.center,
                                  style: textTheme.displayMedium?.copyWith(
                                    fontSize: 44,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    height: 1.2,
                                  ),
                                ),
                                SizedBox(height: betweenSpacing),
                                LayoutBuilder(
                                  builder: (context, innerConstraints) {
                                    const spacing = 18.0;
                                    const minCardWidth = 140.0;
                                    const maxCardWidth = 194.0;
                                    final maxWidth = innerConstraints.maxWidth;

                                    double cardWidth;
                                    bool useRowLayout = true;

                                    if (maxWidth >= (maxCardWidth * 2) + spacing) {
                                      cardWidth = maxCardWidth;
                                    } else if (maxWidth >= (minCardWidth * 2) + spacing) {
                                      cardWidth = (maxWidth - spacing) / 2;
                                    } else {
                                      cardWidth = maxWidth;
                                      useRowLayout = false;
                                    }

                                    if (useRowLayout) {
                                      return Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          _LevelChoiceCard(
                                            title: 'منظر حضاري',
                                            backgroundImage: 'assets/images/true.png',
                                            width: cardWidth,
                                          ),
                                          const SizedBox(width: spacing),
                                          _LevelChoiceCard(
                                            title: 'تشوه بصري',
                                            backgroundImage: 'assets/images/false.png',
                                            width: cardWidth,
                                          ),
                                        ],
                                      );
                                    }

                                    return Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        _LevelChoiceCard(
                                          title: 'منظر حضاري',
                                          backgroundImage: 'assets/images/true.png',
                                          width: cardWidth,
                                        ),
                                        const SizedBox(height: spacing),
                                        _LevelChoiceCard(
                                          title: 'تشوه بصري',
                                          backgroundImage: 'assets/images/false.png',
                                          width: cardWidth,
                                        ),
                                      ],
                                    );
                                  },
                                ),
                                SizedBox(height: footerSpacing),
                                SizedBox(
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
                                          builder: (context) =>
                                              const LevelOnePhotoScreen(),
                                        ),
                                      );
                                    },
                                    child: const Text('ابدأ اللعب'),
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

class _LevelChoiceCard extends StatelessWidget {
  const _LevelChoiceCard({
    required this.title,
    required this.backgroundImage,
    this.width = 194,
    this.height = 102,
  });

  final String title;
  final String backgroundImage;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                backgroundImage,
                fit: BoxFit.cover,
              ),
              Container(
                alignment: Alignment.center,
                color: Colors.black.withOpacity(0.35),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
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
