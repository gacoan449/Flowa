import 'package:flutter/material.dart';

class InteractionButtons extends StatelessWidget {
  final int likes;
  final int comments;
  final VoidCallback onLikePressed;
  final VoidCallback onCommentPressed;
  final VoidCallback onSharePressed;

  const InteractionButtons({
    super.key,
    required this.likes,
    required this.comments,
    required this.onLikePressed,
    required this.onCommentPressed,
    required this.onSharePressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Tombol Like
        _buildIconButton(
          icon: Icons.favorite,
          label: likes.toString(),
          color: Colors.red,
          onTap: onLikePressed,
        ),
        const SizedBox(height: 16),
        
        // Tombol Komentar
        _buildIconButton(
          icon: Icons.comment,
          label: comments.toString(),
          color: Colors.white,
          onTap: onCommentPressed,
        ),
        const SizedBox(height: 16),
        
        // Tombol Share / Bagikan
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
          Icon(icon, color: color, size: 35),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
