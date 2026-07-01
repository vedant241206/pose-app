import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ModeCarousel extends StatefulWidget {
  final int selectedIndex;
  final ValueChanged<int> onModeChanged;

  static const List<String> modes = [
    'NIGHT',
    'PANO',
    'VIDEO',
    'CAM',
    'BEAUTY',
    'PORTRAIT',
    'PRO',
  ];

  const ModeCarousel({
    super.key,
    required this.selectedIndex,
    required this.onModeChanged,
  });

  @override
  State<ModeCarousel> createState() => _ModeCarouselState();
}

class _ModeCarouselState extends State<ModeCarousel> {
  late ScrollController _scrollController;
  static const double _itemWidth = 80;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToSelected();
    });
  }

  @override
  void didUpdateWidget(ModeCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndex != widget.selectedIndex) {
      _scrollToSelected();
    }
  }

  void _scrollToSelected() {
    if (!_scrollController.hasClients) return;
    final screenWidth = MediaQuery.of(context).size.width;
    final offset = (widget.selectedIndex * _itemWidth) - (screenWidth / 2) + (_itemWidth / 2);
    _scrollController.animateTo(
      offset.clamp(0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(
          horizontal: MediaQuery.of(context).size.width / 2 - _itemWidth / 2,
        ),
        itemCount: ModeCarousel.modes.length,
        itemBuilder: (context, index) {
          final isSelected = index == widget.selectedIndex;
          return GestureDetector(
            onTap: () => widget.onModeChanged(index),
            child: SizedBox(
              width: _itemWidth,
              child: Center(
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: TextStyle(
                    color: isSelected ? AppColors.accent : AppColors.whiteMed,
                    fontSize: isSelected ? 14 : 12,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                    letterSpacing: 1.2,
                  ),
                  child: Text(ModeCarousel.modes[index]),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
