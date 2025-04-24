import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final User? currentUser = FirebaseAuth.instance.currentUser;
  String? _username;
  String? _userRole;
  List<QueryDocumentSnapshot> _messages = [];
  String? _defaultProfileImageUrl;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadMessages();
    _loadDefaultProfileImageUrl();
  }

  Future<void> _loadDefaultProfileImageUrl() async {
    try {
      final defaultRef = FirebaseStorage.instance
          .ref()
          .child('profile_images/defaultImage/default.jpg');
      final url = await defaultRef.getDownloadURL();
      setState(() {
        _defaultProfileImageUrl = url;
      });
    } catch (e) {
      print('Error loading default profile image URL: $e');
    }
  }

  Future<void> _loadUserData() async {
    if (currentUser != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .get();
      final data = userDoc.data();
      setState(() {
        _username = data?['username'] ?? 'Unknown';
        _userRole = data?['role'] ?? 'user';
      });
    }
  }

  Future<void> _loadMessages() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('community_messages')
        .orderBy('timestamp', descending: false)
        .get();

    setState(() {
      _messages = snapshot.docs;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final messageText = _controller.text.trim();
    if (messageText.isEmpty || _username == null) return;

    await FirebaseFirestore.instance.collection('community_messages').add({
      'username': _username,
      'message': messageText,
      'senderId': currentUser!.uid,
      'timestamp': FieldValue.serverTimestamp(),
    });

    _controller.clear();
    await _loadMessages();
  }

  Future<void> _deleteMessage(String docId) async {
    try {
      await FirebaseFirestore.instance
          .collection('community_messages')
          .doc(docId)
          .delete();
      await _loadMessages();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Message deleted')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting message: $e')),
      );
    }
  }

  Future<Widget> _buildAvatar(String senderId, String username) async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(senderId)
          .get();
      final data = userDoc.data();
      final url = data?['profileImageUrl'];

      if (url != null && url.toString().isNotEmpty) {
        return CircleAvatar(
          radius: 16,
          backgroundImage: NetworkImage(url),
        );
      } else {
        return CircleAvatar(
          radius: 16,
          backgroundImage: _defaultProfileImageUrl != null
              ? NetworkImage(_defaultProfileImageUrl!)
              : null,
        );
      }
    } catch (e) {
      return CircleAvatar(
        radius: 16,
        backgroundColor: Colors.tealAccent,
        child: Text(
          username[0].toUpperCase(),
          style: const TextStyle(
              color: Colors.black, fontWeight: FontWeight.bold, fontSize: 14),
        ),
      );
    }
  }

  Widget _buildMessageBubble(QueryDocumentSnapshot doc) {
    final Map<String, dynamic> msg = doc.data() as Map<String, dynamic>;
    final bool isMe = msg['senderId'] == currentUser?.uid;
    final String message = msg['message'];
    final String senderId = msg['senderId'];
    final String username = msg['username'];
    final String docId = doc.id;

    return GestureDetector(
      onLongPress: () {
        if (!isMe && _userRole == 'admin') {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('Delete Message'),
              content:
                  const Text('Are you sure you want to delete this message?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _deleteMessage(docId);
                  },
                  child:
                      const Text('Delete', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          );
        }
      },
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
          padding: const EdgeInsets.all(12),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.8,
          ),
          decoration: BoxDecoration(
            color: isMe
                ? (Theme.of(context).brightness == Brightness.dark
                    ? Colors.blueGrey.shade700
                    : Colors.blueAccent)
                : Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(isMe ? 16 : 4),
              bottomRight: Radius.circular(isMe ? 4 : 16),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 5,
                offset: const Offset(0, 2),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment:
                isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              if (!isMe)
                FutureBuilder<Widget>(
                  future: _buildAvatar(senderId, username),
                  builder: (context, snapshot) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        snapshot.data ?? const SizedBox.shrink(),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            username,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 16,
                              color: isMe
                                  ? Colors.white
                                  : Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.color,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                )
              else
                const Text(
                  'Me',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Colors.white70,
                  ),
                ),
              const SizedBox(height: 8),
              Text(
                message,
                style: TextStyle(
                  fontSize: 16,
                  color: isMe ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Community Chat'),
        flexibleSpace: Theme.of(context).brightness == Brightness.dark
            ? Container(color: const Color(0xFF1E1E1E))
            : Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blueAccent, Colors.tealAccent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? const Center(child: Text('No messages yet.'))
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(10),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) =>
                        _buildMessageBubble(_messages[index]),
                  ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: "Type your message...",
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      fillColor: Theme.of(context).colorScheme.surface,
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: const BorderSide(color: Colors.blueAccent),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Ink(
                  decoration: ShapeDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey.shade700
                        : Colors.blueAccent,
                    shape: const CircleBorder(),
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.send,
                      color: Theme.of(context).iconTheme.color,
                    ),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
