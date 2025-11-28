import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../utils/responsive.dart';
import '../utils/sound_effects.dart';
import 'level_completion_screen.dart';

class LevelOnePhotoScreen extends StatefulWidget {
  const LevelOnePhotoScreen({super.key});

  @override
  State<LevelOnePhotoScreen> createState() => _LevelOnePhotoScreenState();
}

class _LevelOnePhotoScreenState extends State<LevelOnePhotoScreen> {
  /// الأساس: بنحدد المسارات + التصنيف فقط (من غير وصف ثابت)
  static const List<PhotoQuestion> _base = [
    // سيّئ
    PhotoQuestion(
      assetPath: 'assets/images/LevelOne/bad1.jpg', // تمديدات التكييفات
      category: PhotoCategory.visualPollution,
      description: '', // سنملأه ديناميكياً
    ),
    PhotoQuestion(
      assetPath: 'assets/images/LevelOne/bad2.jpg', // سيارات تالفة
      category: PhotoCategory.visualPollution,
      description: '',
    ),
    PhotoQuestion(
      assetPath: 'assets/images/LevelOne/bad3.jpg', // مخلفات البناء
      category: PhotoCategory.visualPollution,
      description: '',
    ),
    PhotoQuestion(
      assetPath: 'assets/images/LevelOne/bad4.jpg', // أطباق الأقمار
      category: PhotoCategory.visualPollution,
      description: '',
    ),
    PhotoQuestion(
      assetPath: 'assets/images/LevelOne/bad5.jpg', // هناجر مخالفة
      category: PhotoCategory.visualPollution,
      description: '',
    ),

    // جيّد
    PhotoQuestion(
      assetPath: 'assets/images/LevelOne/good1.jpg', // نظافة الأماكن العامة والحدائق
      category: PhotoCategory.civilizedView,
      description: '',
    ),
    PhotoQuestion(
      assetPath: 'assets/images/LevelOne/good2.jpg', // تناسق ألوان الواجهات
      category: PhotoCategory.civilizedView,
      description: '',
    ),
    PhotoQuestion(
      assetPath: 'assets/images/LevelOne/good3.jpg', // أطفال ينظفون الحديقة
      category: PhotoCategory.civilizedView,
      description: '',
    ),
    PhotoQuestion(
      assetPath: 'assets/images/LevelOne/good4.jpg', // إزالة النفايات في المكان المخصص
      category: PhotoCategory.civilizedView,
      description: '',
    ),
    PhotoQuestion(
      assetPath: 'assets/images/LevelOne/good5.jpg', // منظَر حضاري مرتب/حديقة مُعتنى بها
      category: PhotoCategory.civilizedView,
      description: '',
    ),
  ];

  /// أوصاف مناسبة لكل صورة حسب المسار الذي ذكرتَه
  static const Map<String, String> _descriptionsByAsset = {
    // سيّئ (تشوّه بصري)
    'assets/images/LevelOne/bad1.jpg':
        'تمديدات أجهزة التكييف الظاهرة والعشوائية تشوّه واجهات المباني وتعرّض السكان للخطر عند التسرب أو السقوط.',
    'assets/images/LevelOne/bad2.jpg':
        'السيارات التالفة والمتروكة في الشوارع تشغل الأرصفة وتعيق الحركة وتُعد منظراً غير حضاري.',
    'assets/images/LevelOne/bad3.jpg':
        'مخلفات البناء والركام الملقى في غير أماكنه يعرّض المارة للأذى ويشوّه المشهد العام.',
    'assets/images/LevelOne/bad4.jpg':
        'أطباق الأقمار الصناعية المركّبة بشكل عشوائي على الواجهات والأسطح تسبب فوضى بصرية وقد تؤثر على السلامة.',
    'assets/images/LevelOne/bad5.jpg':
        'هناجر أو منشآت مخالفة دون تراخيص تشوّه النسيج العمراني وتخالف الأنظمة البلدية.',

    // جيّد (منظر حضاري)
    'assets/images/LevelOne/good1.jpg':
        'نظافة الحدائق والأماكن العامة تمنح الجميع مساحة آمنة وجميلة للاسترخاء واللعب.',
    'assets/images/LevelOne/good2.jpg':
        'تناسق ألوان واجهات المباني يخلق منظراً حضارياً متّحداً يريح العين ويعكس الذوق العام.',
    'assets/images/LevelOne/good3.jpg':
        'مشاركة الأطفال في تنظيف الحديقة سلوك إيجابي يغرس قيمة المحافظة على البيئة منذ الصغر.',
    'assets/images/LevelOne/good4.jpg':
        'التخلّص من النفايات في الحاويات المخصّصة يحافظ على نظافة الشوارع ويمنع الروائح والحشرات.',
    'assets/images/LevelOne/good5.jpg':
        'اعتناء المجتمع بالمساحات الخضراء وتنظيمها يرفع جودة الحياة ويزيد جمال الحي.',
  };

