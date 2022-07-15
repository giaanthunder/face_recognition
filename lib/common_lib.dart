// ignore_for_file: camel_case_types, non_constant_identifier_names

import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';
import 'package:ffi/ffi.dart';


// struct CIntArray {
//   int num;
//   int *data;
// };
class CIntArray extends Struct {
  @Int32()
  external int length;
  external Pointer<Int32> data;
}

// struct CUintArray {
//   int num;
//   unsigned int *data;
// };
class CUintArray extends Struct {
  @Int32()
  external int length;
  external Pointer<Uint32> data;
}

// struct CFloatArray {
//   int num;
//   float *data;
// };
class CFloatArray extends Struct {
  @Int32()
  external int length;
  external Pointer<Float> data;
}

// struct CUcharArray {
//   int length;
//   unsigned char *data;
// };
class CUcharArray extends Struct {
  @Int32()
  external int length;
  external Pointer<Uint8> data;
}

// struct CBBox {
//     float score;
//     CFloatArray bbox; // 4
//     CFloatArray landmarks; // 10
//     CFloatArray label;
// };
class CBBox extends Struct {
  @Float()
  external double score;
  external CFloatArray bbox;
  external CFloatArray landmarks;
  external CFloatArray label;
}

// struct Result {
//     unsigned int length;
//     BBox *boxes;
// };
class Result extends Struct {
  @Uint32()
  external int length;
  external Pointer<CBBox> bboxes;
}



DynamicLibrary dylib = Platform.isAndroid
  ? DynamicLibrary.open('libcommon_lib.so')
  : DynamicLibrary.process();



// ============ COMMON_LIB ============

// CFloatArray createCFloatArray(unsigned int length, float *data)
typedef createCFloatArray_csign = CFloatArray Function(Int32, Pointer<Float>);
typedef createCFloatArray_dsign = CFloatArray Function(int, Pointer<Float>);
final ffi_createCFloatArray = dylib.lookupFunction<createCFloatArray_csign,createCFloatArray_dsign>('createCFloatArray');

// CIntArray createCIntArray(unsigned int length, int *data)
typedef createCIntArray_csign = CIntArray Function(Int32, Pointer<Int32>);
typedef createCIntArray_dsign = CIntArray Function(int, Pointer<Int32>);
final ffi_createCIntArray = dylib.lookupFunction<createCIntArray_csign,createCIntArray_dsign>('createCIntArray');

// CIntArray createCUintArray(unsigned int length, unsigned int *data)
typedef createCUintArray_csign = CUintArray Function(Int32, Pointer<Uint32>);
typedef createCUintArray_dsign = CUintArray Function(int, Pointer<Uint32>);
final ffi_createCUintArray = dylib.lookupFunction<createCUintArray_csign,createCUintArray_dsign>('createCUintArray');

// CUcharArray createCUcharArray(unsigned int length, unsigned char *data)
typedef createCUcharArray_csign = CUcharArray Function(Int32, Pointer<Uint8>);
typedef createCUcharArray_dsign = CUcharArray Function(int, Pointer<Uint8>);
final ffi_createCUcharArray = dylib.lookupFunction<createCUcharArray_csign,createCUcharArray_dsign>('createCUcharArray');



CFloatArray mallocFloatList(List<double> lst){
  final ptr = malloc.allocate<Float>(sizeOf<Float>() * lst.length);
  for (int i = 0; i < lst.length; i++){
    ptr.elementAt(i).value = lst[i];
  }
  CFloatArray arr = ffi_createCFloatArray(lst.length, ptr);
  return arr;
}

CIntArray mallocIntList(Int32List lst){
  final ptr = malloc.allocate<Int32>(sizeOf<Int32>() * lst.length);
  for (int i = 0; i < lst.length; i++){
    ptr.elementAt(i).value = lst[i];
  }
  CIntArray arr = ffi_createCIntArray(lst.length, ptr);
  return arr;
}

CUintArray mallocUintList(Uint32List lst){
  final ptr = malloc.allocate<Uint32>(sizeOf<Uint32>() * lst.length);
  for (int i = 0; i < lst.length; i++){
    ptr.elementAt(i).value = lst[i];
  }
  CUintArray arr = ffi_createCUintArray(lst.length, ptr);
  return arr;
}

CUcharArray mallocUcharList(Uint8List lst){
  final ptr = malloc.allocate<Uint8>(lst.length);
  for (int i = 0; i < lst.length; i++){
    ptr.elementAt(i).value = lst[i];
  }
  CUcharArray arr = ffi_createCUcharArray(lst.length, ptr);
  return arr;
}

Pointer<Uint8> mallocCString(String dartString){
  final ptr = malloc.allocate<Uint8>(dartString.length + 1);
  for (int i = 0; i < dartString.length; i++){
    ptr.elementAt(i).value = dartString.codeUnitAt(i);
  }
  ptr.elementAt(dartString.length).value = 0;
  return ptr;
}


// ============ OPENCV ============

