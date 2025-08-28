import 'package:flutter/material.dart';
import 'package:time2go/theme/time2go_theme.dart';

class NavigationCard extends StatelessWidget {
  const NavigationCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Time2GoTheme.of(context).gridColor, width: 1),
      ),
      color: Time2GoTheme.of(context).backgroundColor,
      elevation: 0,
      child: ListTile(
        leading: Icon(icon, size: 32),
        title: Text(
          title,
          style: TextStyle(color: Time2GoTheme.of(context).foregroundColor),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: Time2GoTheme.of(context).foregroundColor.withAlpha(150),
          ),
        ),
        iconColor: Time2GoTheme.of(context).foregroundColor,
        onTap: onTap,
      ),
    );
  }
}
