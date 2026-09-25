import 'package:flutter/material.dart';

class AnimatedNavItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;

  const AnimatedNavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });
}

class CoolCircularNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<AnimatedNavItem> items;
  final double horizontalMargin;
  final double horizontalPadding;

  const CoolCircularNavBar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.items,
    this.horizontalMargin = 16,
    this.horizontalPadding = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 88,
      margin: EdgeInsets.fromLTRB(horizontalMargin, 0, horizontalMargin, 24),
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFF18181B), // Dark Slate backdrop matching Vroom branding
        borderRadius: BorderRadius.circular(44),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double totalWidth = constraints.maxWidth;
          final double itemWidth = totalWidth / items.length;

          return Stack(
            children: [
              // Animated Yellow Circular Sliding Pill Indicator with Glow
              AnimatedPositioned(
                duration: const Duration(milliseconds: 350),
                curve: Curves.fastOutSlowIn,
                left: (selectedIndex * itemWidth) + (itemWidth - 62) / 2,
                top: 13,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.fastOutSlowIn,
                  width: 62,
                  height: 62,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFC700), // Signature Vroom Yellow
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFC700).withValues(alpha: 0.5),
                        blurRadius: 14,
                        spreadRadius: 2,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                ),
              ),

              // Navigation Buttons Row
              Row(
                children: List.generate(items.length, (index) {
                  final isSelected = selectedIndex == index;
                  final item = items[index];

                  return Expanded(
                    child: GestureDetector(
                      onTap: () => onDestinationSelected(index),
                      behavior: HitTestBehavior.opaque,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedScale(
                            scale: isSelected ? 1.2 : 1.0,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOutBack,
                            child: Icon(
                              isSelected ? item.selectedIcon : item.icon,
                              size: 24,
                              color: isSelected ? const Color(0xFF121214) : Colors.grey.shade400,
                            ),
                          ),
                          const SizedBox(height: 4),
                          AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 250),
                            style: TextStyle(
                              fontSize: isSelected ? 12 : 10,
                              fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                              color: isSelected ? const Color(0xFF121214) : Colors.grey.shade400,
                              letterSpacing: 0.5,
                            ),
                            child: Text(
                              item.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ],
          );
        },
      ),
    );
  }
}
