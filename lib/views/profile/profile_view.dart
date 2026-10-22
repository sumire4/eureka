import 'package:flutter/cupertino.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: CustomScrollView(
        slivers: [
          const CupertinoSliverNavigationBar(
            largeTitle: Text('Profil'),
          ),
          // Kullanıcı Kartı
          SliverToBoxAdapter(
            child: CupertinoListSection.insetGrouped(
              children: [
                CupertinoListTile(
                  leadingSize: 52,
                  leading: Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: CupertinoColors.systemGrey5,
                    ),
                    child: const Icon(
                      CupertinoIcons.person_crop_circle_fill,
                      size: 46,
                      color: CupertinoColors.systemGrey,
                    ),
                  ),
                  title: const Text('Mete', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                  subtitle: const Text('mete@example.com'),
                  trailing: const CupertinoListTileChevron(),
                  onTap: () {},
                ),
              ],
            ),
          ),
          // Tercihler Bölümü
          SliverToBoxAdapter(
            child: CupertinoListSection.insetGrouped(
              header: const Text('FAVORİLER'),
              children: [
                CupertinoListTile(
                  leading: const Icon(CupertinoIcons.flag_fill, color: Color(0xFFE10600)),
                  title: const Text('Favori Takım'),
                  additionalInfo: const Text('Ferrari'),
                  trailing: const CupertinoListTileChevron(),
                  onTap: () {},
                ),
                CupertinoListTile(
                  leading: const Icon(CupertinoIcons.person_2_fill, color: CupertinoColors.activeBlue),
                  title: const Text('Favori Pilot'),
                  additionalInfo: const Text('Charles Leclerc'),
                  trailing: const CupertinoListTileChevron(),
                  onTap: () {},
                ),
              ],
            ),
          ),
          // Uygulama Ayarları Bölümü
          SliverToBoxAdapter(
            child: CupertinoListSection.insetGrouped(
              header: const Text('UYGULAMA'),
              children: [
                CupertinoListTile(
                  leading: const Icon(CupertinoIcons.bell_fill, color: CupertinoColors.systemRed),
                  title: const Text('Bildirimler'),
                  trailing: CupertinoSwitch(
                    value: true,
                    onChanged: (val) {},
                    activeTrackColor: const Color(0xFFE10600),
                  ),
                ),
                CupertinoListTile(
                  leading: const Icon(CupertinoIcons.bookmark_fill, color: CupertinoColors.systemYellow),
                  title: const Text('Kaydedilen Haberler'),
                  trailing: const CupertinoListTileChevron(),
                  onTap: () {},
                ),
                CupertinoListTile(
                  leading: const Icon(CupertinoIcons.info_circle_fill, color: CupertinoColors.systemGrey),
                  title: const Text('Sürüm'),
                  additionalInfo: const Text('1.0.0 (Build 1)'),
                ),
              ],
            ),
          ),
          // Çıkış Yap
          SliverToBoxAdapter(
            child: CupertinoListSection.insetGrouped(
              children: [
                CupertinoListTile(
                  title: const Center(
                    child: Text(
                      'Çıkış Yap',
                      style: TextStyle(
                        color: CupertinoColors.destructiveRed,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  onTap: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}