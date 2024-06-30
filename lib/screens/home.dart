import 'dart:io';

import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:aub_ai/aub_ai.dart';
import 'package:aub_ai/prompt_template.dart';
import 'package:flutter/material.dart';
import 'package:llam_local/common/ai_constant.dart';
import 'package:path_provider/path_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController textControllerUserPrompt =
      TextEditingController();
  List<ChatMessage> messages = [];
  TalkAsyncState talkAsyncState = TalkAsyncState.idle;
  File? file;
  bool isAiTyping = false;

  void _setPath() async {
    Directory? externalDir = await getExternalStorageDirectory();
    String savePath = '${externalDir?.path}/tinyllam.gguf';
    file = File(savePath);
    setState(() {
      file = file;
    });
  }

  PromptTemplate promptTemplate = PromptTemplate.chatML().copyWith(
    contextSize: 2048,
  );

  late final String _promptTemplateDefaultPrompt;

  @override
  void initState() {
    super.initState();
    _promptTemplateDefaultPrompt = 'Ask me anything!';
    _setPath();
  }

  void _sendPromptToAi() async {
    if (file == null || textControllerUserPrompt.text.isEmpty) {
      return;
    }

    String userPrompt = textControllerUserPrompt.text.trim();

    setState(() {
      messages.insert(0, ChatMessage(message: userPrompt, isUser: true));
      isAiTyping = true;
      textControllerUserPrompt.clear();
    });

    promptTemplate = PromptTemplate.chatML().copyWith(
      prompt: userPrompt,
    );

    debugPrint('Prompt: ${promptTemplate.prompt}');

    StringBuffer aiResponse = StringBuffer();

    await talkAsync(
      filePathToModel: file!.path,
      promptTemplate: promptTemplate,
      onTokenGenerated: (String token) {
        setState(() {
          aiResponse.write(token);
        });
      },
    );

    String aiResponseStr = aiResponse.toString();
    int assistantIndex = aiResponseStr.indexOf("<|im_start|>assistant");
    if (assistantIndex != -1) {
      aiResponseStr = aiResponseStr.substring(assistantIndex + 21);
    }

    setState(() {
      messages.insert(0, ChatMessage(message: aiResponseStr, isUser: false));
      isAiTyping = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('TinyChat', style: TextStyle(fontWeight: FontWeight.bold)),
        automaticallyImplyLeading: false,
        actions: <Widget>[
          PopupMenuButton<String>(
            onSelected: (String result) {
              if (result == 'View Model') {
                Navigator.pushNamed(context, '/downloads');
              } else if (result == 'About') {
                Navigator.pushNamed(context, '/about');
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'View Model',
                child: Text('View Model'),
              ),
              const PopupMenuItem<String>(
                value: 'About',
                child: Text('About'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: messages.isEmpty
                ? Center(
                    child: Text(
                      'Start a conversation!',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    reverse: true,
                    itemCount: messages.length + (isAiTyping ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (isAiTyping && index == 0) {
                        return TypingIndicator();
                      }
                      final message = messages[isAiTyping ? index - 1 : index];
                      return ChatBubble(
                        message: message.message,
                        isUser: message.isUser,
                      );
                    },
                  ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: textControllerUserPrompt,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: _promptTemplateDefaultPrompt,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                    onSubmitted: (_) => _sendPromptToAi(),
                  ),
                ),
                SizedBox(width: 8.0),
                FloatingActionButton(
                  onPressed: _sendPromptToAi,
                  child: Icon(Icons.send),
                  mini: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ChatMessage {
  final String message;
  final bool isUser;

  ChatMessage({required this.message, required this.isUser});
}

class ChatBubble extends StatelessWidget {
  final String message;
  final bool isUser;

  const ChatBubble({Key? key, required this.message, this.isUser = true})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        decoration: BoxDecoration(
          color: isUser ? Theme.of(context).primaryColor : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          message,
          style: TextStyle(
            color: isUser ? Colors.white : Colors.black87,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}

class TypingIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(left: 16, bottom: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 8),
            AnimatedTextKit(
              animatedTexts: [
                TypewriterAnimatedText(
                  'AI is typing...',
                  textStyle: TextStyle(
                    fontSize: 16.0,
                    fontStyle: FontStyle.italic,
                  ),
                  speed: const Duration(milliseconds: 100),
                ),
              ],
              repeatForever: true, // Infinite repeat
              pause: const Duration(milliseconds: 1000),
              displayFullTextOnTap: false,
              stopPauseOnTap: false,
            ),
          ],
        ),
      ),
    );
  }
}
