import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart' as yt;
import '../models/video.dart';

class VideoPlayerScreen extends StatefulWidget {
  final List<Video> videos;
  final int initialIndex;

  const VideoPlayerScreen(
      {super.key, required this.videos, required this.initialIndex});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  yt.YoutubePlayerController? _controller;
  late int _currentIndex;
  bool _showPlayNextOverlay = false;

  // For custom controls
  bool _areControlsVisible = true;
  bool _isPlayerReady = false;

  // For seek animation
  bool _showSeekIcon = false;
  bool _isSeekingForward = false;

  // For playback speed
  double _playbackRate = 1.0;
  final List<double> _playbackRates = [0.25, 0.5, 1.0, 1.5, 2.0];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _initializePlayer();

    // Thiết lập chế độ toàn màn hình và xoay ngang
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  Future<void> _initializePlayer() async {
    final prefs = await SharedPreferences.getInstance();
    final videoId = widget.videos[_currentIndex].key;
    // Lấy tiến trình đã lưu
    final savedPosition = prefs.getDouble('video_progress_$videoId') ?? 0.0;

    final controller = yt.YoutubePlayerController(
      initialVideoId: videoId,
      flags: yt.YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        forceHD: true,
        disableDragSeek: false,
        startAt: savedPosition.toInt(),
      ),
    )..addListener(_playerListener);

