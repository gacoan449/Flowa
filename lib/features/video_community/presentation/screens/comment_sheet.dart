import 'package:flutter/material.dart';

class CommentSheet extends StatefulWidget {
  final String videoId;
  const CommentSheet({super.key, required this.videoId});

  @override
  State<CommentSheet> createState() => _CommentSheetState();
}

class _CommentSheetState extends State<CommentSheet> {
  final TextEditingController _commentController = TextEditingController();
  
  final List<Map<String, String>> _mockComments = [
    {"user": "Budi_Tani", "text": "Wah info DesaPay sangat bermanfaat gan! 👍"},
    {"user": "Siti_Indah", "text": "Keren videonya, adem bgt ngeliat sawahnya."},
  ];

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _addComment() {
    if (_commentController.text.trim().isEmpty) return;
    setState(() {
      _mockComments.add({
        "user": "Saya",
        "text": _commentController.text,
      });
      _commentController.clear();
    });
    // Menutup keyboard setelah kirim
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          // Handle/Drag bar yang lebih estetik
          Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
          
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text("Komentar", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
          ),
          const Divider(height: 1),
          
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _mockComments.length,
              itemBuilder: (context, index) {
                final comment = _mockComments[index];
                return ListTile(
                  leading: const CircleAvatar(backgroundColor: Colors.purpleAccent, child: Icon(Icons.person, color: Colors.white, size: 20)),
                  title: Text(comment['user']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
                  subtitle: Text(comment['text']!, style: const TextStyle(color: Colors.black54, fontSize: 14)),
                );
              },
            ),
          ),
          
          // [UPGRADE CTO] Input Area dengan Padding & Keyboard Handling yang stabil
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      decoration: InputDecoration(
                        hintText: "Tulis pendapatmu...",
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: BorderSide.none),
                        filled: true,
                        fillColor: Colors.grey[100],
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.send_rounded, color: Colors.purple, size: 28),
                    onPressed: _addComment,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