// const char* version()
typedef opencv_version_csign = Pointer<Utf8> Function();
typedef opencv_version_dsign = Pointer<Utf8> Function();
final opencv_version = dylib.lookupFunction<opencv_version_csign,opencv_version_dsign>('opencv_version');
String ffi_opencv_version() {
  return opencv_version().toDartString();
}

// void process_image(char* inputPath, char* outputPath)
typedef process_image_csign = Void Function(Pointer<Utf8>, Pointer<Utf8>);
typedef process_image_dsign = void Function(Pointer<Utf8>, Pointer<Utf8>);
final processImage = dylib.lookupFunction<process_image_csign,process_image_dsign>('process_image');
void ffi_processImage(String inputPath, String outputPath) {
  processImage(inputPath.toNativeUtf8(), outputPath.toNativeUtf8());
}

// int* nms(float* bboxes, float* classes, float iou_th, float score_th)
typedef nms_csign = CIntArray Function(CFloatArray, CFloatArray, Double, Double);
typedef nms_dsign = CIntArray Function(CFloatArray, CFloatArray, double, double);
final ffi_nms = dylib.lookupFunction<nms_csign,nms_dsign>('nms');

// CFloatArray faceAlign(CUintArray img, CFloatArray bbox, CFloatArray landmarks, unsigned int height, unsigned int width)
typedef faceAlign_csign = CFloatArray Function(CUintArray, CFloatArray, CFloatArray, Uint32, Uint32);
typedef faceAlign_dsign = CFloatArray Function(CUintArray, CFloatArray, CFloatArray, int, int);
final ffi_faceAlign = dylib.lookupFunction<faceAlign_csign,faceAlign_dsign>('faceAlign');

// CFloatArray normalize(float *f1)
typedef normalize_csign = Pointer<Float> Function(Pointer<Float>);
typedef normalize_dsign = Pointer<Float> Function(Pointer<Float>);
final ffi_normalize = dylib.lookupFunction<normalize_csign,normalize_dsign>('normalize');

// CUintArray convertYUVtoRGB(unsigned char *yArr, unsigned char *uArr, unsigned char *vArr,
//             int yRowStride, int uvRowStride, int uvPixelStride,
//             unsigned int width, unsigned int height, unsigned int rotateAngle, bool flip)
typedef convertYUVtoRGB_csign = CFloatArray Function(Pointer<Uint8>,Pointer<Uint8>,Pointer<Uint8>,Int32,Int32,Int32,Uint32,Uint32,Uint32,Uint8);
typedef convertYUVtoRGB_dsign = CFloatArray Function(Pointer<Uint8>,Pointer<Uint8>,Pointer<Uint8>,int,int,int,int,int,int,int);
final ffi_convertYUVtoRGB = dylib.lookupFunction<convertYUVtoRGB_csign,convertYUVtoRGB_dsign>('convertYUVtoRGB');


// CFloatArray preproc(CUintArray img, unsigned int height, unsigned int width, unsigned int size)
typedef preproc_csign = CFloatArray Function(CUintArray,Uint32,Uint32,Uint32);
typedef preproc_dsign = CFloatArray Function(CUintArray,int,int,int);
final ffi_preproc = dylib.lookupFunction<preproc_csign,preproc_dsign>('preproc');



// ============ TFLITE ============


// const char* version()
typedef tfl_version_csign = Pointer<Utf8> Function();
typedef tfl_version_dsign = Pointer<Utf8> Function();
final tfl_version = dylib.lookupFunction<tfl_version_csign,tfl_version_dsign>('tflite_version');
String ffi_tfl_version() {
  return tfl_version().toDartString();
}

// void *createInterpreter(char *h)
typedef createModel_csign = Pointer<Void> Function(Pointer<Uint8>);
typedef createModel_dsign = Pointer<Void> Function(Pointer<Uint8>);
final ffi_createModel = dylib.lookupFunction<createModel_csign,createModel_dsign>('createModel');

// Result forwardModel(void *model_p, CFloatArray input)
typedef forwardModel_csign = Result Function(Uint32, CFloatArray);
typedef forwardModel_dsign = Result Function(int, CFloatArray);
final ffi_forwardModel = dylib.lookupFunction<forwardModel_csign,forwardModel_dsign>('forwardModel');

// void deleteModel(void *model_p)
typedef deleteModel_csign = Void Function(Uint32);
typedef deleteModel_dsign = void Function(int);
final ffi_deleteModel = dylib.lookupFunction<deleteModel_csign,deleteModel_dsign>('deleteModel');


// void freeResult(Result res)
typedef freeResult_csign = Void Function(Result);
typedef freeResult_dsign = void Function(Result);
final ffi_freeResult = dylib.lookupFunction<freeResult_csign,freeResult_dsign>('freeResult');


// CBBox getBBox(CBBox *box)
typedef getBBox_csign = CBBox Function(Uint32);
typedef getBBox_dsign = CBBox Function(int);
final ffi_getBBox = dylib.lookupFunction<getBBox_csign,getBBox_dsign>('getBBox');










