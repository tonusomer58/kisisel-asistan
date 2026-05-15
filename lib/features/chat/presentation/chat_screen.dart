import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/ai_service.dart';
import '../../../core/services/database_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

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
          _scrollController.position.maxScrollExtent,
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yapay Zeka Asistan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            tooltip: 'Sohbeti Temizle',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: AppTheme.cardColor,
                  title: const Text('Sohbeti Sil', style: TextStyle(color: Colors.white)),
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
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _dbService.getChatsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppTheme.neonGreen));
                }

                final docs = snapshot.hasData ? snapshot.data!.docs : [];
                
                // Add listener to scroll to bottom when new messages arrive
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollController.hasClients && _scrollController.position.maxScrollExtent > 0) {
                     // We only scroll to bottom if we're not too far up, or just always for simplicity
                     _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
                  }
                });

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16.0),
                  itemCount: docs.length + (_isLoading ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == docs.length && _isLoading) {
                      return _buildLoadingIndicator();
                    }

                    final data = docs[index].data() as Map<String, dynamic>;
                    final isUser = data['isUser'] ?? false;
                    final text = data['text'] ?? '';
                    final isError = text.contains('ulaşılamıyor') || text.contains('Bağlantı hatası');
                    
                    final bubbleColor = isUser ? AppTheme.neonGreen : const Color(0xFF2D3748); 
                    final textColor = isUser ? AppTheme.background : (isError ? Colors.redAccent : Colors.white); 
                    
                    return Align(
                      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 16.0),
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.75,
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
                                color: AppTheme.neonGreen.withOpacity(0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              )
                          ],
                        ),
                        child: _buildMessageText(text, textColor),
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
              color: AppTheme.background,
              border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      style: const TextStyle(color: AppTheme.textMain),
                      decoration: InputDecoration(
                        hintText: 'Asistana bir mesaj yazın...',
                        hintStyle: const TextStyle(color: AppTheme.textMuted),
                        filled: true,
                        fillColor: AppTheme.cardColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide(color: AppTheme.neonGreen.withOpacity(0.5), width: 1),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide(color: AppTheme.neonGreen.withOpacity(0.3), width: 1),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: const BorderSide(color: AppTheme.neonGreen, width: 2),
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
                        color: _isLoading ? Colors.grey : AppTheme.neonGreen,
                        shape: BoxShape.circle,
                        boxShadow: [
                          if (!_isLoading)
                            BoxShadow(
                              color: AppTheme.neonGreen.withOpacity(0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            )
                        ],
                      ),
                      child: const Icon(Icons.send, color: AppTheme.background, size: 24),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16.0),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
        decoration: const BoxDecoration(
          color: Color(0xFF2D3748),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomRight: Radius.circular(16),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Asistan düşünüyor...',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
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
    List<TextSpan> spans = [];
    final parts = text.split('**');
    for (int i = 0; i < parts.length; i++) {
      final isBold = i % 2 == 1; // Tek sayılı indeksler (1, 3, 5) ** arasında kalan kısımlardır
      spans.add(TextSpan(
        text: parts[i],
        style: TextStyle(
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          color: textColor,
          fontSize: 15,
          height: 1.4,
        ),
      ));
    }
    return RichText(text: TextSpan(children: spans));
  }
}
