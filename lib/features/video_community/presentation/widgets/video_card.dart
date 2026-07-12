import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoCard extends StatefulWidget {
  final String videoUrl;
  
  const VideoCard({
    super.key, 
    required this.videoUrl,
  });

  @override
  State<VideoCard> createState() => _VideoCardState();
}

class _VideoCardState extends State<VideoCard> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    // Menginisialisasi pemutar video menggunakan URL dari internet
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..initialize().then((_) {
        setState(() {
          _isInitialized = true;
        });
        _controller.setLooping(true); // Otomatis mengulang video jika habis
        _controller.play();           // Otomatis putar video saat dimuat
      });
  }

  @override
  void dispose() {
    // PENTING: Menghapus controller dari memori HP saat video digeser
    // Ini rahasia agar aplikasi Flowa tetap ringan seperti FB Lite!
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Center(
        child: CircularProgressIndicator(
          color: Colors.amber, // Loading spinner melingkar sebelum video berputar
        ),
      );
    }

    return GestureDetector(
      onTap: () {
        // Fitur ketuk layar untuk Pause / Play video
        setState(() {
          _controller.value.isPlaying ? _controller.pause() : _controller.play();
        });
      },
      child: SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.cover, // Membuat video memenuhi seluruh layar HP mirip TikTok
          child: SizedBox(
            width: _controller.value.size.width,
            height: _controller.value.size.height,
            child: VideoPlayer(_controller),
          ),
        ),
      ),
    );
  }
}
