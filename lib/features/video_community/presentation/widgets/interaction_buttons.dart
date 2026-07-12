import 'package:flutter/material.dart';

class InteractionButtons extends StatelessWidget {
  final int likes;
  final int comments;
  final int bookmarks; // Parameter baru untuk hitungan simpan
  final bool isLiked;
  final bool isBookmarked; // Parameter baru untuk status warna simpan
  final VoidCallback onLikePressed;
  final VoidCallback onCommentPressed;
  final VoidCallback onBookmarkPressed; // Callback baru
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

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Tombol Like (Suka)
        _buildIconButton(
          icon: Icons.favorite,
          label: likes.toString(),
          color: isLiked ? Colors.red : Colors.white,
          onTap: onLikePressed,
        ),
        const SizedBox(height: 18),
        
        // Tombol Komentar
        _buildIconButton(
          icon: Icons.comment,
          label: comments.toString(),
          color: Colors.white,
          onTap: onCommentPressed,
        ),
        const SizedBox(height: 18),

        // TOMBOL BARU: Bookmark / Simpan Video ala TikTok (Menarik & Interaktif)
        _buildIconButton(
          icon: isBookmarked ? Icons.bookmark : Icons.bookmark_border,
          label: bookmarks.toString(),
          color: isBookmarked ? Colors.amber : Colors.white, // Berubah jadi Emas DesaPay saat disimpan
          onTap: onBookmarkPressed,
        ),
        const SizedBox(height: 18),
        
        // Tombol Share (Bagikan)
        _buildIconButton(
          icon: Icons.share,
          label: "Bagikan",
          color: Colors.white,
          onTap: onSharePressed,
        ),
      ],
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: color, size: 36),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
