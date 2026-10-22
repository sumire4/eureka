import 'package:flutter/cupertino.dart';
import '../../services/eureka_ai_service.dart';

class EurekaAiView extends StatefulWidget {
  const EurekaAiView({super.key});

  @override
  State<EurekaAiView> createState() => _EurekaAiViewState();
}

class _EurekaAiViewState extends State<EurekaAiView> {
  final EurekaAiService _aiService = EurekaAiService();
  late Future<RaceAiAnalysis> _analysisFuture;

  final TextEditingController _chatController = TextEditingController();
  final List<Map<String, String>> _messages = [
    {
      'role': 'assistant',
      'text': 'Merhaba! Ben Eureka F1 Asistanı. Sıradaki yarışın pist yapısı, hava durumu veya takım stratejileri hakkında bana dilediğini sorabilirsin.'
    }
  ];
  bool _isChatLoading = false;

  @override
  void initState() {
    super.initState();
    _analysisFuture = _aiService.fetchNextRaceAnalysis();
  }

  String _getCountryIso2(String code) {
    const Map<String, String> countryMap = {
      'ESP': 'es', 'ITA': 'it', 'GBR': 'gb', 'MON': 'mc',
      'NED': 'nl', 'BEL': 'be', 'AUT': 'at', 'HUN': 'hu',
      'USA': 'us', 'JPN': 'jp', 'SGP': 'sg', 'AZE': 'az',
      'QAT': 'qa', 'UAE': 'ae', 'BHR': 'bh', 'SAU': 'sa',
      'AUS': 'au', 'CAN': 'ca', 'BRA': 'br', 'MEX': 'mx',
    };
    return countryMap[code.toUpperCase()] ?? 'es';
  }

