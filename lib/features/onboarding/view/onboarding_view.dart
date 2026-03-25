import 'package:flutter/material.dart';
import 'package:logbook_app_001/features/auth/view/login_view.dart';

class OnBoardingView extends StatefulWidget {
  const OnBoardingView({super.key});

  @override
  State<OnBoardingView> createState() => _OnBoardingViewState();
}

class OnboardingContent extends StatelessWidget {
  final String title, desc, image;

  const OnboardingContent({
    super.key,
    required this.title,
    required this.desc,
    required this.image,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset(image, height: 250), 
        const SizedBox(height: 30),
        Text(
          title,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 15),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Text(
            desc,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
      ],
    );
  }
}

class _OnBoardingViewState extends State<OnBoardingView> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final List<Map<String, String>> onboardingData = [
    {
      "title": "Catat Aktivitas",
      "desc": "Mudah mencatat setiap progres tugasmu secara real-time",
      "image": "assets/Hal-1.png"
    },
    {
      "title": "Pantau Riwayat",
      "desc": "Lihat kembali apa saja yang sudah kamu kerjakan hari ini.",
      "image": "assets/Hal-2.png"
    },
    {
      "title": "Mulai Sekarang",
      "desc": "Ayo masuk dan kelola logbook kamu dengan lebih profesional.",
      "image": "assets/Hal-3.png"
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (value) => setState(() => _currentPage = value),
              itemCount: onboardingData.length,
              itemBuilder: (context, index) => OnboardingContent(
                title: onboardingData[index]["title"]!,
                desc: onboardingData[index]["desc"]!,
                image: onboardingData[index]["image"]!,
              ),
            ),
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              onboardingData.length,
              (index) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 5),
                height: 10,
                width: _currentPage == index ? 25 : 10,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(5),
                  color: _currentPage == index ? Colors.indigo : Colors.grey.shade300,
                ),
              ),
            ),
          ),

          const SizedBox(height: 50),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  if (_currentPage == onboardingData.length - 1) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const LoginView()),
                    );
                  } else {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeIn,
                    );
                  }
                },
                child: Text(_currentPage == onboardingData.length - 1 ? "MASUK" : "LANJUT"),
              ),
            ),
          ),
        ],
      ),
    );
  }
}