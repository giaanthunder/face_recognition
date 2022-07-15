// ignore_for_file: non_constant_identifier_names

import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:ffi/ffi.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as imglib;
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

import 'package:face_recognition/common_lib.dart';

List<BBox> forward(List<Object> args) {
  FaceDetector detector = args[0] as FaceDetector;
  CameraImage image = args[1] as CameraImage;

  // var stopwatch = Stopwatch()..start();
  // var img = convertYUVtoRGB(image);
  // print('Dart convert time: ${stopwatch.elapsed}');
  // stopwatch.reset();
  // var img2 = convertYUVtoRGB2(image);
  // print('C++ convert time: ${stopwatch.elapsed}');

  CFloatArray img = convertYUVtoRGB(image);
  List<BBox> bb = detector.forward(img);
  malloc.free(img.data);
  return bb;
}

class FaceDetector {
  late int detector;
  late List<String> labels;

  FaceDetector() {
    List<String> fileNames = [
      "retinaface.tflite",
      "mb_face_net.tflite",
      "c_model.tflite"
    ];
    getAssetPath(fileNames).then((path) {
      Pointer<Uint8> cpath = mallocCString(path);
      this.detector = ffi_createModel(cpath).address;
      malloc.free(cpath);

      print("MODEL ADDRESS: ${this.detector}");
    });
  }

  List<BBox> forward(CFloatArray img) {
    List<BBox> results = [];
    Result ret = ffi_forwardModel(this.detector, img);

    for (int i = 0; i < ret.length; i++) {
      CBBox cbox = ffi_getBBox(ret.bboxes.elementAt(i).address);
      BBox box = BBox(cbox.score, cbox.bbox, cbox.landmarks);
      results.add(box);
    }

    ffi_freeResult(ret);
    return results;
  }

  void close() {
    ffi_deleteModel(this.detector);
  }
}

Future<String> getAssetPath(List<String> fileNames) async {
  Directory directory = await getApplicationDocumentsDirectory();
  print(directory.path);
  for (var name in fileNames) {
    var dbPath = join(directory.path, name);
    if (FileSystemEntity.typeSync(dbPath) == FileSystemEntityType.notFound) {
      ByteData data = await rootBundle.load("assets/$name");
      List<int> bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      await File(dbPath).writeAsBytes(bytes);
    }
  }
  return directory.path;
}

CFloatArray convertYUVtoRGB(CameraImage image) {
  Pointer<Uint8> yArr = mallocUcharList(image.planes[0].bytes).data;
  Pointer<Uint8> uArr = mallocUcharList(image.planes[1].bytes).data;
  Pointer<Uint8> vArr = mallocUcharList(image.planes[2].bytes).data;
  int yRowStride = image.planes[0].bytesPerRow;
  int uvRowStride = image.planes[1].bytesPerRow;
  int uvPixelStride = image.planes[1].bytesPerPixel!;

  var img = ffi_convertYUVtoRGB(yArr, uArr, vArr, yRowStride, uvRowStride,
      uvPixelStride, image.width, image.height, 90, 0);
  malloc.free(yArr);
  malloc.free(uArr);
  malloc.free(vArr);
  return img;
}

imglib.Image convertYUVtoRGB2(CameraImage image) {
  const shift = (0xFF << 24);

  final int width = image.width;
  final int height = image.height;
  final int uvRowStride = image.planes[1].bytesPerRow;
  final int uvPixelStride = image.planes[1].bytesPerPixel!;

  imglib.Image img = imglib.Image(width, height);

  for (int x = 0; x < width; x++) {
    for (int y = 0; y < height; y++) {
      final int uvIndex = uvPixelStride * (x / 2).floor() + uvRowStride * (y / 2).floor();
      final int index = y * width + x;

      final yp = image.planes[0].bytes[index];
      final up = image.planes[1].bytes[uvIndex];
      final vp = image.planes[2].bytes[uvIndex];

      int r = (yp + vp * 1436 / 1024 - 179).round().clamp(0, 255);
      int g = (yp - up * 46549 / 131072 + 44 - vp * 93604 / 131072 + 91)
          .round()
          .clamp(0, 255);
      int b = (yp + up * 1814 / 1024 - 227).round().clamp(0, 255);
      img.data[index] = shift | (b << 16) | (g << 8) | r;
    }
  }

  int x = (img.width - img.height) ~/ 2;
  img = imglib.copyCrop(img, x, 0, img.height, img.height);
  img = imglib.copyRotate(img, 90);

  // imglib.PngEncoder pngEncoder = imglib.PngEncoder(level: 0, filter: 0);
  // sendPort.send(pngEncoder.encodeImage(img));
  return img;
}

int argmax(Float32List lst) {
  double max_val = double.negativeInfinity;
  int max_i = 0;
  for (var i = 0; i < lst.length; i++) {
    if (lst[i] > max_val) {
      max_i = i;
      max_val = lst[i];
    }
  }
  return max_i;
}

List<int> nonMaximumSupress(Float32List bboxes, Float32List scores,
    {double iou_th: 0.4, double score_th: 0.8}) {
  final scores_ptr = mallocFloatList(scores);
  final bboxes_ptr = mallocFloatList(bboxes);

  final chosen_idx = ffi_nms(bboxes_ptr, scores_ptr, iou_th, score_th);
  var idx = chosen_idx.data.asTypedList(chosen_idx.length);
  List<int> ret = [];
  for (var i in idx) {
    ret.add(i);
  }
  print("CHOSEN IDX: $ret");
  return ret;
}

class BBox {
  late double score;
  late List<double> box;
  late List<double> landmarks;
  String name = "UNK";

  BBox(double scores, CFloatArray bboxes, CFloatArray landmarks) {
    this.score = scores;
    this.box = List.from(bboxes.data.asTypedList(bboxes.length));
    this.landmarks = List.from(landmarks.data.asTypedList(landmarks.length));
  }
}