  void _sendMessage() async {
    final text = _chatController.text.trim();
    if (text.isEmpty || _isChatLoading) return;

    _chatController.clear();
    setState(() {
      _messages.add({'role': 'user', 'text': text});
      _isChatLoading = true;
    });

    final reply = await _aiService.askEurekaAssistant(
      question: text,
      chatHistory: _messages,
    );

    if (mounted) {
      setState(() {
        _messages.add({'role': 'assistant', 'text': reply});
        _isChatLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Eureka AI Analiz & Asistan'),
      ),
      child: SafeArea(
        child: FutureBuilder<RaceAiAnalysis>(
          future: _analysisFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CupertinoActivityIndicator(radius: 14));
            }

            final data = snapshot.data ?? RaceAiAnalysis.fallback();
            final countryIso = _getCountryIso2(data.countryCode);

            return ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 120),
              children: [
                const SizedBox(height: 12),

                // 1. BİR SONRAKİ YARIŞ BANNER KARTI (Bayrak + Tarih + Pist Kuşbakışı)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: CupertinoColors.secondarySystemGroupedBackground.resolveFrom(context),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFF8E2DE2).withValues(alpha: 0.35),
                        width: 1.3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: CupertinoColors.systemGrey.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Üst Etiket & Bayrak
                        // Üst Etiket & Bayrak (Taşma korumalı)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(CupertinoIcons.sparkles, size: 12, color: CupertinoColors.white),
                                  SizedBox(width: 4),
                                  Text(
                                    'SIRADAKİ GRAND PRIX',
                                    style: TextStyle(
                                      color: CupertinoColors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Bayrak PNG ve Tarih (Hata ve Taşma Korumalı)
                            Flexible(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(3),
                                    child: Image.network(
                                      'https://flagcdn.com/w40/${countryIso.toLowerCase().trim()}.png',
                                      width: 22,
                                      height: 15,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => const Icon(
                                        CupertinoIcons.flag_fill,
                                        size: 14,
                                        color: CupertinoColors.systemGrey,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      data.dateText,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: CupertinoColors.secondaryLabel,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // Yarış ve Pist Adı
                        Text(
                          data.raceName,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                        Text(
                          data.circuitName,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: CupertinoColors.secondaryLabel,
                          ),
                        ),

                        const SizedBox(height: 14),

                        // Pist Kuşbakışı Düzeni
                        Container(
                          width: double.infinity,
                          height: 130,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: CupertinoColors.systemGrey6.resolveFrom(context),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Image.network(
                            data.circuitImageUrl,
                            fit: BoxFit.contain,
                            errorBuilder: (_, _, _) => const Center(
                              child: Icon(CupertinoIcons.map, size: 40, color: CupertinoColors.systemGrey3),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // 2. BİR ÖNCEKİ YARIŞIN DEĞERLENDİRMESİ
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: CupertinoColors.secondarySystemGroupedBackground.resolveFrom(context),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: CupertinoColors.systemGrey5.resolveFrom(context)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(CupertinoIcons.clock_fill, size: 14, color: Color(0xFFE10600)),
                            SizedBox(width: 6),
                            Text(
                              'BİR ÖNCEKİ YARIŞTAN YANSIYANLAR',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: CupertinoColors.secondaryLabel,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          data.lastRaceSummary,
                          style: const TextStyle(
                            fontSize: 13,
                            height: 1.35,
                            color: CupertinoColors.label,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // 3. GEMINI AI TEKNİK TAHMİN KUTUCUKLARI (GRID)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'YAPAY ZEKA TAHMİN & DEĞERLENDİRMELERİ',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: CupertinoColors.secondaryLabel,
                          letterSpacing: 0.4,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Kutucuk 1: Hava & Asfalt
                      _buildAiBox(
                        title: 'HAVA & ASFALT DURUMU',
                        content: data.weatherTrack,
                        icon: CupertinoIcons.cloud_sun_rain_fill,
                        iconColor: const Color(0xFF00A8FF),
                      ),
                      const SizedBox(height: 8),

                      // Kutucuk 2: Takım Formu & Avantaj
                      _buildAiBox(
                        title: 'TAKIM FORMU & DÜZLÜK/VİRAJ FARKLARI',
                        content: data.teamForm,
                        icon: CupertinoIcons.car_detailed,
                        iconColor: const Color(0xFFFF8000),
                      ),
                      const SizedBox(height: 8),

                      // Kutucuk 3: Lastik & Pit Stratejisi
                      _buildAiBox(
                        title: 'PİRELLİ LASTİK & PİT STRATEJİSİ',
                        content: data.strategyTires,
                        icon: CupertinoIcons.circle_grid_hex_fill,
                        iconColor: const Color(0xFFD4AF37),
                      ),
                      const SizedBox(height: 8),

                      // Kutucuk 4: Podyum Tahmini
                      _buildAiBox(
                        title: 'YAPAY ZEKA PODYUM TAHMİNİ',
                        content: data.podiumPrediction,
                        icon: CupertinoIcons.rosette,
                        iconColor: const Color(0xFF8E2DE2),
                        isHighlight: true,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // 4. INTERAKTİF SOHBET BÖLÜMÜ (Eureka Asistan Chat Kutucuğu)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: CupertinoColors.secondarySystemGroupedBackground.resolveFrom(context),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: CupertinoColors.systemGrey5.resolveFrom(context)),
                    ),
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(5),
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
                                ),
                              ),
                              child: const Icon(CupertinoIcons.chat_bubble_2_fill, size: 14, color: CupertinoColors.white),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Yarış Hakkında Gemini ile Konuş',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Mesaj Balonları
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _messages.length,
                          itemBuilder: (context, idx) {
                            final m = _messages[idx];
                            final isUser = m['role'] == 'user';
                            return Align(
                              alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                              child: Container(
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                constraints: BoxConstraints(
                                  maxWidth: MediaQuery.of(context).size.width * 0.72,
                                ),
                                decoration: BoxDecoration(
                                  color: isUser
                                      ? const Color(0xFFE10600)
                                      : CupertinoColors.systemGrey6.resolveFrom(context),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Text(
                                  m['text'] ?? '',
                                  style: TextStyle(
                                    fontSize: 13,
                                    height: 1.3,
                                    color: isUser ? CupertinoColors.white : CupertinoColors.label,
                                    fontWeight: isUser ? FontWeight.w600 : FontWeight.normal,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),

                        if (_isChatLoading)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Row(
                              children: const [
                                CupertinoActivityIndicator(radius: 8),
                                SizedBox(width: 8),
                                Text(
                                  'Gemini düşünüyor...',
                                  style: TextStyle(fontSize: 12, color: CupertinoColors.secondaryLabel),
                                ),
                              ],
                            ),
                          ),

                        const SizedBox(height: 10),

                        // Soru Gönderme Input Kutusu
                        Row(
                          children: [
                            Expanded(
                              child: CupertinoTextField(
                                controller: _chatController,
                                placeholder: 'Yarış stratejisi, pilot formu sor...',
                                style: const TextStyle(fontSize: 13),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  color: CupertinoColors.systemGrey6.resolveFrom(context),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                onSubmitted: (_) => _sendMessage(),
                              ),
                            ),
                            const SizedBox(width: 8),
                            CupertinoButton(
                              padding: const EdgeInsets.all(10),
                              color: const Color(0xFF8E2DE2),
                              borderRadius: BorderRadius.circular(10),
                              onPressed: _sendMessage,
                              child: const Icon(
                                CupertinoIcons.arrow_up,
                                size: 18,
                                color: CupertinoColors.white,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildAiBox({
    required String title,
    required String content,
    required IconData icon,
    required Color iconColor,
    bool isHighlight = false,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: CupertinoColors.secondarySystemGroupedBackground.resolveFrom(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isHighlight
              ? iconColor.withValues(alpha: 0.5)
              : CupertinoColors.systemGrey5.resolveFrom(context),
          width: isHighlight ? 1.4 : 0.8,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 15, color: iconColor),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: isHighlight ? iconColor : CupertinoColors.secondaryLabel,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            content,
            style: TextStyle(
              fontSize: 13,
              height: 1.35,
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.w500,
              color: CupertinoColors.label.resolveFrom(context),
            ),
          ),
        ],
      ),
    );
  }
}