import 'package:flutter/material.dart';

class DrawerItem {
  final int index;
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const DrawerItem({
    required this.index,
    required this.icon,
    required this.title,
    required this.onTap,
  });
}

class DrawerItemsList extends StatelessWidget {
  final List<DrawerItem> items;
  final int selectedIndex;
  final bool isDark;
  final ColorScheme colorScheme;
  final bool isSidebar;

  const DrawerItemsList({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.isDark,
    required this.colorScheme,
    this.isSidebar = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: items.map((item) {
        final isSelected = selectedIndex == item.index;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: item.onTap,
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? colorScheme.primaryContainer
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? colorScheme.primary.withOpacity(0.3)
                        : Colors.transparent,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? colorScheme.primary.withOpacity(0.2)
                            : isDark
                            ? Colors.grey.shade800
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        item.icon,
                        color: isSelected
                            ? colorScheme.primary
                            : isDark
                            ? Colors.grey.shade400
                            : Colors.grey.shade700,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        item.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontFamily: 'Cairo',
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w500,
                          color: isSelected
                              ? colorScheme.primary
                              : isDark
                              ? Colors.grey.shade300
                              : Colors.grey.shade800,
                        ),
                      ),
                    ),
                    if (isSelected)
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 16,
                        color: colorScheme.primary,
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class DrawerHeaderWidget extends StatelessWidget {
  final bool isDark;
  final ColorScheme colorScheme;
  final String displayName;
  final String username;
  final VoidCallback? onHomeTap;

  const DrawerHeaderWidget({
    super.key,
    required this.isDark,
    required this.colorScheme,
    required this.displayName,
    required this.username,
    this.onHomeTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  colorScheme.primary.withOpacity(0.8),
                  colorScheme.primary,
                  colorScheme.secondary.withOpacity(0.9),
                ]
              : [
                  colorScheme.primary,
                  colorScheme.primary.withOpacity(0.9),
                  colorScheme.secondary.withOpacity(0.7),
                ],
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Hero(
            tag: 'user_avatar',
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 38,
                backgroundColor: isDark ? colorScheme.surface : Colors.white,
                child: CircleAvatar(
                  radius: 34,
                  backgroundColor: isDark
                      ? colorScheme.primaryContainer
                      : colorScheme.primary.withOpacity(0.1),
                  child: Text(
                    displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            displayName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                Icons.person_outline,
                size: 16,
                color: Colors.white.withOpacity(0.9),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  username,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                    letterSpacing: 0.3,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (onHomeTap != null)
                IconButton(
                  onPressed: onHomeTap,
                  icon: const Icon(Icons.home_rounded, color: Colors.white),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class DrawerLogoutSection extends StatelessWidget {
  final bool isDark;
  final ColorScheme colorScheme;
  final VoidCallback onLogout;

  const DrawerLogoutSection({
    super.key,
    required this.isDark,
    required this.colorScheme,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surface : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: isDark
            ? Border.all(color: Colors.grey.shade800, width: 1)
            : null,
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.grey.shade300,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onLogout,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.logout_rounded,
                    color: Colors.red.shade700,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'تسجيل الخروج',
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w600,
                    color: Colors.red.shade700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
