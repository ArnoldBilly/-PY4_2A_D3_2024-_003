import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'vision_controller.dart';
import 'damage_painter.dart';
import 'image_processing.dart';

class VisionView extends StatefulWidget {
  const VisionView({super.key});

  @override
  State<VisionView> createState() => _VisionViewState();
}

class _VisionViewState extends State<VisionView> {
  late VisionController _visionController;

  @override
  void initState() {
    super.initState();
    _visionController = VisionController();
    _visionController.startMockDetection();
  }

  @override
  void dispose() {
    _visionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Smart-Patrol Vision"),
        actions: [
          ListenableBuilder(
            listenable: _visionController, 
            builder: (context, _) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(
                      _visionController.isFlashlightOn ? Icons.flash_on : Icons.flash_off,
                    ),
                    onPressed: _visionController.toggleFlashlight,
                    tooltip: 'Toggle Flashlight',
                  ),
                  IconButton(
                    icon: Icon(
                      _visionController.isOverlayVisible ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: _visionController.toggleOverlay,
                    tooltip: 'Toggle Overlay',
                  ),
                ],
              );
            }
          )
        ],
      ),
      body: ListenableBuilder(
        listenable: _visionController,
        builder: (context, child) {
          if (!_visionController.isInitialized) {
            return _buildLoadingState();
          }
          return _buildVisionStack();
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final image = await _visionController.takePhoto();
          if (image != null && context.mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ImageProcessing(imagePath: image.path),
              ),
            );
          }
        },
        tooltip: 'Capture Photo',
        child: const Icon(Icons.camera),
      ),
    );
  }
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          const Text(
            "Menghubungkan ke Sensor Visual...",
            style: TextStyle(fontSize: 16),
          ),
          if (_visionController.errorMessage != null) ...[
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _visionController.errorMessage!,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => openAppSettings(),
              child: const Text("Open Settings"),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVisionStack() {
    return Stack(
      fit: StackFit.expand,
      children: [
        Center(
          child: AspectRatio(
            aspectRatio: 1/_visionController.controller!.value.aspectRatio,
            child: CameraPreview(_visionController.controller!),
          ),
        ),
        if (_visionController.isOverlayVisible)
          Positioned.fill(
            child: CustomPaint(
              painter: DamagePainter(
                _visionController.currentDetections,
              ),
            ),
          ),
      ],
    );
  }
}
