import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import '../utils/custom_snackbar.dart';

class AIChatScreen extends StatefulWidget {
  const AIChatScreen({super.key});

  @override
  _AIChatScreenState createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen> {
  final List<Map<String, String>> _messages = [];
  final TextEditingController _controller = TextEditingController();
  final apiKey = dotenv.env['OPENAI_API_KEY'];
  bool _isLoading = false;
  bool hasInternet = true;

  @override
  void initState() {
    super.initState();
    _checkInternet();
    _loadMessagesFromLocal();
  }

  Future<void> _checkInternet() async {
    try {
      final result = await InternetAddress.lookup('example.com');
      setState(() {
        hasInternet = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      });
    } on SocketException {
      setState(() => hasInternet = false);
    }
  }

  Future<void> _sendMessage() async {
    await _checkInternet(); // ✅ újraellenőrzés

    if (!hasInternet) {
      showCustomSnackBar(context, "You are offline. AI Chat is unavailable.",
          isError: true);
      return;
    }

    if (_controller.text.isEmpty) return;

    setState(() {
      _messages.add({"sender": "user", "message": _controller.text});
      _isLoading = true;
    });

    final userMessage = _controller.text;
    _controller.clear();

    try {
      final response = await _getAIResponse(userMessage);

      setState(() {
        _messages.add({"sender": "AI", "message": response});
      });
    } catch (e) {
      setState(() {
        _messages.add({"sender": "AI", "message": "Failed to fetch response."});
      });
    } finally {
      _isLoading = false;
      await _saveMessagesToLocal();
    }
  }

  Future<String> _getAIResponse(String prompt) async {
    const url = 'https://api.openai.com/v1/chat/completions';
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $apiKey',
    };
    final body = jsonEncode({
      "model": "gpt-3.5-turbo",
      "messages": [
        {
          "role": "system",
          "content":
              "You are an AI assistant that specializes in providing advice and answering questions about healthy living and fitness training. Avoid discussing topics outside of these domains."
        },
        {"role": "user", "content": prompt},
      ],
    });

    final response =
        await http.post(Uri.parse(url), headers: headers, body: body);

    if (response.statusCode == 200) {
      final decodedResponse = utf8.decode(response.bodyBytes);
      final data = jsonDecode(decodedResponse);
      return data['choices'][0]['message']['content'].trim();
    } else {
      throw Exception('Failed to fetch AI response');
    }
  }

  Future<void> _saveMessagesToLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final key = 'chat_messages_${user.uid}';
    final jsonList = _messages.map((msg) => jsonEncode(msg)).toList();
    await prefs.setStringList(key, jsonList);
  }

  Future<void> _loadMessagesFromLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final key = 'chat_messages_${user.uid}';
    final jsonList = prefs.getStringList(key);
    if (jsonList != null) {
      setState(() {
        _messages.clear();
        _messages.addAll(
            jsonList.map((e) => Map<String, String>.from(jsonDecode(e))));
      });
    }
  }

  Future<void> _clearChatHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await prefs.remove('chat_messages_${user.uid}');
    setState(() {
      _messages.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Chat'),
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
        actions: [
          IconButton(
            icon: Icon(
              Icons.delete_outline,
              color: Theme.of(context).iconTheme.color,
            ),
            onPressed: () async {
              final isDark = Theme.of(context).brightness == Brightness.dark;
              final cancelColor = isDark
                  ? Theme.of(context).textTheme.bodyLarge?.color
                  : Colors.black;

              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                  title: const Text("Clear Chat History"),
                  content: const Text(
                      "Are you sure you want to delete all messages?"),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child:
                          Text("Cancel", style: TextStyle(color: cancelColor)),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text("Delete",
                          style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );

              if (confirmed == true) {
                await _clearChatHistory();
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                bool isUser = _messages[index]["sender"] == "user";
                return Align(
                  alignment:
                      isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 5),
                    padding: const EdgeInsets.all(12),
                    constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.7),
                    decoration: BoxDecoration(
                      color: isUser
                          ? (Theme.of(context).brightness == Brightness.dark
                              ? Colors.blueGrey.shade700
                              : Colors.blueAccent)
                          : Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 5,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      _messages[index]["message"]!,
                      style: TextStyle(
                        color: isUser
                            ? Colors.white
                            : Theme.of(context).textTheme.bodyMedium?.color,
                        fontSize: 16,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: CircularProgressIndicator(
                  color: Colors.blueAccent,
                ),
              ),
            ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 5,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    enabled:
                        hasInternet, // 🔒 csak akkor lehet gépelni, ha van net
                    decoration: InputDecoration(
                      hintText: hasInternet
                          ? "Type your message..."
                          : "Offline – AI Chat unavailable",
                      hintStyle: TextStyle(
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
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
                  decoration: const ShapeDecoration(
                    color: Colors.blueAccent,
                    shape: CircleBorder(),
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.send,
                      color: Theme.of(context).iconTheme.color,
                    ),
                    onPressed:
                        hasInternet ? _sendMessage : null, // 🔒 csak ha van net
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
