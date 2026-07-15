import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class BackgroundVideoWidget extends StatefulWidget {
  final String? videoUrl;

  const BackgroundVideoWidget({super.key, this.videoUrl});

  @override
  State<BackgroundVideoWidget> createState() => _BackgroundVideoWidgetState();
}

class _BackgroundVideoWidgetState extends State<BackgroundVideoWidget> {
  VideoPlayerController? _controller;
  bool _videoError = false;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  @override
  void didUpdateWidget(covariant BackgroundVideoWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoUrl != widget.videoUrl) {
      _disposeVideo();
      _videoError = false;
      _initVideo();
    }
  }

  void _initVideo() {
    final url = widget.videoUrl;
    if (url == null || url.isEmpty) {
      _videoError = true;
      return;
    }

    try {
      if (url.startsWith('http://') || url.startsWith('https://')) {
        _controller = VideoPlayerController.networkUrl(Uri.parse(url));
      } else {
        _controller = VideoPlayerController.file(File(url));
      }
      _controller!.initialize().then((_) {
        if (mounted) {
          _controller!.setLooping(true);
          _controller!.play();
          setState(() => _videoError = false);
        }
      }).catchError((e) {
        if (mounted) {
          _disposeVideo();
          setState(() => _videoError = true);
        }
      });
    } catch (_) {
      _disposeVideo();
      _videoError = true;
    }
  }

  void _disposeVideo() {
    _controller?.dispose();
    _controller = null;
  }

  @override
  void dispose() {
    _disposeVideo();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller != null && _controller!.value.isInitialized && !_videoError) {
      return SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: _controller!.value.size.width,
            height: _controller!.value.size.height,
            child: VideoPlayer(_controller!),
          ),
        ),
      );
    }

    if (_videoError) {
      return const SizedBox.expand(child: ColoredBox(color: Colors.white));
    }

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFB00510),
            Color(0xFFE30613),
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _PatternPainter(),
            ),
          ),
          Container(
            color: Colors.black.withValues(alpha: 0.15),
          ),
        ],
      ),
    );
  }
}

class _PatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.03)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    const spacing = 60.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
