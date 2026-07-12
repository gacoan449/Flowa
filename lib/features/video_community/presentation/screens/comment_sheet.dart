import 'package:flutter/material.dart';

class CommentSheet extends StatefulWidget {
  final String videoId;
  const CommentSheet({super.key, required this.videoId});

  @override
  State<CommentSheet> createState() => _CommentSheetState();
}

class _CommentSheetState extends State<CommentSheet> {
  final TextEditingController _commentController = TextEditingController();
  
  // Simulasi daftar komentar dari server
  final List<Map<String, String>> _mockComments = [
    {"user": "Budi_Tani", "text": "Wah info DesaPay sangat bermanfaat gan! 👍"},
    {"user": "Siti_Indah", "text": "Keren videonya, adem bgt ngeliat sawahnya."},
  ];

  void _addComment() {
    if (_commentController.text.trim().isEmpty) return;
    setState(() {
      _mockComments.add({
        "user": "Saya",
        "text": _commentController.text,
      });
      _commentController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.65, // Mengambil 65% tinggi layar HP
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          // Garis kecil penanda bahwa panel bisa di-swipe ke bawah untuk tutup
          Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text("Komentar", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          const Divider(height: 1),
          
          // Daftar isi komentar
          Expanded(
            child: ListView.builder(
              itemCount: _mockComments.length,
              itemBuilder: (context, index) {
                final comment = _mockComments[index];
                return ListTile(
                  leading: const CircleAvatar(backgroundColor: Colors.purple, child: Icon(Icons.person, color: Colors.white)),
                  title: Text(comment['user']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  subtitle: Text(comment['text']!, style: const TextStyle(color: Colors.black87, fontSize: 14)),
                );
              },
            ),
          ),
          
          // Bagian kolom ketik komentar di paling bawah panel
          Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 16, right: 16, top: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      hintText: "Tambahkan komentar...",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: BorderSide.none),
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.purple),
                  onPressed: _addComment,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
