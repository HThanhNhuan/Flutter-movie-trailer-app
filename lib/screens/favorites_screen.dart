import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/favorites_provider.dart';
import '../widgets/movie_card.dart';
import '../models/movie.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  // GlobalKey để điều khiển AnimatedGrid, được khai báo trong State
  final _gridKey = GlobalKey<AnimatedGridState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorite Movies'),
      ),
      body: Consumer<FavoritesProvider>(
        builder: (context, provider, child) {
          if (provider.favorites.isEmpty) {
            return const Center(
              child: Text('You have no favorite movies yet.'),
            );
          }
          return AnimatedGrid(
            key: _gridKey,
            padding: const EdgeInsets.all(8.0),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 2 / 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            initialItemCount: provider.favorites.length,
            itemBuilder: (context, index, animation) {
              final movie = provider.favorites[index];
              return _buildAnimatedItem(context, movie, animation, index);
            },
          );
        },
      ),
    );
  }

  // Widget để xây dựng từng item với hiệu ứng animation
  Widget _buildAnimatedItem(BuildContext context, Movie movie,
      Animation<double> animation, int index) {
    return FadeTransition(
      opacity: animation,
      child: ScaleTransition(
        scale: animation,
        child: MovieCard(
          movie: movie,
          onTap: () => context.push('/movie/${movie.id}', extra: movie),
          // Thêm một nút để xóa khỏi danh sách yêu thích ngay tại đây
          // Hoặc bạn có thể dùng LongPress, tùy vào thiết kế UX
          onRemove: () {
            // Lấy provider mà không lắng nghe thay đổi
            final provider =
                Provider.of<FavoritesProvider>(context, listen: false);
            // Xóa item khỏi AnimatedGrid
            _gridKey.currentState?.removeItem(
              index,
              (context, animation) =>
                  _buildAnimatedItem(context, movie, animation, index),
              duration: const Duration(milliseconds: 300),
            );
            // Xóa item khỏi provider
            provider.removeFavoriteAt(index);
          },
        ),
      ),
    );
  }
}
