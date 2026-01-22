// views/splash/splash_view.dart
import 'package:flutter/material.dart';
import 'package:music_music/views/home/home_screen.dart';

import '../../core/theme/app_colors.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> {
  @override
  void initState() {
    super.initState();
    _navigateToHome();
  }

  _navigateToHome() async {
    await Future.delayed(const Duration(seconds: 4));
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Remove o backgroundColor do Scaffold para que a imagem de fundo seja visível
      // backgroundColor: AppColors.background, 
      body: Stack( // ✅ Usamos um Stack para sobrepor widgets
        children: [
          // ✅ Imagem de Fundo
          Positioned.fill( // Preenche todo o espaço disponível
            child: Image.asset(
              'assets/images/background.png', // ✅ Caminho para sua imagem
              fit: BoxFit.cover, // ✅ Ajusta a imagem para cobrir toda a área
            ),
          ),
          // Conteúdo da Tela de Splash (seu Icon e Text)
       //   Center(
       //     child: Column(
       //       mainAxisAlignment: MainAxisAlignment.center,
           //   children: [
                // Substitua esta linha pelo seu logo
          //      Icon(
          //        Icons.music_note,
           //       size: 100,
          //        color: AppColors.accentPurple, // Mantendo a cor roxa
         //       ),
               // const SizedBox(height: 20),
               // const Text(
                //  'Music App',
                //  style: TextStyle(
                 //   fontSize: 24,
                 //   fontWeight: FontWeight.bold,
                 //   color: Colors.white, // Mantendo a cor branca para contraste com o fundo escuro
                 // ),
              //  ),
        //      ],
       //     ),
      //    ),
        ],
      ),
    );
  }
}