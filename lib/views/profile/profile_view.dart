import 'package:flutter/cupertino.dart';
import '../../widgets/ios27_switch.dart';
import '../../widgets/liquid_glass_list.dart';
import '../../widgets/ios_glass_dialog.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  bool _notificationsEnabled = true;

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          const CupertinoSliverNavigationBar(
            largeTitle: Text('Profil'),
          ),

          // 1. Kullanıcı Profil Kartı
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: IosGlassSection(
                children: [
                  CupertinoListTile(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                    leadingSize: 50,
                    leading: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFE10600).withValues(alpha: 0.12),
                        border: Border.all(
                          color: const Color(0xFFE10600).withValues(alpha: 0.35),
                          width: 1.5,
                        ),
                      ),
                      child: const Center(
                        child: Text(
                          'M',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFE10600),
                          ),
                        ),
                      ),
                    ),
                    title: const Text(
                      'Mete',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                        letterSpacing: -0.4,
                      ),
                    ),
                    subtitle: const Text(
                      'mete@example.com',
                      style: TextStyle(fontSize: 13, color: CupertinoColors.secondaryLabel),
                    ),
                    trailing: const CupertinoListTileChevron(),
                    onTap: () {},
                  ),
                ],
              ),
            ),
          ),

          // 2. Favoriler Bölümü
          SliverToBoxAdapter(
            child: IosGlassSection(
              header: 'Favoriler',
              children: [
                IosGlassTile(
                  icon: CupertinoIcons.flag_fill,
                  iconColor: const Color(0xFFE10600),
                  title: 'Favori Takım',
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text(
                        'Ferrari',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: CupertinoColors.secondaryLabel,
                        ),
                      ),
                      SizedBox(width: 6),
                      CupertinoListTileChevron(),
                    ],
                  ),
                  onTap: () {},
                ),
                IosGlassTile(
                  icon: CupertinoIcons.person_2_fill,
                  iconColor: CupertinoColors.activeBlue,
                  title: 'Favori Pilot',
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text(
                        'Charles Leclerc',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: CupertinoColors.secondaryLabel,
                        ),
                      ),
                      SizedBox(width: 6),
                      CupertinoListTileChevron(),
                    ],
                  ),
                  onTap: () {},
                ),
              ],
            ),
          ),

          // 3. Uygulama ve Bildirim Ayarları
          SliverToBoxAdapter(
            child: IosGlassSection(
              header: 'Uygulama',
              children: [
                IosGlassTile(
                  icon: CupertinoIcons.bell_fill,
                  iconColor: const Color(0xFFE10600),
                  title: 'Yarış Bildirimleri',
                  subtitle: 'Seans başlangıçları ve haberler',
                  trailing: Ios27Switch(
                    value: _notificationsEnabled,
                    activeColor: const Color(0xFFE10600), // veya Apple yeşili için parametreyi boş bırakabilirsiniz
                    onChanged: (val) {
                      setState(() => _notificationsEnabled = val);
                    },
                  ),
                ),
                IosGlassTile(
                  icon: CupertinoIcons.bell_fill,
                  iconColor: CupertinoColors.systemYellow,
                  title: 'Canlı Pist Olayları',
                  subtitle: 'Kırmızı bayrak ve güvenlik aracı',
                  trailing: Ios27Switch(
                    value: _notificationsEnabled,
                    activeColor: const Color(0xFFE10600), // veya Apple yeşili için parametreyi boş bırakabilirsiniz
                    onChanged: (val) {
                      setState(() => _notificationsEnabled = val);
                    },
                  ),
                ),
                IosGlassTile(
                  icon: CupertinoIcons.bookmark_fill,
                  iconColor: const Color(0xFF8E2DE2),
                  title: 'Kaydedilen Haberler',
                  trailing: const CupertinoListTileChevron(),
                  onTap: () {},
                ),
                IosGlassTile(
                  icon: CupertinoIcons.info_circle_fill,
                  iconColor: CupertinoColors.systemGrey,
                  title: 'Sürüm',
                  trailing: const Text(
                    '1.0.0 (Build 27)',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: CupertinoColors.secondaryLabel,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 4. Çıkış Yap Butonu (Liquid Glass Modal Onaylı)
          SliverToBoxAdapter(
            child: IosGlassSection(
              children: [
                CupertinoListTile(
                  padding: const EdgeInsets.symmetric(vertical: 14.0),
                  title: const Center(
                    child: Text(
                      'Çıkış Yap',
                      style: TextStyle(
                        color: CupertinoColors.destructiveRed,
                        fontWeight: FontWeight.w600,
                        fontSize: 16.0,
                      ),
                    ),
                  ),
                  onTap: () {
                    showIosGlassDialog(
                      context: context,
                      title: 'Çıkış Yapılsın mı?',
                      message: 'Hesabınızdan çıkış yapmak istediğinize emin misiniz?',
                      cancelText: 'Vazgeç',
                      confirmText: 'Çıkış Yap',
                      isDestructive: true,
                      onConfirm: () {
                        // Çıkış oturum temizleme mantığı
                      },
                    );
                  },
                ),
              ],
            ),
          ),

          // Alt Bar Boşluğu (Bottom Bar altında içerik ezilmesin)
          const SliverToBoxAdapter(
            child: SizedBox(height: 100),
          ),
        ],
      ),
    );
  }
}