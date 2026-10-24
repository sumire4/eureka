import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import '../../services/eureka_ai_service.dart';

class EurekaAiView extends StatefulWidget {
  const EurekaAiView({super.key});

  @override
  State<EurekaAiView> createState() => _EurekaAiViewState();
}

class _EurekaAiViewState extends State<EurekaAiView> {
  static const Color _purple = Color(0xFF8E2DE2);
  static const Color _indigo = Color(0xFF4A00E0);
  static const Color _f1Red = Color(0xFFE10600);

  final EurekaAiService _aiService = EurekaAiService();
  late Future<RaceAiAnalysis> _analysisFuture;

  final TextEditingController _chatController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<Map<String, String>> _messages = [
    {
      'role': 'assistant',
      'text':
      'Merhaba! Ben Eureka F1 Asistanı. Sıradaki yarışın pist yapısı, hava durumu veya takım stratejileri hakkında bana dilediğini sorabilirsin.'
    }
  ];
  bool _isChatLoading = false;

  static const List<_QuickQuestion> _quickQuestions = [
    _QuickQuestion(CupertinoIcons.cloud_rain_fill, 'Yağmur riski var mı?'),
    _QuickQuestion(CupertinoIcons.circle_grid_hex_fill, 'Hangi lastik stratejisi?'),
    _QuickQuestion(CupertinoIcons.rosette, 'Pole kimden gelir?'),
    _QuickQuestion(CupertinoIcons.flag_fill, 'Pistte en kritik viraj?'),
  ];

  @override
  void initState() {
    super.initState();
    _analysisFuture = _aiService.fetchNextRaceAnalysis();
  }