  /// القائمة التي سنعرضها بعد إضافة الأوصاف وخلط الترتيب
  late final List<PhotoQuestion> _questions;

  int _currentIndex = 0;
  bool? _isAnswerCorrect;
  bool _showFeedback = false;

  @override
  void initState() {
    super.initState();
    // جهّز القائمة بالأوصاف الصحيحة لكل عنصر
    final filled = _base.map((q) {
      final desc = _descriptionsByAsset[q.assetPath] ?? '';
      return PhotoQuestion(
        assetPath: q.assetPath,
        category: q.category,
        description: desc,
      );
    }).toList();

    // اعمل Shuffle عشوائي كل مرة تفتح فيها الشاشة
    final rng = Random(DateTime.now().millisecondsSinceEpoch);
    filled.shuffle(rng);
    _questions = filled;
  }

  PhotoQuestion get _currentQuestion => _questions[_currentIndex];
  String get _currentImage => _currentQuestion.assetPath;
  bool get _isLastQuestion => _currentIndex == _questions.length - 1;

  void _onAnswerSelected(PhotoCategory category) {
    if (_showFeedback) return;

    SoundEffects.playClaim();
    final isCorrect = category == _currentQuestion.category;
    setState(() {
      _isAnswerCorrect = isCorrect;
      _showFeedback = true;
    });
  }

