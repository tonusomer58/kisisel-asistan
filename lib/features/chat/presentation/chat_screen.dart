import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/ai_service.dart';
import '../../../core/services/database_service.dart';

class ChatScreen extends StatefulWidget {
  final bool isDarkMode;
  const ChatScreen({Key? key, this.isDarkMode = true}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GeminiService _aiService = GeminiService();
  final DatabaseService _dbService = DatabaseService();
  
  bool _isLoading = false;

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    
    _controller.clear();
    setState(() => _isLoading = true);
    
    // Save user message
    await _dbService.addChatMessage(text, true);
    _scrollToBottom();
    
    try {
      final transSnapshot = await _dbService.getTransactionsStream().first;
      final goalsSnapshot = await _dbService.getGoalsStream().first;
      final profile = await _dbService.getUserProfile();

      String contextString = "KULLANICI FİNANSAL VERİLERİ VE PROFİLİ (Bunu analiz için kullan, sadece sorulan soruya yanıt ver. Detayları dökme):\n";
      
      if (profile != null) {
        contextString += "İsim: ${profile['fullName'] ?? 'Bilinmiyor'}\n";
        contextString += "Hesap Tipi: ${profile['role'] == 'esnaf' ? 'Esnaf/KOBİ' : 'Bireysel'}\n\n";
      }

      contextString += "--- İŞLEMLER (GELİR/GİDER) ---\n";
      if (transSnapshot.docs.isEmpty) {
         contextString += "Hiç kayıt yok.\n";
      } else {
         for (var doc in transSnapshot.docs) {
           final data = doc.data() as Map<String, dynamic>;
           final typeText = data['type'] == 'income' ? 'Gelir' : 'Gider';
           contextString += "- ${data['title']}: ${data['amount']} TL ($typeText)\n";
         }
      }

      contextString += "\n--- BİRİKİM HEDEFLERİ ---\n";
      if (goalsSnapshot.docs.isEmpty) {
         contextString += "Hiç hedef yok.\n";
      } else {
         for (var doc in goalsSnapshot.docs) {
           final data = doc.data() as Map<String, dynamic>;
           contextString += "- ${data['name']}: Toplanan ${data['current']} TL / Hedef ${data['target']} TL\n";
         }
      }
      
      final promptWithContext = "$contextString\n\nKullanıcı Sorusu: $text";

      final response = await _aiService.sendMessage(promptWithContext);
      // Save AI message
      await _dbService.addChatMessage(response, false);
    } catch (e) {
      await _dbService.addChatMessage(e.toString().replaceAll('Exception: ', ''), false);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        _scrollToBottom();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.isDarkMode ? AppTheme.background : const Color(0xFFF0F4F8);
    final cardColor = widget.isDarkMode ? AppTheme.cardColor : const Color(0xFFFFFFFF);
    final textColor = widget.isDarkMode ? AppTheme.textMain : const Color(0xFF0F172A);
    final aiBubbleColor = widget.isDarkMode ? const Color(0xFF2D3748) : const Color(0xFFE8EDF2);
    final userBubbleColor = widget.isDarkMode ? AppTheme.neonGreen : const Color(0xFF2563EB);
    final userTextColor = widget.isDarkMode ? AppTheme.background : Colors.white;
    final primaryColor = widget.isDarkMode ? AppTheme.neonGreen : const Color(0xFF2563EB);

    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isSmallScreen = screenWidth < 900;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Column(
                children: [
                  Container(
                    height: 56,
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      children: [
                        if (isSmallScreen) ...[
                          const SizedBox(width: 52), // Space for floating hamburger icon at top left
                        ],
                        Expanded(
                          child: Text(
                            'FinAI Akıllı Asistan',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_sweep_outlined, color: Colors.redAccent),
                          tooltip: 'Sohbeti Temizle',
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                backgroundColor: cardColor,
                                title: Text('Sohbeti Sil', style: TextStyle(color: textColor)),
                                content: const Text('Tüm sohbet geçmişini silmek istediğinize emin misiniz?', style: TextStyle(color: AppTheme.textMuted)),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('İptal', style: TextStyle(color: AppTheme.textMuted))),
                                  TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Sil', style: TextStyle(color: Colors.redAccent))),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              await _dbService.clearChat();
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: Colors.white10),
            Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _dbService.getChatsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                  return Center(child: CircularProgressIndicator(color: primaryColor));
                }

                final docs = snapshot.hasData ? snapshot.data!.docs : [];

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.all(16.0),
                  itemCount: docs.length + (_isLoading ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (_isLoading && index == 0) {
                      return _buildLoadingIndicator();
                    }

                    final docIndex = _isLoading ? index - 1 : index;
                    final data = docs[docIndex].data() as Map<String, dynamic>;
                    final isUser = data['isUser'] ?? false;
                    final text = data['text'] ?? '';
                    final isError = text.contains('ulaşılamıyor') || text.contains('Bağlantı hatası');
                    
                    final bubbleColor = isUser ? userBubbleColor : aiBubbleColor; 
                    final messageTextColor = isUser ? userTextColor : (isError ? Colors.redAccent : textColor); 
                    
                    return Align(
                      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 16.0),
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width > 900
                              ? 650
                              : MediaQuery.of(context).size.width * 0.75,
                        ),
                        decoration: BoxDecoration(
                          color: bubbleColor,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(16),
                            topRight: const Radius.circular(16),
                            bottomLeft: Radius.circular(isUser ? 16 : 0),
                            bottomRight: Radius.circular(isUser ? 0 : 16),
                          ),
                          boxShadow: [
                            if (isUser)
                              BoxShadow(
                                color: userBubbleColor.withOpacity(0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              )
                          ],
                        ),
                        child: _buildMessageText(text, messageTextColor),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: bgColor,
              border: Border(top: BorderSide(color: widget.isDarkMode ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05))),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      style: TextStyle(color: textColor),
                      decoration: InputDecoration(
                        hintText: 'Asistana bir mesaj yazın...',
                        hintStyle: const TextStyle(color: AppTheme.textMuted),
                        filled: true,
                        fillColor: cardColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide(color: primaryColor.withOpacity(0.5), width: 1),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide(color: primaryColor.withOpacity(0.3), width: 1),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide(color: primaryColor, width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                      textInputAction: TextInputAction.send,
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: _isLoading ? null : _sendMessage,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _isLoading ? Colors.grey : primaryColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          if (!_isLoading)
                            BoxShadow(
                              color: primaryColor.withOpacity(0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            )
                        ],
                      ),
                      child: Icon(Icons.send, color: userTextColor, size: 24),
                    ),
                  ),
                ],
              ),
            ),
          ),
            ],
          ),
        ),
      ),
    ),
  ),
);
  }

  Widget _buildLoadingIndicator() {
    final aiBubbleColor = widget.isDarkMode ? const Color(0xFF2D3748) : const Color(0xFFE8EDF2);
    final textColor = widget.isDarkMode ? AppTheme.textMain : const Color(0xFF0F172A);
    final primaryColor = widget.isDarkMode ? AppTheme.neonGreen : const Color(0xFF2563EB);

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16.0),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
        decoration: BoxDecoration(
          color: aiBubbleColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomRight: Radius.circular(16),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Asistan düşünüyor...',
              style: TextStyle(
                color: textColor.withOpacity(0.7),
                fontSize: 14,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageText(String text, Color textColor) {
    final lines = text.split('\n');
    List<Widget> lineWidgets = [];

    for (int i = 0; i < lines.length; i++) {
      String line = lines[i];
      if (line.isEmpty) {
        // Empty lines add vertical spacing
        lineWidgets.add(const SizedBox(height: 8));
        continue;
      }
      
      // Check for headings
      bool isHeading = false;
      double fontSize = 15.0;
      FontWeight fontWeight = FontWeight.normal;
      EdgeInsets padding = const EdgeInsets.symmetric(vertical: 2.0);

      if (line.startsWith('### ')) {
        isHeading = true;
        line = line.substring(4);
        fontSize = 17.0;
        fontWeight = FontWeight.bold;
        padding = const EdgeInsets.only(top: 10.0, bottom: 4.0);
      } else if (line.startsWith('## ')) {
        isHeading = true;
        line = line.substring(3);
        fontSize = 19.0;
        fontWeight = FontWeight.bold;
        padding = const EdgeInsets.only(top: 12.0, bottom: 6.0);
      } else if (line.startsWith('# ')) {
        isHeading = true;
        line = line.substring(2);
        fontSize = 22.0;
        fontWeight = FontWeight.bold;
        padding = const EdgeInsets.only(top: 14.0, bottom: 8.0);
      }

      // Check for bullet lists
      bool isBullet = false;
      if (!isHeading && (line.startsWith('* ') || line.startsWith('- '))) {
        isBullet = true;
        line = line.substring(2);
        padding = const EdgeInsets.only(left: 12.0, top: 2.0, bottom: 2.0);
      }

      // Parse inline bolding **text**
      List<TextSpan> spans = [];
      final parts = line.split('**');
      for (int j = 0; j < parts.length; j++) {
        final isBold = j % 2 == 1;
        spans.add(TextSpan(
          text: parts[j],
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : (isHeading ? FontWeight.bold : FontWeight.normal),
            color: textColor,
            fontSize: fontSize,
            height: 1.4,
          ),
        ));
      }

      Widget lineWidget = RichText(
        text: TextSpan(
          children: [
            if (isBullet)
              TextSpan(
                text: '•  ',
                style: TextStyle(
                  color: textColor,
                  fontSize: fontSize,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ...spans,
          ],
        ),
      );

      if (padding != EdgeInsets.zero) {
        lineWidget = Padding(
          padding: padding,
          child: lineWidget,
        );
      }

      lineWidgets.add(lineWidget);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: lineWidgets,
    );
  }
}