  @override
  void dispose() {
    _chatController.dispose();
    _scrollController.dispose();
    super.dispose();
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

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    });
  }

  Future<void> _sendMessage([String? preset]) async {
    final text = (preset ?? _chatController.text).trim();
    if (text.isEmpty || _isChatLoading) return;

    HapticFeedback.selectionClick();
    _chatController.clear();
    setState(() {
      _messages.add({'role': 'user', 'text': text});
      _isChatLoading = true;
    });
    _scrollToBottom();

    final reply = await _aiService.askEurekaAssistant(
      question: text,
      chatHistory: _messages,
    );

    if (mounted) {
      HapticFeedback.lightImpact();
      setState(() {
        _messages.add({'role': 'assistant', 'text': reply});
        _isChatLoading = false;
      });
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      child: FutureBuilder<RaceAiAnalysis>(
        future: _analysisFuture,
        builder: (context, snapshot) {
          final loading = snapshot.connectionState == ConnectionState.waiting;
          final data = snapshot.data ?? RaceAiAnalysis.fallback();

          return CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            slivers: [
              const CupertinoSliverNavigationBar(
                largeTitle: Text('Eureka AI'),
                border: null,
                backgroundColor: Color(0x00000000),
              ),
              if (loading)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: _LoadingState(),
                )
              else
                SliverList(
                  delegate: SliverChildListDelegate([
                    _buildHero(data),
                    const SizedBox(height: 18),
                    _buildLastRace(data),
                    const SizedBox(height: 24),
                    _buildInsights(data),
                    const SizedBox(height: 24),
                    _buildChat(),
                    const SizedBox(height: 120),
                  ]),
                ),
            ],
          );
        },
      ),
    );
  }

  // ───────────────────────── HERO ─────────────────────────
  Widget _buildHero(RaceAiAnalysis data) {
    final iso = _getCountryIso2(data.countryCode).toLowerCase().trim();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1B1035), Color(0xFF3A0CA3), _purple],
          ),
          boxShadow: [
            BoxShadow(
              color: _purple.withValues(alpha: 0.35),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Stack(
            children: [
              // Dekoratif parlama
              Positioned(
                right: -50,
                top: -50,
                child: Container(
                  width: 170,
                  height: 170,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: CupertinoColors.white.withValues(alpha: 0.08),
                  ),
                ),
              ),
              Positioned(
                left: -40,
                bottom: -60,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _f1Red.withValues(alpha: 0.18),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _GlassPill(
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(CupertinoIcons.sparkles,
                                  size: 12, color: CupertinoColors.white),
                              SizedBox(width: 4),
                              Text(
                                'SIRADAKİ GP',
                                style: TextStyle(
                                  color: CupertinoColors.white,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        Flexible(
                          child: _GlassPill(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(3),
                                  child: Image.network(
                                    'https://flagcdn.com/w40/$iso.png',
                                    width: 20,
                                    height: 14,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) => const Icon(
                                      CupertinoIcons.flag_fill,
                                      size: 13,
                                      color: CupertinoColors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    data.dateText,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: CupertinoColors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Text(
                      data.raceName,
                      style: const TextStyle(
                        color: CupertinoColors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.6,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(CupertinoIcons.location_solid,
                            size: 13,
                            color: CupertinoColors.white.withValues(alpha: 0.7)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            data.circuitName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: CupertinoColors.white.withValues(alpha: 0.75),
                              fontSize: 13.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      height: 140,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: CupertinoColors.white.withValues(alpha: 0.93),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Image.network(
                        data.circuitImageUrl,
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => const Center(
                          child: Icon(CupertinoIcons.map,
                              size: 40, color: CupertinoColors.systemGrey3),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ───────────────────────── SON YARIŞ ─────────────────────────
  Widget _buildLastRace(RaceAiAnalysis data) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: _Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const _IconTile(
                  icon: CupertinoIcons.clock_fill,
                  colors: [Color(0xFFFF453A), _f1Red],
                  size: 30,
                ),
                const SizedBox(width: 10),
                Text(
                  'Bir Önceki Yarıştan Yansıyanlar',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: CupertinoColors.label.resolveFrom(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              data.lastRaceSummary,
              style: TextStyle(
                fontSize: 13.5,
                height: 1.45,
                color: CupertinoColors.label.resolveFrom(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ───────────────────────── AI KUTULARI ─────────────────────────
  Widget _buildInsights(RaceAiAnalysis data) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            icon: CupertinoIcons.sparkles,
            title: 'Yapay Zeka Tahminleri',
          ),
          const SizedBox(height: 12),
          _InsightCard(
            title: 'Hava & Asfalt',
            content: data.weatherTrack,
            icon: CupertinoIcons.cloud_sun_rain_fill,
            colors: const [Color(0xFF4FC3F7), Color(0xFF0A84FF)],
          ),
          const SizedBox(height: 10),
          _InsightCard(
            title: 'Takım Formu & Düzlük/Viraj Farkları',
            content: data.teamForm,
            icon: CupertinoIcons.car_detailed,
            colors: const [Color(0xFFFFB347), Color(0xFFFF6A00)],
          ),
          const SizedBox(height: 10),
          _InsightCard(
            title: 'Pirelli Lastik & Pit Stratejisi',
            content: data.strategyTires,
            icon: CupertinoIcons.circle_grid_hex_fill,
            colors: const [Color(0xFFFFE259), Color(0xFFD4AF37)],
          ),
          const SizedBox(height: 10),
          _InsightCard(
            title: 'Yapay Zeka Podyum Tahmini',
            content: data.podiumPrediction,
            icon: CupertinoIcons.rosette,
            colors: const [_purple, _indigo],
            highlight: true,
          ),
        ],
      ),
    );
  }

  // ───────────────────────── SOHBET ─────────────────────────
  Widget _buildChat() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: _Card(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Başlık
            Container(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: CupertinoColors.separator.resolveFrom(context),
                    width: 0.5,
                  ),
                ),
              ),
              child: Row(
                children: [
                  const _IconTile(
                    icon: CupertinoIcons.chat_bubble_2_fill,
                    colors: [_purple, _indigo],
                    size: 36,
                    circle: true,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Eureka Asistan',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: CupertinoColors.label.resolveFrom(context),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: const BoxDecoration(
                                color: CupertinoColors.systemGreen,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              'Gemini ile çevrimiçi',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: CupertinoColors.secondaryLabel
                                    .resolveFrom(context),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Mesajlar
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
              child: ListView.builder(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _messages.length,
                itemBuilder: (context, idx) {
                  final m = _messages[idx];
                  return _ChatBubble(
                    text: m['text'] ?? '',
                    isUser: m['role'] == 'user',
                  );
                },
              ),
            ),

            if (_isChatLoading)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
                child: Row(
                  children: [
                    const _AssistantAvatar(),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: CupertinoColors.systemGrey6.resolveFrom(context),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CupertinoActivityIndicator(radius: 8),
                          const SizedBox(width: 8),
                          Text(
                            'Gemini düşünüyor...',
                            style: TextStyle(
                              fontSize: 12,
                              color: CupertinoColors.secondaryLabel
                                  .resolveFrom(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 12),

            // Hızlı sorular
            SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: _quickQuestions.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final q = _quickQuestions[i];
                  return CupertinoButton(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    onPressed: () => _sendMessage(q.text),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _purple.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: _purple.withValues(alpha: 0.30),
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(q.icon, size: 13, color: _purple),
                          const SizedBox(width: 6),
                          Text(
                            q.text,
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: _purple,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Input
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: CupertinoTextField(
                      controller: _chatController,
                      placeholder: 'Yarış stratejisi, pilot formu sor...',
                      style: const TextStyle(fontSize: 14),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 11),
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      decoration: BoxDecoration(
                        color: CupertinoColors.systemGrey6.resolveFrom(context),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _sendMessage,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [_purple, _indigo],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _purple.withValues(alpha: 0.4),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        CupertinoIcons.arrow_up,
                        size: 20,
                        color: CupertinoColors.white,
                      ),
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

// ═════════════════════ YARDIMCI WIDGET'LAR ═════════════════════

class _QuickQuestion {
  final IconData icon;
  final String text;
  const _QuickQuestion(this.icon, this.text);
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const _IconTile(
          icon: CupertinoIcons.sparkles,
          colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
          size: 64,
          circle: true,
        ),
        const SizedBox(height: 20),
        const CupertinoActivityIndicator(radius: 12),
        const SizedBox(height: 14),
        Text(
          'Yapay zeka yarışı analiz ediyor...',
          style: TextStyle(
            fontSize: 14,
            color: CupertinoColors.secondaryLabel.resolveFrom(context),
          ),
        ),
        const SizedBox(height: 80),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  const _Card({required this.child, this.padding = const EdgeInsets.all(16)});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: CupertinoColors.secondarySystemGroupedBackground
            .resolveFrom(context),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _GlassPill extends StatelessWidget {
  final Widget child;
  const _GlassPill({required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: CupertinoColors.white.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: CupertinoColors.white.withValues(alpha: 0.25),
              width: 0.8,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// iOS "Ayarlar" tarzı gradient ikon karosu
class _IconTile extends StatelessWidget {
  final IconData icon;
  final List<Color> colors;
  final double size;
  final bool circle;

  const _IconTile({
    required this.icon,
    required this.colors,
    this.size = 34,
    this.circle = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: circle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: circle ? null : BorderRadius.circular(size * 0.29),
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: colors.last.withValues(alpha: 0.35),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Icon(icon, size: size * 0.52, color: CupertinoColors.white),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  const _SectionHeader({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF8E2DE2)),
        const SizedBox(width: 6),
        Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
            color: CupertinoColors.label.resolveFrom(context),
          ),
        ),
      ],
    );
  }
}

class _InsightCard extends StatelessWidget {
  final String title;
  final String content;
  final IconData icon;
  final List<Color> colors;
  final bool highlight;

  const _InsightCard({
    required this.title,
    required this.content,
    required this.icon,
    required this.colors,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: CupertinoColors.secondarySystemGroupedBackground
            .resolveFrom(context),
        border: highlight
            ? Border.all(color: colors.first.withValues(alpha: 0.55), width: 1.4)
            : null,
        boxShadow: [
          BoxShadow(
            color: highlight
                ? colors.first.withValues(alpha: 0.22)
                : CupertinoColors.black.withValues(alpha: 0.04),
            blurRadius: highlight ? 18 : 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _IconTile(icon: icon, colors: colors, size: 38),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                    color: highlight
                        ? colors.first
                        : CupertinoColors.secondaryLabel.resolveFrom(context),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  content,
                  style: TextStyle(
                    fontSize: 13.5,
                    height: 1.4,
                    fontWeight: highlight ? FontWeight.w700 : FontWeight.w500,
                    color: CupertinoColors.label.resolveFrom(context),
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

class _AssistantAvatar extends StatelessWidget {
  const _AssistantAvatar();

  @override
  Widget build(BuildContext context) {
    return const _IconTile(
      icon: CupertinoIcons.sparkles,
      colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
      size: 28,
      circle: true,
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final String text;
  final bool isUser;
  const _ChatBubble({required this.text, required this.isUser});

  @override
  Widget build(BuildContext context) {
    final maxW = MediaQuery.of(context).size.width * 0.68;

    final bubble = Container(
      constraints: BoxConstraints(maxWidth: maxW),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: isUser
            ? const LinearGradient(
          colors: [Color(0xFFFF3B30), Color(0xFFE10600)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        )
            : null,
        color: isUser ? null : CupertinoColors.systemGrey6.resolveFrom(context),
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(18),
          topRight: const Radius.circular(18),
          bottomLeft: Radius.circular(isUser ? 18 : 5),
          bottomRight: Radius.circular(isUser ? 5 : 18),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13.5,
          height: 1.35,
          color: isUser ? CupertinoColors.white : CupertinoColors.label.resolveFrom(context),
          fontWeight: isUser ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment:
        isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            const _AssistantAvatar(),
            const SizedBox(width: 8),
          ],
          bubble,
        ],
      ),
    );
  }
}