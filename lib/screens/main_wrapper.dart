import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/scroll_provider.dart';

class MainWrapper extends ConsumerStatefulWidget {
  final Widget child;
  const MainWrapper({super.key, required this.child});

  @override
  ConsumerState<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends ConsumerState<MainWrapper> {
  bool _isVisible = true;
  int _previousIndex = 0;
  late final ScrollController _scrollController;

  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/home')) {
      return 0;
    }
    if (location.startsWith('/search')) {
      return 1;
    }
    if (location.startsWith('/favorites')) {
      return 2;
    }
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    setState(() {
      // Lưu lại index cũ để xác định hướng trượt
      _previousIndex = _calculateSelectedIndex(context);
    });
    switch (index) {
      case 0:
        context.go('/home');
        break;
      case 1:
        context.go('/search');
        break;
      case 2:
        context.go('/favorites');
        break;
    }
  }

  @override
  void initState() {
    super.initState();
    // Chỉ lắng nghe scroll controller của màn hình Home
    _scrollController = ref.read(homeScreenScrollControllerProvider);
    _scrollController.addListener(_listen);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_listen);
    super.dispose();
  }

  void _listen() {
    final direction = _scrollController.position.userScrollDirection;
    if (direction == ScrollDirection.reverse && _isVisible) {
      setState(() => _isVisible = false);
    } else if (direction == ScrollDirection.forward && !_isVisible) {
      setState(() => _isVisible = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _calculateSelectedIndex(context);

    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        transitionBuilder: (child, animation) {
          // Xác định hướng trượt
          final isGoingForward = currentIndex > _previousIndex;
          final offset =
              isGoingForward ? const Offset(1.0, 0.0) : const Offset(-1.0, 0.0);

          return SlideTransition(
            position: Tween<Offset>(
              begin: offset,
              end: Offset.zero,
            ).animate(animation),
            child: child,
          );
        },
        child: widget.child,
      ),
      bottomNavigationBar: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: _isVisible ? kBottomNavigationBarHeight : 0.0,
        // Bọc BottomNav bằng ClipRRect và BackdropFilter
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(
                sigmaX: 6.0, sigmaY: 6.0), // 🔹 (c) Giảm opacity blur
            child: Wrap(
              children: [
                BottomNavigationBar(
                  // Theme đã xử lý màu sắc, không cần set ở đây
                  currentIndex: currentIndex,
                  onTap: (index) => _onItemTapped(index, context),
                  items: const [
                    BottomNavigationBarItem(
                        icon: Icon(Icons.home), label: 'Home'),
                    BottomNavigationBarItem(
                        icon: Icon(Icons.search), label: 'Search'),
                    BottomNavigationBarItem(
                        icon: Icon(Icons.favorite), label: 'Favorites'),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
