import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'dart:math' as math;

class ImageProcessing extends StatefulWidget {
  final String imagePath;
  const ImageProcessing({super.key, required this.imagePath});

  @override
  State<ImageProcessing> createState() => _ImageProcessingState();
}

class _ImageProcessingState extends State<ImageProcessing> {
  Uint8List? _displayImage;
  bool _isProcessing = false;
  double brightnessValue = 0.0;

  @override
  void initState() {
    super.initState();
    _displayImage = File(widget.imagePath).readAsBytesSync();
  }

  Future<void> _applyEffect(img.Image Function(img.Image) filterFunc) async {
    setState(() => _isProcessing = true);
    final bytes = File(widget.imagePath).readAsBytesSync();
    img.Image? original = img.decodeImage(bytes);

    if (original != null) {
      img.Image processed = filterFunc(original);
      setState(() {
        _displayImage = Uint8List.fromList(img.encodeJpg(processed));
        _isProcessing = false;
      });
    }
  }

  void _showArithmeticDialog() {
    TextEditingController valController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Operasi Aritmatika"),
        content: TextField(
          controller: valController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(hintText: "Masukkan nilai (misal: 25)"),
        ),
        actions: [
          TextButton(onPressed: () => _runArithmetic(valController.text, true), child: const Text("Tambah (+)")),
          TextButton(onPressed: () => _runArithmetic(valController.text, false), child: const Text("Kurang (-)")),
        ],
      ),
    );
  }

  void _runArithmetic(String input, bool isAddition) {
    int constant = int.tryParse(input) ?? 0;
    int factor = isAddition ? constant : -constant; 
    Navigator.pop(context);

    _applyEffect((src) {
      for (var frame in src.frames) {
        for (var pixel in frame) {
          pixel.r = (pixel.r.toInt() + factor).clamp(0, 255);
          pixel.g = (pixel.g.toInt() + factor).clamp(0, 255);
          pixel.b = (pixel.b.toInt() + factor).clamp(0, 255);
        }
      }
      return src;
    });
  }

  void _showLogicDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Operasi Logika"),
        content: const Text("Pilih gambar kedua untuk dioperasikan dengan gambar saat ini."),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              TextButton(onPressed: () => _runLogicOp("AND"), child: const Text("AND")),
              TextButton(onPressed: () => _runLogicOp("OR"), child: const Text("OR")),
              TextButton(onPressed: () => _runLogicOp("XOR"), child: const Text("XOR")),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              TextButton(onPressed: () => _runLogicOp("MAX"), child: const Text("MAX")),
              TextButton(onPressed: () => _runLogicOp("MIN"), child: const Text("MIN")),
            ],
          )
        ],
      ),
    );
  }

  Future<void> _runLogicOp(String op) async {
    Navigator.pop(context);
    final picker = ImagePicker();
    final XFile? secondFile = await picker.pickImage(source: ImageSource.gallery);
    
    if (secondFile == null) return;

    _applyEffect((imgA) {
      Uint8List bytesB = File(secondFile.path).readAsBytesSync();
      img.Image? imgB = img.decodeImage(bytesB);
      imgB = img.copyResize(imgB!, width: imgA.width, height: imgA.height);
      for (int y = 0; y < imgA.height; y++) {
        for (int x = 0; x < imgA.width; x++) {
          var pA = imgA.getPixel(x, y);
          var pB = imgB.getPixel(x, y);

          if (op == "AND") {
            imgA.setPixelRgb(x, y, pA.r.toInt() & pB.r.toInt(), pA.g.toInt() & pB.g.toInt(), pA.b.toInt() & pB.b.toInt());
          } else if (op == "OR") {
            imgA.setPixelRgb(x, y, pA.r.toInt() | pB.r.toInt(), pA.g.toInt() | pB.g.toInt(), pA.b.toInt() | pB.b.toInt());
          } else if (op == "XOR") {
            imgA.setPixelRgb(x, y, pA.r.toInt() ^ pB.r.toInt(), pA.g.toInt() ^ pB.g.toInt(), pA.b.toInt() ^ pB.b.toInt());
          } else if (op == "MAX") {
            imgA.setPixelRgb(x, y, 
              math.max(pA.r.toInt(), pB.r.toInt()), 
              math.max(pA.g.toInt(), pB.g.toInt()), 
              math.max(pA.b.toInt(), pB.b.toInt())
            );
          } else if (op == "MIN") {
            imgA.setPixelRgb(x, y, 
              math.min(pA.r.toInt(), pB.r.toInt()), 
              math.min(pA.g.toInt(), pB.g.toInt()), 
              math.min(pA.b.toInt(), pB.b.toInt())
            );
          }
        }
      }
      return imgA;
    });
  }

  Future<void> _applyHistogramEqualization() async {
    _applyEffect((src) {
      img.Image gray = img.grayscale(src);
      int totalPixels = gray.width * gray.height;
      List<int> histogram = List.filled(256, 0);
      for (var frame in gray.frames) {
        for (var pixel in frame) {
          histogram[pixel.r.toInt()]++;
        }
      }
      List<int> cdf = List.filled(256, 0);
      cdf[0] = histogram[0];
      for (int i = 1; i < 256; i++) {
        cdf[i] = cdf[i - 1] + histogram[i];
      }
      int cdfMin = cdf.firstWhere((value) => value > 0);
      for (var frame in gray.frames) {
        for (var pixel in frame) {
          int v = pixel.r.toInt();
          // Normalisasi Histogram
          int newValue = (((cdf[v] - cdfMin) / (totalPixels - cdfMin)) * 255).round();
          
          pixel.r = newValue;
          pixel.g = newValue;
          pixel.b = newValue;
        }
      }
      return gray;
    });
  }

  Future<void> _applyHistogramSpecification() async {
    final picker = ImagePicker();
    final XFile? refFile = await picker.pickImage(source: ImageSource.gallery);
    if (refFile == null) return;

    setState(() => _isProcessing = true);

    _applyEffect((src) {
      img.Image imgA = img.grayscale(src);
      Uint8List bytesB = File(refFile.path).readAsBytesSync();
      img.Image? imgB = img.decodeImage(bytesB);
      if (imgB == null) return src;
      imgB = img.grayscale(imgB);
      List<double> calculateNormalizedCDF(img.Image image) {
        List<int> hist = List.filled(256, 0);
        for (var frame in image.frames) {
          for (var pixel in frame) {
            hist[pixel.r.toInt()]++;
          }
        }
        List<double> cdf = List.filled(256, 0.0);
        cdf[0] = hist[0].toDouble();
        for (int i = 1; i < 256; i++) {
          cdf[i] = cdf[i - 1] + hist[i];
        }
        int total = image.width * image.height;
        return cdf.map((v) => v / total).toList();
      }
      List<double> cdfA = calculateNormalizedCDF(imgA);
      List<double> cdfB = calculateNormalizedCDF(imgB);
      List<int> lut = List.filled(256, 0);
      for (int i = 0; i < 256; i++) {
        int bestJ = 0;
        double minDiff = (cdfA[i] - cdfB[0]).abs();
        for (int j = 1; j < 256; j++) {
          double diff = (cdfA[i] - cdfB[j]).abs();
          if (diff < minDiff) {
            minDiff = diff;
            bestJ = j;
          }
        }
        lut[i] = bestJ;
      }
      for (var frame in imgA.frames) {
        for (var pixel in frame) {
          int newValue = lut[pixel.r.toInt()];
          pixel.r = newValue;
          pixel.g = newValue;
          pixel.b = newValue;
        }
      }

      return imgA;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("DIP Editor"),
        actions: [
          IconButton(
            icon: const Icon(Icons.restore),
            onPressed: () => setState(() => _displayImage = File(widget.imagePath).readAsBytesSync()),
            tooltip: "Reset Gambar",
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: _isProcessing 
                ? const CircularProgressIndicator() 
                : _displayImage != null 
                    ? Image.memory(_displayImage!) 
                    : const Text("Gagal memuat gambar"),
            ),
          ),
          Container(
            height: 150,
            padding: const EdgeInsets.symmetric(vertical: 10),
            color: Colors.grey[200],
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildMenuTile("Grayscale", Icons.filter_b_and_w, () {
                  _applyEffect((src) => img.grayscale(src));
                }),
                _buildMenuTile("Biner", Icons.contrast, () {
                  _applyEffect((src) => img.luminanceThreshold(src, threshold: 0.5));
                }),
                _buildMenuTile("Brightness", Icons.light_mode, () {
                  showModalBottomSheet(
                    context: context,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    builder: (context) {
                      return StatefulBuilder(
                        builder: (BuildContext context, StateSetter setModalState) {
                          return Container(
                            padding: const EdgeInsets.all(20),
                            height: 180,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  "Brightness: ${(brightnessValue * 100).round()}%",
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Slider(
                                  value: brightnessValue,
                                  min: -1.0,
                                  max: 1.0,
                                  divisions: 10,
                                  onChanged: (val) {
                                    setModalState(() => brightnessValue = val);
                                  },
                                  onChangeEnd: (val) {
                                    _applyEffect((src) => img.adjustColor(src, brightness: val));
                                  },
                                ),
                                const Text(
                                  "Geser slider lalu lepas untuk melihat perubahan",
                                  style: TextStyle(fontSize: 10, color: Colors.grey),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  );
                }),
                _buildMenuTile("Contrast", Icons.contrast, () {
                  showModalBottomSheet(
                    context: context,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    builder: (context) {
                      return StatefulBuilder(
                        builder: (BuildContext context, StateSetter setModalState) {
                          return Container(
                            padding: const EdgeInsets.all(20),
                            height: 180,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  "Contrast: ${(brightnessValue * 100).round()}%",
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Slider(
                                  value: brightnessValue,
                                  min: -1.0,
                                  max: 1.0,
                                  divisions: 10,
                                  onChanged: (val) {
                                    setModalState(() => brightnessValue = val);
                                  },
                                  onChangeEnd: (val) {
                                    _applyEffect((src) => img.adjustColor(src, contrast: val));
                                  },
                                ),
                                const Text(
                                  "Geser slider lalu lepas untuk melihat perubahan",
                                  style: TextStyle(fontSize: 10, color: Colors.grey),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  );
                }),
                _buildMenuTile("Inverse", Icons.invert_colors, () {
                  _applyEffect((src) => img.invert(src));
                }),
                _buildMenuTile("Logic Ops", Icons.architecture, () {
                  _showLogicDialog();
                }),
                _buildMenuTile("Arithmetic Ops", Icons.calculate, () {
                  _showArithmeticDialog();
                }),
                _buildMenuTile("Histogram Eq", Icons.equalizer, () {
                  _applyHistogramEqualization();
                }),
                _buildMenuTile("Histogram Sp", Icons.analytics, () {
                  _applyHistogramSpecification();
                }),
                _buildMenuTile("Convolution", Icons.filter_center_focus, () {
                  _applyEffect((src) => img.convolution(src, filter: [0, 0, 0, 0, 1, 0, 0, 0, 0]));
                }),
                _buildMenuTile("Blurring", Icons.blur_on, () {
                  _applyEffect((src) => img.gaussianBlur(src, radius: 5));
                }),
                _buildMenuTile("Sharpening", Icons.details, () {
                  _applyEffect((src) => img.convolution(src, filter: [0, -1, 0, -1, 5, -1, 0, -1, 0]));
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuTile(String label, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.blue),
            const SizedBox(height: 5),
            Text(label, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}