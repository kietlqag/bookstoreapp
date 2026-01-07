import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../widgets/app_colors.dart';

class SettingsNotificationPage extends StatefulWidget {
  const SettingsNotificationPage({super.key});

  @override
  State<SettingsNotificationPage> createState() =>
      _SettingsNotificationPageState();
}

class _SettingsNotificationPageState extends State<SettingsNotificationPage> {
  bool _orderUpdates = true;
  bool _promotions = true;
  bool _newBooks = true;
  bool _priceDrops = true;
  bool _supportReplies = true;
  bool _sound = true;
  bool _vibration = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _orderUpdates = prefs.getBool('notif_order_updates') ?? true;
      _promotions = prefs.getBool('notif_promotions') ?? true;
      _newBooks = prefs.getBool('notif_new_books') ?? true;
      _priceDrops = prefs.getBool('notif_price_drops') ?? true;
      _supportReplies = prefs.getBool('notif_support_replies') ?? true;
      _sound = prefs.getBool('notif_sound') ?? true;
      _vibration = prefs.getBool('notif_vibration') ?? true;
    });
  }

  Future<void> _saveSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray50,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Cài đặt thông báo'),
        centerTitle: false,
        toolbarHeight: 44,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        titleTextStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.orange600, AppColors.rose500],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Loại thông báo
          _buildSectionHeader('Loại thông báo'),
          const SizedBox(height: 8),
          _buildSettingsCard([
            _buildSwitchTile(
              icon: Icons.local_shipping_outlined,
              title: 'Cập nhật đơn hàng',
              subtitle: 'Thông báo về trạng thái đơn hàng',
              value: _orderUpdates,
              onChanged: (v) {
                setState(() => _orderUpdates = v);
                _saveSetting('notif_order_updates', v);
              },
            ),
            _buildDivider(),
            _buildSwitchTile(
              icon: Icons.local_offer_outlined,
              title: 'Khuyến mãi',
              subtitle: 'Voucher và ưu đãi đặc biệt',
              value: _promotions,
              onChanged: (v) {
                setState(() => _promotions = v);
                _saveSetting('notif_promotions', v);
              },
            ),
            _buildDivider(),
            _buildSwitchTile(
              icon: Icons.menu_book_outlined,
              title: 'Sách mới',
              subtitle: 'Thông báo khi có sách mới',
              value: _newBooks,
              onChanged: (v) {
                setState(() => _newBooks = v);
                _saveSetting('notif_new_books', v);
              },
            ),
            _buildDivider(),
            _buildSwitchTile(
              icon: Icons.trending_down_outlined,
              title: 'Giảm giá',
              subtitle: 'Sách yêu thích được giảm giá',
              value: _priceDrops,
              onChanged: (v) {
                setState(() => _priceDrops = v);
                _saveSetting('notif_price_drops', v);
              },
            ),
            _buildDivider(),
            _buildSwitchTile(
              icon: Icons.support_agent_outlined,
              title: 'Phản hồi hỗ trợ',
              subtitle: 'Khi nhân viên trả lời yêu cầu',
              value: _supportReplies,
              onChanged: (v) {
                setState(() => _supportReplies = v);
                _saveSetting('notif_support_replies', v);
              },
            ),
          ]),
          const SizedBox(height: 24),

          // Cài đặt chung
          _buildSectionHeader('Cài đặt chung'),
          const SizedBox(height: 8),
          _buildSettingsCard([
            _buildSwitchTile(
              icon: Icons.volume_up_outlined,
              title: 'Âm thanh',
              subtitle: 'Phát âm thanh khi có thông báo',
              value: _sound,
              onChanged: (v) {
                setState(() => _sound = v);
                _saveSetting('notif_sound', v);
              },
            ),
            _buildDivider(),
            _buildSwitchTile(
              icon: Icons.vibration_outlined,
              title: 'Rung',
              subtitle: 'Rung khi có thông báo',
              value: _vibration,
              onChanged: (v) {
                setState(() => _vibration = v);
                _saveSetting('notif_vibration', v);
              },
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.gray700,
            ),
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.orange50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.orange600, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.gray500,
                      ),
                ),
              ],
            ),
          ),
          Transform.scale(
            scale: 0.8,
            child: Switch(
              value: value,
              onChanged: onChanged,
              activeColor: AppColors.orange600,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(height: 1, indent: 68);
  }
}