    if (mounted) {
      setState(() {
        _controller = controller;
      });
    }
  }

  void _playerListener() {
    if (!mounted || _controller == null) return;

    // Hiển thị nút "Play Next" khi video kết thúc
    if (_controller!.value.playerState == yt.PlayerState.ended) {
      // Chỉ hiển thị nếu đây không phải video cuối cùng
      if (_currentIndex < widget.videos.length - 1) {
        setState(() {
          _showPlayNextOverlay = true;
        });
      }
    } else {
      // Ẩn overlay nếu người dùng phát lại hoặc tua video
      if (_showPlayNextOverlay) {
        setState(() {
          _showPlayNextOverlay = false;
        });
      }
    }
  }

  Future<void> _playNextVideo() async {
    if (_currentIndex < widget.videos.length - 1) {
      // 1. Lưu tiến trình của video vừa xem xong
      await _saveVideoProgress();

      // 2. Chuyển sang video tiếp theo
      _currentIndex++;

      // 3. Lấy tiến trình đã lưu của video tiếp theo
      final prefs = await SharedPreferences.getInstance();
      final nextVideoId = widget.videos[_currentIndex].key;
      final savedPosition =
          prefs.getDouble('video_progress_$nextVideoId') ?? 0.0;

      // 4. Tải video tiếp theo và bắt đầu từ vị trí đã lưu
      _controller?.load(
        widget.videos[_currentIndex].key,
        startAt: savedPosition.toInt(),
      );

      // 5. Cập nhật UI
      setState(() {
        _showPlayNextOverlay = false;
      });
    }
  }

  Future<void> _saveVideoProgress() async {
    if (_controller != null && _controller!.value.isReady) {
      final prefs = await SharedPreferences.getInstance();
      final videoId = widget.videos[_currentIndex].key;
      final currentPosition = _controller!.value.position.inSeconds.toDouble();

      // Chỉ lưu nếu video đã xem được một đoạn đáng kể
      if (currentPosition > 5) {
        await prefs.setDouble('video_progress_$videoId', currentPosition);
      }
    }
  }

  void _handleDoubleTap(TapDownDetails details) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isForward = details.globalPosition.dx > screenWidth / 2;

    final currentPosition = _controller!.value.position;
    final newPosition = isForward
        ? currentPosition + const Duration(seconds: 10)
        : currentPosition - const Duration(seconds: 10);

    _controller!.seekTo(newPosition);

    // Show seek animation
    setState(() {
      _isSeekingForward = isForward;
      _showSeekIcon = true;
    });

    // Hide animation after a short duration
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _showSeekIcon = false;
        });
      }
    });
  }

  @override
  void dispose() {
    // Lưu tiến trình xem trước khi thoát
    _saveVideoProgress();

    _controller?.removeListener(_playerListener);
    _controller?.dispose();

    // Khôi phục lại chế độ giao diện và hướng màn hình mặc định khi thoát
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: SystemUiOverlay.values);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Giao diện toàn màn hình, đắm chìm
    // Không sử dụng Hero widget ở đây để tránh xung đột
    return Scaffold(
      backgroundColor: Colors.black,
      body: _controller == null
    ? const Center(child: CircularProgressIndicator(color: Colors.white))
    : SafeArea(
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: yt.YoutubePlayerBuilder(
              player: yt.YoutubePlayer(
                controller: _controller!,
                onReady: () {
                  if (mounted) setState(() => _isPlayerReady = true);
                },
              ),
              builder: (context, player) {
                return GestureDetector(
                  onTap: () {
                          if (!_isPlayerReady) return;
                          setState(
                              () => _areControlsVisible = !_areControlsVisible);
                        },
                  onDoubleTapDown: _handleDoubleTap,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      player, // Lớp dưới cùng là video
                      // Lớp phủ điều khiển
                      _buildCustomControls(context),
                      // Lớp phủ "Up Next"
                      if (_showPlayNextOverlay)
                        Builder(builder: (context) {
                          if (_currentIndex < widget.videos.length - 1) {
                            final nextVideo = widget.videos[_currentIndex + 1];
                            return Container(
                              color: Colors.black.withOpacity(0.7),
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text('Up Next',
                                        style: TextStyle(
                                            color: Colors.white, fontSize: 24)),
                                    const SizedBox(height: 10),
                                    Image.network(
                                        'https://img.youtube.com/vi/${nextVideo.key}/mqdefault.jpg',
                                        height: 90,
                                        fit: BoxFit.cover),
                                    const SizedBox(height: 10),
                                    Text(nextVideo.name,
                                        style: const TextStyle(
                                            color: Colors.white, fontSize: 16),
                                        textAlign: TextAlign.center),
                                    const SizedBox(height: 20),
                                    ElevatedButton.icon(
                                      onPressed: _playNextVideo,
                                      icon: const Icon(Icons.skip_next),
                                      label: const Text('Play Next Video'),
                                      style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        }),
                      // Lớp phủ tua video
                      _buildSeekAnimation(),
                    ],
                  ),
                );
              }),
          ),
        ),
    );
  }

  Widget _buildSeekAnimation() {
    return AnimatedOpacity(
      opacity: _showSeekIcon ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 200),
      child: Align(
        alignment:
            _isSeekingForward ? Alignment.centerRight : Alignment.centerLeft,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 50.0),
          child: Icon(
            _isSeekingForward ? Icons.forward_10 : Icons.replay_10,
            color: Colors.white,
            size: 50.0,
          ),
        ),
      ),
    );
  }

  Widget _buildCustomControls(BuildContext context) {
    return GestureDetector(
      child: Stack(
        children: [
          // A transparent container to make the whole area tappable
          Container(color: Colors.transparent),

          // The controls overlay
          AnimatedOpacity(
            opacity: _areControlsVisible ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300),
            child: IgnorePointer(
              ignoring: !_areControlsVisible,
              child: Container(
                color: Colors.black.withOpacity(0.3),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Top bar with Back Button and Title
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 8.0),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back,
                                color: Colors.white),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              widget.videos[_currentIndex].name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Spacer(),

                    // Center play/pause button
                    ValueListenableBuilder<yt.YoutubePlayerValue>(
                      valueListenable: _controller!,
                      builder: (context, value, child) {
                        return IconButton(
                          onPressed: () {
                            value.isPlaying
                                ? _controller!.pause()
                                : _controller!.play();
                          },
                          icon: Icon(
                            value.isPlaying
                                ? Icons.pause_circle_filled
                                : Icons.play_circle_filled,
                            color: Colors.white,
                            size: 64.0,
                          ),
                        );
                      },
                    ),

                    const Spacer(),

                    // Bottom control bar
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Row(
                        children: [
                          const yt.CurrentPosition(),
                          const SizedBox(width: 8),
                          Expanded(
                            child: yt.ProgressBar(
                              isExpanded: true,
                              colors: yt.ProgressBarColors(
                                playedColor: Colors.red,
                                handleColor: Colors.redAccent,
                                bufferedColor: Colors.grey.withOpacity(0.5),
                                backgroundColor: Colors.grey.withOpacity(0.2),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const yt.RemainingDuration(),
                          PopupMenuButton<double>(
                            icon: const Icon(Icons.speed, color: Colors.white),
                            initialValue: _playbackRate,
                            tooltip: 'Playback speed',
                            onSelected: (rate) {
                              _controller!.setPlaybackRate(rate);
                              setState(() => _playbackRate = rate);
                            },
                            itemBuilder: (context) => _playbackRates
                                .map((rate) => PopupMenuItem(
                                      value: rate,
                                      child: Text('${rate}x'),
                                    ))
                                .toList(),
                          ),
                          // Nút PiP và các nút khác được tích hợp sẵn trong thanh điều khiển mặc định
                          // của phiên bản 9.0.0. Chúng ta có thể thêm lại nếu cần tùy chỉnh sâu hơn.
                          // Hiện tại, chúng ta sẽ dựa vào các nút mặc định của trình phát.
                          const yt.FullScreenButton(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
