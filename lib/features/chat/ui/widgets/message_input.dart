import 'package:flutter/material.dart';

class MessageInput extends StatefulWidget {
  final Function(String) onSendMessage;
  final bool isLoading;

  const MessageInput({
    Key? key,
    required this.onSendMessage,
    required this.isLoading,
  }) : super(key: key);

  @override
  State<MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends State<MessageInput> {
  final _textController = TextEditingController();
  bool _canSend = false;

  @override
  void initState() {
    super.initState();
    _textController.addListener(() {
      setState(() {
        _canSend = _textController.text.trim().isNotEmpty;
      });
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    if (_canSend && !widget.isLoading) {
      widget.onSendMessage(_textController.text.trim());
      _textController.clear(); // Mesaj gönderildikten sonra alanı temizle
    }
  }


  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor, // Veya farklı bir arkaplan
        // border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              textInputAction: TextInputAction.send, // Klavye gönder butonu
              onSubmitted: (_) => _sendMessage(), // Enter ile gönderme
              decoration: InputDecoration(
                hintText: 'Bir soru sorun...',
                border: OutlineInputBorder(
                   borderRadius: BorderRadius.circular(25.0),
                   borderSide: BorderSide.none, // Kenarlıksız
                ),
                filled: true, // Arkaplan rengi için
                fillColor: Colors.grey.shade200, // Veya tema rengi
                contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
              ),
              minLines: 1,
              maxLines: 5, // Çok satırlı giriş için
              enabled: !widget.isLoading, // Yüklenirken devre dışı bırak
            ),
          ),
          SizedBox(width: 8.0),
          // Gönderme Butonu veya Yükleniyor Göstergesi
          widget.isLoading
              ? Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 3)),
                )
              : IconButton(
                  icon: Icon(Icons.send),
                  onPressed: _canSend ? _sendMessage : null, // Boşsa veya yükleniyorsa pasif
                  color: Theme.of(context).colorScheme.primary,
                  tooltip: 'Gönder',
                ),
        ],
      ),
    );
  }
} 