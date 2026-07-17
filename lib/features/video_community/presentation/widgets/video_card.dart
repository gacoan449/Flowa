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
  bool _isPlaying = true;

  @override
  void initState() {
    super.initState();
    // Menginisialisasi pemutar video menggunakan URL dari internet
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..initialize().then((_) {
        // [UPGRADE CTO] Pengecekan 'mounted' mencegah error memori jika 
        // pengguna melakukan scroll cepat sebelum video sempat dimuat
        if (mounted) {
          setState(() {
            _isInitialized = true;
          });
          _controller.setLooping(true); // Otomatis mengulang video jika habis
          _controller.play();           // Otomatis putar video saat dimuat
        }
      });
  }

  @override
  void dispose() {
    // PENTING: Menghapus controller dari memori HP saat video digeser
    _controller.dispose();
    super.dispose();
  }

  void _togglePlay() {
    setState(() {
      if (_controller.value.isPlaying) {
        _controller.pause();
        _isPlaying = false;
      } else {
        _controller.play();
        _isPlaying = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Container(
        color: Colors.black, // Latar belakang hitam elegan saat memuat
        child: const Center(
          child: CircularProgressIndicator(
            color: Colors.amber, 
            strokeWidth: 2.5, // Dibuat lebih tipis agar terkesan mahal & modern
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: _togglePlay,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1. LAPISAN DASAR: Pemutar Video dengan Transisi Halus (Fade-In)
          AnimatedOpacity(
            opacity: _isInitialized ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 600),
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _controller.value.size.width,
                height: _controller.value.size.height,
                child: VideoPlayer(_controller),
              ),
            ),
          ),

          // 2. LAPISAN PELINDUNG VISUAL: Gradien Hitam
          // Memastikan teks putih (Nama Akun, Caption) yang akan ditaruh di atas video 
          // tetap bisa terbaca jelas, meskipun videonya berwarna sangat terang.
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black38,      // Gelap di atas (untuk ikon UI)
                  Colors.transparent,
                  Colors.transparent,
                  Colors.black87,      // Sangat gelap di bawah (untuk caption & info)
                ],
                stops: [0.0, 0.2, 0.6, 1.0],
              ),
            ),
          ),

          // 3. LAPISAN INTERAKSI: Animasi Tombol Play/Pause ala Glassmorphism
          Center(
            child: IgnorePointer( // Memastikan ikon ini tidak mengganggu ketukan jari
              child: AnimatedOpacity(
                opacity: _isPlaying ? 0.0 : 1.0, // Muncul saat pause, hilang saat play
                duration: const Duration(milliseconds: 250),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.4), // Efek transparan mewah
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 70, // Ukuran ikon besar & bulat
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
