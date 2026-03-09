import 'package:flutter/material.dart';
import 'post_card.dart';

class HomeWidget extends StatefulWidget {
  const HomeWidget({super.key});

  @override
  State<HomeWidget> createState() => _HomeWidgetState();
}

class _HomeWidgetState extends State<HomeWidget> {
  final PageController _pageController = PageController();
  
  final List<Map<String, String>> _videos = [
    {
      'url': 'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4',
      'username': '@amaye_ezechiel',
      'caption': 'Exploration des profondeurs 🌊',
      'music': 'Ocean Vibes - DJ Aqua'
    },
    {
      'url': 'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4',
      'username': '@djebi',
      'caption': 'Un autre monde sous-marin 🐠',
      'music': 'Deep Sea Sound - Nature Beats'
    },
    {
      'url': 'https://sample-videos.com/video321/mp4/720/big_buck_bunny_720p_1mb.mp4',
      'username': '@temu_project',
      'caption': 'Le futur de la vidéo sociale 🌍',
      'music': 'Future Sounds - MixLab'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: _pageController,
      scrollDirection: Axis.vertical,
      itemCount: _videos.length,
      itemBuilder: (context, index) {
        final video = _videos[index];
        return PostCard(
          videoUrl: video['url']!,
          username: video['username']!,
          caption: video['caption']!,
          music: video['music']!,
        );
      },
    );
  }
}
