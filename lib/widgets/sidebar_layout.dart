import 'package:flutter/material.dart';

class SidebarItem {
  final String label;
  final IconData icon;
  final String key;
  final Color? color;

  const SidebarItem({
    required this.label,
    required this.icon,
    required this.key,
    this.color,
  });
}

class SidebarLayout extends StatefulWidget {
  final Widget body;
  final List<SidebarItem> items;
  final String selectedKey;
  final ValueChanged<String> onItemTap;
  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final Widget? header;

  const SidebarLayout({
    super.key,
    required this.body,
    required this.items,
    required this.selectedKey,
    required this.onItemTap,
    this.title = 'TexPilot',
    this.subtitle,
    this.actions,
    this.header,
  });

  @override
  State<SidebarLayout> createState() => _SidebarLayoutState();
}

class _SidebarLayoutState extends State<SidebarLayout> {
  bool _collapsed = false;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Mobilde sidebar gösterme
    if (screenWidth < 768) {
      return Scaffold(
        body: widget.body,
        bottomNavigationBar: _buildBottomNav(isDark),
      );
    }

    final sidebarWidth = _collapsed ? 72.0 : 240.0;
    final bgColor = isDark ? const Color(0xFF1E1E2E) : Colors.white;
    final borderColor = isDark ? Colors.white.withValues(alpha: 0.06) : Colors.grey.withValues(alpha: 0.12);

    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOutCubic,
            width: sidebarWidth,
            decoration: BoxDecoration(
              color: bgColor,
              border: Border(right: BorderSide(color: borderColor)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
                  blurRadius: 10,
                  offset: const Offset(2, 0),
                ),
              ],
            ),
            child: Column(
              children: [
                // Sidebar Header
                _buildSidebarHeader(isDark),
                const SizedBox(height: 8),
                // Menu Items
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    children: widget.items.map((item) => _buildSidebarTile(item, isDark)).toList(),
                  ),
                ),
                // Collapse Toggle
                _buildCollapseButton(isDark),
              ],
            ),
          ),
          // Body
          Expanded(child: widget.body),
        ],
      ),
    );
  }

  Widget _buildSidebarHeader(bool isDark) {
    final textColor = isDark ? const Color(0xFFE0E0E0) : const Color(0xFF212121);
    final subColor = isDark ? const Color(0xFF9E9EA8) : const Color(0xFF757575);

    return Container(
      padding: EdgeInsets.fromLTRB(_collapsed ? 12 : 16, 16, _collapsed ? 12 : 16, 12),
      child: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1976D2), Color(0xFF0D47A1)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.precision_manufacturing_rounded, color: Colors.white, size: 22),
                ),
                if (!_collapsed) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.title, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: textColor)),
                        if (widget.subtitle != null)
                          Text(
                            widget.subtitle!,
                            style: TextStyle(fontSize: 11, color: subColor),
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (widget.header != null && !_collapsed) ...[
            const SizedBox(height: 8),
            widget.header!,
          ],
        ],
      ),
    );
  }

  Widget _buildSidebarTile(SidebarItem item, bool isDark) {
    final isSelected = item.key == widget.selectedKey;
    final accentColor = item.color ?? const Color(0xFF1976D2);
    final textColor = isDark ? const Color(0xFFE0E0E0) : const Color(0xFF212121);
    final subColor = isDark ? const Color(0xFF9E9EA8) : const Color(0xFF757575);

    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: () => widget.onItemTap(item.key),
          borderRadius: BorderRadius.circular(10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.symmetric(
              horizontal: _collapsed ? 12 : 12,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? accentColor.withValues(alpha: isDark ? 0.15 : 0.08)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(
                  item.icon,
                  size: 20,
                  color: isSelected ? accentColor : subColor,
                ),
                if (!_collapsed) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item.label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isSelected ? accentColor : textColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCollapseButton(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(8),
      child: IconButton(
        icon: Icon(
          _collapsed ? Icons.chevron_right_rounded : Icons.chevron_left_rounded,
          color: isDark ? Colors.white54 : Colors.grey,
        ),
        onPressed: () => setState(() => _collapsed = !_collapsed),
        tooltip: _collapsed ? 'Genişlet' : 'Daralt',
      ),
    );
  }

  Widget _buildBottomNav(bool isDark) {
    // Mobilde en fazla 5 öğe göster
    final visibleItems = widget.items.take(5).toList();
    final selectedIdx = visibleItems.indexWhere((i) => i.key == widget.selectedKey);

    return NavigationBar(
      height: 60,
      selectedIndex: selectedIdx.clamp(0, visibleItems.length - 1),
      onDestinationSelected: (i) => widget.onItemTap(visibleItems[i].key),
      destinations: visibleItems.map((item) {
        return NavigationDestination(
          icon: Icon(item.icon, size: 22),
          selectedIcon: Icon(item.icon, size: 22, color: item.color ?? const Color(0xFF1976D2)),
          label: item.label,
        );
      }).toList(),
    );
  }
}
