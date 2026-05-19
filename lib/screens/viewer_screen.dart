import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:photo_view/photo_view.dart';
import 'package:provider/provider.dart';
import '../services/viewer_provider.dart';

class ViewerScreen extends StatefulWidget {
  const ViewerScreen({super.key});

  @override
  State<ViewerScreen> createState() => _ViewerScreenState();
}

class _ViewerScreenState extends State<ViewerScreen> {
  final PhotoViewControllerBase _photoController = PhotoViewController();
  bool _showControls = true;

  @override
  void dispose() {
    _photoController.dispose();
    super.dispose();
  }

  void _resetZoom() {
    (_photoController as PhotoViewController).reset();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ViewerProvider>(
      builder: (context, provider, _) {
        if (!provider.hasImages) {
          return const SizedBox.shrink();
        }

        return KeyboardListener(
          focusNode: FocusNode()..requestFocus(),
          autofocus: true,
          onKeyEvent: (event) {
            if (event is KeyDownEvent) {
              if (event.logicalKey == LogicalKeyboardKey.arrowRight ||
                  event.logicalKey == LogicalKeyboardKey.space) {
                provider.next();
                _resetZoom();
              } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
                provider.previous();
                _resetZoom();
              }
            }
          },
          child: Scaffold(
            backgroundColor: Colors.black,
            body: GestureDetector(
              onTap: () => setState(() => _showControls = !_showControls),
              child: Stack(
                children: [
                  // 메인 이미지 뷰어
                  _ImageView(
                    provider: provider,
                    photoController: _photoController as PhotoViewController,
                  ),

                  // 상단 바
                  if (_showControls)
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: _TopBar(provider: provider, onResetZoom: _resetZoom),
                    ),

                  // 하단 바
                  if (_showControls)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: _BottomBar(provider: provider, onResetZoom: _resetZoom),
                    ),

                  // 좌우 네비게이션 버튼
                  if (_showControls) ...[
                    Positioned(
                      left: 8,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: _NavButton(
                          icon: Icons.chevron_left,
                          onTap: () {
                            provider.previous();
                            _resetZoom();
                          },
                        ),
                      ),
                    ),
                    Positioned(
                      right: 8,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: _NavButton(
                          icon: Icons.chevron_right,
                          onTap: () {
                            provider.next();
                            _resetZoom();
                          },
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ImageView extends StatefulWidget {
  final ViewerProvider provider;
  final PhotoViewController photoController;

  const _ImageView({required this.provider, required this.photoController});

  @override
  State<_ImageView> createState() => _ImageViewState();
}

class _ImageViewState extends State<_ImageView> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: widget.provider.loadCurrentImageBytes(),
      key: ValueKey(widget.provider.currentIndex),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.white));
        }
        if (snapshot.hasError || snapshot.data == null) {
          return Center(
            child: Text('이미지를 불러올 수 없습니다\n${snapshot.error}',
                style: const TextStyle(color: Colors.white70), textAlign: TextAlign.center),
          );
        }

        final rotation = widget.provider.rotation * 3.14159265 / 180;

        return PhotoView(
          controller: widget.photoController,
          imageProvider: MemoryImage(snapshot.data!),
          minScale: PhotoViewComputedScale.contained * 0.5,
          maxScale: PhotoViewComputedScale.covered * 8.0,
          initialScale: PhotoViewComputedScale.contained,
          backgroundDecoration: const BoxDecoration(color: Colors.black),
          rotation: rotation,
        );
      },
    );
  }
}

class _TopBar extends StatelessWidget {
  final ViewerProvider provider;
  final VoidCallback onResetZoom;

  const _TopBar({required this.provider, required this.onResetZoom});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black87, Colors.transparent],
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                provider.currentImage?.name ?? '',
                style: const TextStyle(color: Colors.white, fontSize: 16),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              '${provider.currentIndex + 1} / ${provider.images.length}',
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  final ViewerProvider provider;
  final VoidCallback onResetZoom;

  const _BottomBar({required this.provider, required this.onResetZoom});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Colors.black87, Colors.transparent],
        ),
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _BarButton(
              icon: Icons.rotate_left,
              label: '왼쪽 회전',
              onTap: provider.rotateCounterClockwise,
            ),
            _BarButton(
              icon: Icons.rotate_right,
              label: '오른쪽 회전',
              onTap: provider.rotateClockwise,
            ),
            _BarButton(
              icon: Icons.fit_screen,
              label: '화면 맞춤',
              onTap: onResetZoom,
            ),
          ],
        ),
      ),
    );
  }
}

class _BarButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _BarButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _NavButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.black45,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Icon(icon, color: Colors.white, size: 32),
      ),
    );
  }
}
