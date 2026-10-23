import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/theme_extensions.dart';
import '../../services/ai_service.dart';
import '../../services/database_service.dart';
import '../../widgets/bottom_navbar.dart';

class AIAssistantScreen extends StatefulWidget {
  const AIAssistantScreen({super.key});

  @override
  State<AIAssistantScreen> createState() => _AIAssistantScreenState();
}

class _AIAssistantScreenState extends State<AIAssistantScreen> {
  final AIService aiService = AIService();
  final TextEditingController controller = TextEditingController();
  final ScrollController scrollController = ScrollController();

  final List<Map<String, dynamic>> messages = [
    {
      "role": "ai",
      "text": "Hi! I'm your AI Finance Assistant. How can I help you today?",
      "time": DateFormat('hh:mm a').format(DateTime.now()),
    }
  ];

  bool isLoading = false;

  @override
  void dispose() {
    controller.dispose();
    scrollController.dispose();
    super.dispose();
  }

  Future<void> sendMessage([String? customText]) async {
    final textToSend = customText ?? controller.text.trim();
    if (textToSend.isEmpty) return;

    final now = DateFormat('hh:mm a').format(DateTime.now());

    setState(() {
      messages.add({
        "role": "user",
        "text": textToSend,
        "time": now,
      });
      isLoading = true;
    });

    if (customText == null) controller.clear();
    _scrollToBottom();

    try {
      final summary = await DatabaseService.instance.getFinancialSummary();
      final reply = await aiService.askAI(textToSend, summary);

      if (mounted) {
        setState(() {
          messages.add({
            "role": "ai",
            "text": reply,
            "time": DateFormat('hh:mm a').format(DateTime.now()),
          });
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          messages.add({
            "role": "ai",
            "text": "Sorry, I couldn't process that right now. Please try again.",
            "time": DateFormat('hh:mm a').format(DateTime.now()),
          });
        });
        _scrollToBottom();
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Widget _suggestionChip(String label, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        avatar: Icon(icon, size: 16, color: const Color(0xff7B4DFF)),
        label: Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xff7B4DFF).withValues(alpha: 0.12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        onPressed: () => sendMessage(label),
      ),
    );
  }

  Widget _chatBubble(String text, bool isUser, String time) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final aiBg = isDark ? const Color(0xff1B233A) : Colors.white;
    final userBg = const Color(0xff7B4DFF);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xff2A334D) : Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.smart_toy_rounded, color: Color(0xff7B4DFF), size: 18),
            ),
            const SizedBox(width: 10),
          ],
          Flexible(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.8,
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isUser ? userBg : aiBg,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(20),
                    topRight: const Radius.circular(20),
                    bottomLeft: Radius.circular(isUser ? 20 : 4),
                    bottomRight: Radius.circular(isUser ? 4 : 20),
                  ),
                  boxShadow: isDark || !isUser ? null : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _formatMessageContent(text, isUser, isDark),
                    const SizedBox(height: 6),
                    Text(
                      time,
                      style: TextStyle(
                        fontSize: 10,
                        color: isUser ? Colors.white70 : context.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 10),
        ],
      ),
    );
  }

  List<InlineSpan> _parseBold(String text, Color textColor) {
    final spans = <InlineSpan>[];
    final regex = RegExp(r'\*\*(.*?)\*\*');
    int lastEnd = 0;

    for (final match in regex.allMatches(text)) {
      if (match.start > lastEnd) {
        spans.add(TextSpan(text: text.substring(lastEnd, match.start)));
      }
      spans.add(TextSpan(
        text: match.group(1),
        style: TextStyle(fontWeight: FontWeight.bold, color: textColor, fontSize: 15, height: 1.5),
      ));
      lastEnd = match.end;
    }

    if (lastEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastEnd)));
    }

    return spans;
  }

  Widget _formatMessageContent(String content, bool isUser, bool isDark) {
    final textColor = isUser ? Colors.white : (isDark ? Colors.white.withOpacity(0.95) : Colors.black87);
    final lines = content.split('\n');
    final children = <Widget>[];

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) {
        children.add(const SizedBox(height: 10));
        continue;
      }

      if (trimmed.startsWith('•') || trimmed.startsWith('-')) {
        String bulletText = trimmed.substring(1).trim();
        children.add(
          Padding(
            padding: const EdgeInsets.only(left: 6, top: 4, bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
              children: [
                if (!isUser) ...[
                  Padding(
                    padding: const EdgeInsets.only(top: 7, right: 8),
                    child: Container(
                      width: 5,
                      height: 5,
                      decoration: const BoxDecoration(
                        color: Color(0xff7B4DFF),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
                Flexible(
                  child: RichText(
                    textAlign: isUser ? TextAlign.right : TextAlign.left,
                    text: TextSpan(
                      style: TextStyle(color: textColor, fontSize: 15, height: 1.5),
                      children: _parseBold(bulletText, textColor),
                    ),
                  ),
                ),
                if (isUser) ...[
                  Padding(
                    padding: const EdgeInsets.only(top: 7, left: 8),
                    child: Container(
                      width: 5,
                      height: 5,
                      decoration: const BoxDecoration(
                        color: Colors.white70,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      } else if (trimmed.endsWith(':')) {
        children.add(
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 4),
            child: Text(
              trimmed,
              textAlign: isUser ? TextAlign.right : TextAlign.left,
              style: TextStyle(
                color: textColor,
                fontSize: 15.5,
                height: 1.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        );
      } else {
        children.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: RichText(
              textAlign: isUser ? TextAlign.right : TextAlign.left,
              text: TextSpan(
                style: TextStyle(color: textColor, fontSize: 15, height: 1.5),
                children: _parseBold(trimmed, textColor),
              ),
            ),
          ),
        );
      }
    }

    return Column(
      crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: children,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xff070B16) : const Color(0xffF8FAFC);
    final cardColor = isDark ? const Color(0xff1B233A) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xff7B4DFF).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.psychology_rounded, color: Color(0xff7B4DFF), size: 24),
            ),
            const SizedBox(width: 10),
            Text(
              "AI Expense Assistant",
              style: TextStyle(color: textColor, fontSize: 17, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNavBar(currentRoute: '/ai'),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _suggestionChip("My Budget Status", Icons.account_balance_wallet_outlined),
                  _suggestionChip("Highest Expense Category", Icons.trending_up_rounded),
                  _suggestionChip("Total Spent this month", Icons.payments_outlined),
                  _suggestionChip("How to save money?", Icons.lightbulb_outline_rounded),
                ],
              ),
            ),
          ),
          Divider(height: 1, color: isDark ? Colors.white12 : Colors.grey.shade200),
          Expanded(
            child: ListView.builder(
              controller: scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];
                return _chatBubble(
                  message["text"]!,
                  message["role"] == "user",
                  message["time"] ?? "",
                );
              },
            ),
          ),
          if (isLoading)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: const Color(0xff7B4DFF),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    "Analyzing your finances...",
                    style: TextStyle(
                      color: context.textMuted,
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            color: bgColor,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    style: TextStyle(color: textColor, fontSize: 14),
                    minLines: 1,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: "Ask about your budget, expenses, or advice...",
                      hintStyle: TextStyle(color: context.textMuted, fontSize: 14),
                      filled: true,
                      fillColor: isDark ? const Color(0xff070B16) : Colors.grey.shade100,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (_) => sendMessage(),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: sendMessage,
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: const BoxDecoration(
                      color: Color(0xff7B4DFF),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
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
