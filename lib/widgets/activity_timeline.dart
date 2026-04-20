import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AktiviteItem {
  final String baslik;
  final String aciklama;
  final IconData icon;
  final Color renk;
  final DateTime tarih;

  const AktiviteItem({
    required this.baslik,
    required this.aciklama,
    required this.icon,
    required this.renk,
    required this.tarih,
  });
}

class ActivityTimeline extends StatelessWidget {
  final List<AktiviteItem> aktiviteler;

  const ActivityTimeline({super.key, required this.aktiviteler});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF2A2A3C) : Colors.white;
    final textColor = isDark ? const Color(0xFFE0E0E0) : const Color(0xFF212121);
    final subTextColor = isDark ? const Color(0xFF9E9EA8) : const Color(0xFF757575);
    final lineColor = isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.withValues(alpha: 0.2);
    final formatter = DateFormat('dd MMM, HH:mm', 'tr');

    if (aktiviteler.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.inbox_rounded, size: 40, color: subTextColor),
              const SizedBox(height: 8),
              Text('Henüz aktivite yok', style: TextStyle(color: subTextColor, fontSize: 13)),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: aktiviteler.length,
        separatorBuilder: (_, __) => Divider(height: 1, color: lineColor, indent: 56),
        itemBuilder: (context, index) {
          final item = aktiviteler[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: item.renk.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(item.icon, color: item.renk, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.baslik,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.aciklama,
                        style: TextStyle(fontSize: 12, color: subTextColor),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  formatter.format(item.tarih),
                  style: TextStyle(fontSize: 11, color: subTextColor),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
