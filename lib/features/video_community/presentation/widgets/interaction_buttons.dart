import 'package:flutter/material.dart';

class InteractionButtons extends StatelessWidget {
  final int likes;
  final int comments;
  final int bookmarks; 
  final bool isLiked;
  final bool isBookmarked; 
  final VoidCallback onLikePressed;
  final VoidCallback onCommentPressed;
  final VoidCallback onBookmarkPressed; 
  final VoidCallback onSharePressed;

  const InteractionButtons({
    super.key,
    required this.likes,
    required this.comments,
    required this.bookmarks,
    required this.isLiked,
    required this.isBookmarked,
    required this.onLikePressed,
    required this.onCommentPressed,
    required this.onBookmarkPressed,
    required this.onSharePressed,
  });

  // [UPGRADE CTO] Fungsi utilitas untuk menyingkat angka skala besar (Contoh: 1500 -> 1.5K)
  // Menjaga UI tetap rapi saat video viral dan mencapai jutaan views/likes
  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Tombol Like (Suka) - Berubah dari Outline ke Solid
        _buildPremiumIconButton(
          icon: isLiked ? Icons.favorite : Icons.favorite_border_rounded,
          label: _formatNumber(likes),
          color: isLiked ? Colors.redAccent : Colors.white,
          onTap: onLikePressed,
          isActive: isLiked,
        ),
        const SizedBox(height: 22),
        
        // Tombol Komentar
        _buildPremiumIconButton(
          icon: Icons.chat_bubble_outline_rounded, // Ikon membulat yang lebih modern
          label: _formatNumber(comments),
          color: Colors.white,
          onTap: onCommentPressed,
          isActive: false,
        ),
        const SizedBox(height: 22),

        // Tombol Bookmark / Simpan Video (DesaPay Gold Edition)
        _buildPremiumIconButton(
          icon: isBookmarked ? Icons.bookmark : Icons.bookmark_border_rounded,
          label: _formatNumber(bookmarks),
          color: isBookmarked ? Colors.amber : Colors.white,
          onTap: onBookmarkPressed,
          isActive: isBookmarked,
        ),
        const SizedBox(height: 22),
        
        // Tombol Share (Bagikan)
        _buildPremiumIconButton(
          icon: Icons.reply_rounded, // Standar ikon share pada platform video pendek (seperti panah melengkung)
          label: "Bagikan",
          color: Colors.white,
          onTap: onSharePressed,
          isActive: false,
        ),
      ],
    );
  }

  // [UPGRADE CTO] Pembangun Ikon Khusus dengan Animasi & Shadow
  Widget _buildPremiumIconButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    required bool isActive,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque, // Memastikan area ketukan direspons sempurna meski meleset beberapa piksel
      child: Column(
        children: [
          // Animasi pergantian Ikon (Micro-interaction)
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            transitionBuilder: (Widget child, Animation<double> animation) {
              // Memberikan efek membesar (Scale) saat tombol ditekan
              return ScaleTransition(scale: animation, child: child);
            },
            child: Icon(
              icon,
              key: ValueKey<String>('$icon$isActive'), // Kunci agar mesin Flutter tahu kapan harus menganimasi
              color: color,
              size: 38, // Diperbesar sedikit agar mudah ditekan
              shadows: const [
                Shadow(
                  color: Colors.black54,
                  blurRadius: 10,
                  offset: Offset(0, 2),
                )
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white, 
              fontSize: 13, 
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(
                  color: Colors.black87,
                  blurRadius: 4,
                  offset: Offset(1, 1),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
