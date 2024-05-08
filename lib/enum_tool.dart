/// Rotation
enum Rotation { r_0, r_90, r_180, r_270 }

/// BarCodeType
enum BarCodeType {
  c_128,
  c_39,
  c_93,
  c_ITF,
  c_UPCA,
  c_UPCE,
  c_CODABAR,
  c_EAN8,
  c_EAN13,
}

/// EnumTool
class EnumTool {
  /// getRotation
  static int getRotation(Rotation rotation) {
    switch (rotation) {
      case Rotation.r_0:
        return 0;
      case Rotation.r_90:
        return 90;
      case Rotation.r_180:
        return 180;
      case Rotation.r_270:
        return 270;
    }
  }

  /// getCodeType
  static String getCodeType(BarCodeType codeType) {
    switch (codeType) {
      case BarCodeType.c_128:
        return "128";
      case BarCodeType.c_39:
        return "39";
      case BarCodeType.c_93:
        return "93";
      case BarCodeType.c_ITF:
        return "ITF";
      case BarCodeType.c_UPCA:
        return "UPCA";
      case BarCodeType.c_UPCE:
        return "UPCE";
      case BarCodeType.c_CODABAR:
        return "CODABAR";
      case BarCodeType.c_EAN8:
        return "EAN8";
      case BarCodeType.c_EAN13:
        return "EAN13";
    }
  }
}
