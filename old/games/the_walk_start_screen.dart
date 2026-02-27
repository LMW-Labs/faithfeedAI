import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../theme/app_theme.dart';
import 'the_walk_screen.dart';

class TheWalkStartScreen extends StatelessWidget {
  const TheWalkStartScreen({super.key});

  void _startGame(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const TheWalkScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppTheme.lightBackgroundGradient,
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          systemOverlayStyle: SystemUiOverlayStyle.dark,
          title: const Text(
            'The Walk',
            style: TextStyle(color: AppTheme.lightOnSurface),
          ),
          iconTheme: const IconThemeData(color: AppTheme.lightOnSurface),
        ),
        body: Center(
          child: Padding(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 24,
              bottom: 24 + MediaQuery.of(context).padding.bottom,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppTheme.primaryTeal, AppTheme.lightBlue],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: SvgPicture.asset(
                    'assets/thewalk.svg',
                    width: 80,
                    height: 80,
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Experience the journey of Jesus and other biblical figures.',
                  style: TextStyle(
                    color: AppTheme.lightOnSurface,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: () => _startGame(context),
                    icon: const Icon(Icons.play_arrow),
                    label: const Text(
                      'Start Walking',
                      style: TextStyle(fontSize: 18),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryTeal,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