  void _handleNextQuestion() {
    if (_isLastQuestion) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LevelCompletionScreen()),
      );
      return;
    }
    setState(() {
      _currentIndex += 1;
      _isAnswerCorrect = null;
      _showFeedback = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/images/levelBackground.png', fit: BoxFit.cover),
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
                    max: 40,
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
                  36,
                  min: 20,
                  max: 60,
                );
                final betweenSpacing = Responsive.scaledValue(
                  width,
                  24,
                  min: 20,
                  max: 40,
                );
                final imageMaxWidth = Responsive.scaledValue(
                  width,
                  320,
                  min: 260,
                  max: 420,
                );
                final imageMaxHeight = Responsive.scaledValue(
                  width,
                  240,
                  min: 200,
                  max: 320,
                );
                final buttonSpacing = Responsive.scaledValue(
                  width,
                  16,
                  min: 12,
                  max: 24,
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
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(height: topSpacing),
                          Text(
                            'اختر نوع الصورة',
                            textAlign: TextAlign.center,
                            style: textTheme.displaySmall?.copyWith(
                              fontSize: 34,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: betweenSpacing),
                          Expanded(
                            child: Center(
                              child: Container(
                                constraints: BoxConstraints(
                                  maxWidth: imageMaxWidth,
                                  maxHeight: imageMaxHeight,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(28),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.25),
                                      blurRadius: 20,
                                      offset: const Offset(0, 14),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(28),
                                  child: Image.asset(
                                    _currentImage,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: betweenSpacing),
                          Row(
                            children: [
                              Expanded(
                                child: _ChoiceButton(
                                  label: 'تشوه بصري',
                                  backgroundColor: const Color(0xFFA66B55),
                                  textColor: const Color(0xFFF7E7DC),
                                  onPressed: _showFeedback
                                      ? null
                                      : () =>
                                          _onAnswerSelected(PhotoCategory.visualPollution),
                                ),
                              ),
                              SizedBox(width: buttonSpacing),
                              Expanded(
                                child: _ChoiceButton(
                                  label: 'منظر حضاري',
                                  backgroundColor: const Color(0xFF1E6F5C),
                                  textColor: const Color(0xFFEAF5EE),
                                  onPressed: _showFeedback
                                      ? null
                                      : () =>
                                          _onAnswerSelected(PhotoCategory.civilizedView),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // طبقة التغذية الراجعة
          if (_showFeedback && _isAnswerCorrect != null)
            _AnswerFeedbackOverlay(
              question: _currentQuestion,
              isCorrect: _isAnswerCorrect!,
              isLastQuestion: _isLastQuestion,
              onNext: _handleNextQuestion,
              onTryAgain: () {
                setState(() {
                  _showFeedback = false;
                  _isAnswerCorrect = null;
                });
              },
            ),
        ],
      ),
    );
  }
}

class PhotoQuestion {
  const PhotoQuestion({
    required this.assetPath,
    required this.category,
    required this.description,
  });

  final String assetPath;
  final PhotoCategory category;
  final String description;
}

enum PhotoCategory { visualPollution, civilizedView }

class _AnswerFeedbackOverlay extends StatelessWidget {
  const _AnswerFeedbackOverlay({
    required this.question,
    required this.isCorrect,
    required this.isLastQuestion,
    required this.onNext,
    required this.onTryAgain,
  });

  final PhotoQuestion question;
  final bool isCorrect;
  final bool isLastQuestion;
  final VoidCallback onNext;
  final VoidCallback onTryAgain;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final Color accentColor =
        isCorrect ? const Color(0xFF1E6F5C) : const Color(0xFFA8443D);
    final IconData icon =
        isCorrect ? Icons.check_circle_rounded : Icons.close_rounded;
    final String title = isCorrect ? 'إجابة صحيحة' : 'إجابة خاطئة';
    final String buttonLabel =
        isCorrect ? (isLastQuestion ? 'إنهاء' : 'التالي') : 'حاول مجدداً';

    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.55),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withOpacity(0.3),
                    blurRadius: 28,
                    offset: const Offset(0, 18),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Icon(icon, color: accentColor, size: 48),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: accentColor,
                    ),
                  ),
                  const SizedBox(height: 18),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: Image.asset(
                      question.assetPath,
                      height: 160,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    isCorrect
                        ? question.description
                        : 'فكّر مرة أخرى ولاحظ تفاصيل الصورة لتحديد الاختيار الصحيح.',
                    textAlign: TextAlign.center,
                    style: textTheme.titleMedium?.copyWith(
                      fontSize: 20,
                      height: 1.5,
                      color: const Color(0xFF4A4A4A),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(22),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: 20,
                        ),
                      ),
                      onPressed: () {
                        SoundEffects.playClaim();
                        if (isCorrect) {
                          if (isLastQuestion) {
                            Future<void>.delayed(
                              const Duration(milliseconds: 150),
                              SoundEffects.playCorrect,
                            );
                          }
                          onNext();
                        } else {
                          onTryAgain();
                        }
                      },
                      child: Text(buttonLabel),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ChoiceButton extends StatelessWidget {
  const _ChoiceButton({
    required this.label,
    required this.backgroundColor,
    required this.onPressed,
    this.textColor = Colors.white,
  });

  final String label;
  final Color backgroundColor;
  final Color textColor;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final bool isEnabled = onPressed != null;

    return SizedBox(
      height: 64,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: isEnabled ? backgroundColor : backgroundColor.withOpacity(0.55),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: backgroundColor.withOpacity(isEnabled ? 0.38 : 0.15),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: isEnabled
                ? () {
                    SoundEffects.playClaim();
                    onPressed!();
                  }
                : null,
            child: Center(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: textTheme.titleMedium?.copyWith(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: isEnabled ? textColor : textColor.withOpacity(0.7),
                  height: 1.2,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
