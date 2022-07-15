import 'dart:async';
import 'dart:typed_data';
import 'dart:io';
import 'dart:isolate';
import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:face_recognition/utility.dart';
import 'package:face_recognition/common_lib.dart';
import 'package:flutter/services.dart';

Uint8List png = Uint8List.fromList(List<int>.filled(3687743, 255));
bool test = false;
bool isProc = false;

List<BBox> bboxes = [];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();
  final firstCamera = cameras.first;

  print("OPENCV VERSION ${ffi_opencv_version()}");
  print("TFLITE VERSION ${ffi_tfl_version()}");

  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]).then((value) => runApp(MaterialApp(
      theme: ThemeData.dark(),
      home: TakePictureScreen(camera: firstCamera),
    ))
  );

  runApp(MaterialApp(
    theme: ThemeData.dark(),
    home: TakePictureScreen(camera: firstCamera),
  ));
}

// class MainApp extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) => MaterialApp();
// }

// A screen that allows users to take a picture using a given camera.
class TakePictureScreen extends StatefulWidget {
  final CameraDescription camera;

  const TakePictureScreen({
    Key? key,
    required this.camera,
  }) : super(key: key);

  @override
  TakePictureScreenState createState() => TakePictureScreenState();
}

class TakePictureScreenState extends State<TakePictureScreen> {
  late CameraController camCtrl;
  late Future<void> _initializeControllerFuture;
  late FaceDetector detector;

  TakePictureScreenState() {
    print("INIT DETECTOR");
    detector = FaceDetector();
  }

  @override
  void initState() {
    super.initState();
    camCtrl = CameraController(widget.camera, ResolutionPreset.max);
    _initializeControllerFuture = camCtrl.initialize();
    print("INIT STATE");

    _initializeControllerFuture.then((_) {
      camCtrl.startImageStream((CameraImage image) {
        if (isProc) {
          return;
        }
        isProc = true;

        // forward(detector, image).then((bb) {
        //   if (bb.length > 0){
        //     bboxes = bb;
        //     setState(() { });
        //   }
        //   isProc = false;
        // });

        compute(forward, [detector, image]).then((bb) {
          if (bb.length > 0) {
            bboxes = bb;
            setState(() {});
          }
          isProc = false;
        });

        // var recvPort = ReceivePort();
        // Isolate.spawn(predict, [detector, image, recvPort.sendPort]);
        // recvPort.listen((bb){
        //   if (bb.length > 0){
        //     bboxes = bb;
        //     setState(() { });
        //   }
        //   isProc = false;
        // });
      });
    });
  }

  @override
  void dispose() {
    camCtrl.dispose();
    detector.close();
    // detector.extractor.close();
    // detector.recognizer.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(title: const Text('Take a picture')),
      // You must wait until the controller is initialized before displaying the
      // camera preview. Use a FutureBuilder to display a loading spinner until the
      // controller has finished initializing.
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return camPrev(size, camCtrl, context);
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}

class RectPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()
      ..color = Colors.teal
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    Offset s1 = Offset(0, 0);
    Offset e2 = Offset(size.width, size.height);
    Rect rect = Rect.fromPoints(s1, e2);
    canvas.drawRect(rect, paint);

    print("BBOXES: ${bboxes.length}");
    for (var bbox in bboxes) {
      Offset p1 = Offset(bbox.box[0] * size.width, bbox.box[1] * size.height);
      Offset p2 = Offset(bbox.box[2] * size.width, bbox.box[3] * size.height);

      Rect rect = Rect.fromPoints(p1, p2);
      canvas.drawRect(rect, paint);

      double txtSize = (bbox.box[2] - bbox.box[0]) * size.width / 4;
      Offset txtOffset = Offset(bbox.box[0] * size.width, bbox.box[1] * size.height - txtSize * 1.1);

      var txtspn = TextSpan(
        text: bbox.name,
        style: TextStyle(color: Colors.teal, fontSize: txtSize),
      );

      final textPainter = TextPainter(text: txtspn, textDirection: TextDirection.ltr);
      textPainter.layout(minWidth: 0, maxWidth: size.width);
      textPainter.paint(canvas, txtOffset);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}

Widget camPrev(double size, CameraController ctrl, BuildContext context) {
  double previewW = 720;
  double previewH = 1280;

  return Column(
    children: [
      Stack(fit: StackFit.passthrough, children: <Widget>[
        ClipRect(
            child: SizedBox(
                width: size,
                height: size,
                child: FittedBox(
                    fit: BoxFit.fitWidth,
                    alignment: Alignment.center,
                    child: Center(
                        child: Container(
                            width: previewW,
                            height: previewH,
                            child: CameraPreview(ctrl)))))),
        Container(
            width: size,
            height: size,
            child: CustomPaint(painter: RectPainter()))
      ]),
    ],
  );
}



