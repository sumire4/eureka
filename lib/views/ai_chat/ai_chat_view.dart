import 'package:flutter/cupertino.dart';

class AiChatView extends StatefulWidget {
  const AiChatView({super.key});

  @override
  State<AiChatView> createState() => _AiChatViewState();
}

class _AiChatViewState extends State<AiChatView> {
  final TextEditingController _controller = TextEditingController();

  final List<Map<String, String>> _messages = [
    {
      'role': 'ai',
      'text': 'Merhaba! Ben Eureka F1 Asistanı. Pilotlar, yarış stratejileri veya kurallar hakkında bana dilediğini sorabilirsin.'
    },
    {
      'role': 'user',
      'text': 'Son yarışta Ferrari pit stratejisi neden eleştirildi?'
    },
    {
      'role': 'ai',
      'text': 'Ferrari, sert lastiklere erken geçerek undercut yapmayı hedefledi ancak arkadaki trafik hesaba katılmadığı için Sainz kritik 3 saniye kaybetti.'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Eureka Asistan'),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  final isUser = msg['role'] == 'user';

                  return Align(
                    alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.75,
                      ),
                      decoration: BoxDecoration(
                        color: isUser
                            ? const Color(0xFFE10600)
                            : CupertinoColors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(18),
                          topRight: const Radius.circular(18),
                          bottomLeft: Radius.circular(isUser ? 18 : 4),
                          bottomRight: Radius.circular(isUser ? 4 : 18),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: CupertinoColors.systemGrey.withOpacity(0.08),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        msg['text']!,
                        style: TextStyle(
                          color: isUser ? CupertinoColors.white : CupertinoColors.black,
                          fontSize: 15,
                          height: 1.3,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            // iOS Tarzı Alt Mesaj Giriş Barı
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              color: CupertinoColors.systemBackground,
              child: Row(
                children: [
                  Expanded(
                    child: CupertinoTextField(
                      controller: _controller,
                      placeholder: 'F1 hakkında bir şey sor...',
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: CupertinoColors.systemGrey6,
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () {},
                    child: const Icon(
                      CupertinoIcons.arrow_up_circle_fill,
                      size: 32,
                      color: Color(0xFFE10600),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}