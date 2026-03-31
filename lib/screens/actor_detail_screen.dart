import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../api/api_constants.dart';
import '../api/api_service.dart';
import '../models/actor.dart';
import '../models/movie.dart';
import '../widgets/movie_list.dart';
import '../widgets/actor_detail_shimmer.dart';

class ActorDetailScreen extends StatefulWidget {
  final int actorId;
  const ActorDetailScreen({super.key, required this.actorId});

  @override
  State<ActorDetailScreen> createState() => _ActorDetailScreenState();
}

class _ActorDetailScreenState extends State<ActorDetailScreen> {
  late Future<Actor> _actorFuture;
  late Future<List<Movie>> _moviesFuture;
  final ApiService _apiService = ApiService();
  bool _isBiographyExpanded = false;

  @override
  void initState() {
    super.initState();
    _actorFuture = _apiService.getActorDetails(widget.actorId);
    _moviesFuture = _apiService.getActorMovies(widget.actorId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<Actor>(
        future: _actorFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const ActorDetailShimmer();
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData) {
            return const Center(child: Text('Actor not found'));
          }

          final actor = snapshot.data!;

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 400.0,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(actor.name, style: const TextStyle(fontSize: 16)),
                  background: actor.profilePath != null
                      ? CachedNetworkImage(
                          imageUrl:
                              '${ApiConstants.imageBaseUrl}${actor.profilePath}',
                          fit: BoxFit.cover,
                          placeholder: (context, url) =>
                              const Center(child: CircularProgressIndicator()),
                          errorWidget: (context, url, error) =>
                              const Icon(Icons.person, size: 100),
                        )
                      : Container(
                          color: Colors.grey.shade800,
                          child: const Center(
                              child: Icon(Icons.person,
                                  size: 100, color: Colors.white)),
                        ),
                ),
              ),
              SliverList(
                delegate: SliverChildListDelegate([
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (actor.birthday != null)
                          _buildInfoRow(
                            context,
                            icon: Icons.cake_outlined,
                            text: 'Born: ${_formatDate(actor.birthday)}',
                          ),
                        if (actor.placeOfBirth != null)
                          _buildInfoRow(
                            context,
                            icon: Icons.location_on_outlined,
                            text: 'From: ${actor.placeOfBirth!}',
                          ),
                        if (actor.biography != null &&
                            actor.biography!.isNotEmpty) ...[
                          Text('Biography',
                              style: Theme.of(context).textTheme.titleLarge),
                          const SizedBox(height: 8),
                          AnimatedSize(
                            duration: const Duration(milliseconds: 200),
                            child: Text(
                              actor.biography!,
                              style: Theme.of(context).textTheme.bodyMedium,
                              maxLines: _isBiographyExpanded ? null : 5,
                              overflow: TextOverflow.fade,
                            ),
                          ),
                          InkWell(
                            onTap: () {
                              setState(() {
                                _isBiographyExpanded = !_isBiographyExpanded;
                              });
                            },
                            child: Text(
                                _isBiographyExpanded
                                    ? 'Show Less'
                                    : 'Read More',
                                style: const TextStyle(
                                    color: Colors.blue,
                                    fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ],
                    ),
                  ),
                  _buildMoviesSection(),
                ]),
              ),
            ],
          );
        },
      ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) {
      return 'N/A';
    }
    try {
      final date = DateTime.parse(dateString);
      return DateFormat.yMMMMd().format(date); // e.g., January 1, 1990
    } catch (e) {
      return dateString; // Return original string if parsing fails
    }
  }

  Widget _buildInfoRow(BuildContext context,
      {required IconData icon, required String text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade400),
          const SizedBox(width: 8),
          Expanded(
              child: Text(text, style: Theme.of(context).textTheme.bodyMedium)),
        ],
      ),
    );
  }

  Widget _buildMoviesSection() {
    return FutureBuilder<List<Movie>>(
      future: _moviesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError ||
            !snapshot.hasData ||
            snapshot.data!.isEmpty) {
          return const SizedBox.shrink(); // Don't show anything if no movies
        }
        return MovieList(title: 'Known For', movies: snapshot.data!);
      },
    );
  }
}
