/// BlueState
enum BlueState { blueOn, blueOff }

/// ConnectState
enum ConnectState { connected, disconnected }

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

/// EscTextStyle
enum EscTextStyle { default_, bold, underline, boldAndUnderline }

/// EscFontSize
enum EscFontSize {
  default_,
  size1,
  size2,
  size3,
  size4,
  size5,
  size6,
  size7,
}

/// HriPosition
enum HriPosition { none, above, below, aboveAndBelow }

/// Alignment
enum Alignment { left, center, right }

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

  /// getEscTextStyle
  static int getEscTextStyle(EscTextStyle style) {
    switch (style) {
      case EscTextStyle.default_:
        return 0x0;
      case EscTextStyle.bold:
        return 0x08;
      case EscTextStyle.underline:
        return 0x80;
      case EscTextStyle.boldAndUnderline:
        return 0x88;
    }
  }

  /// getEscFontSize
  static int getEscFontSize(EscFontSize size) {
    switch (size) {
      case EscFontSize.default_:
        return 0;
      case EscFontSize.size1:
        return 1;
      case EscFontSize.size2:
        return 2;
      case EscFontSize.size3:
        return 3;
      case EscFontSize.size4:
        return 4;
      case EscFontSize.size5:
        return 5;
      case EscFontSize.size6:
        return 6;
      case EscFontSize.size7:
        return 7;
    }
  }

  /// getHri
  static int getHri(HriPosition position) {
    switch (position) {
      case HriPosition.none:
        return 0;
      case HriPosition.above:
        return 1;
      case HriPosition.below:
        return 2;
      case HriPosition.aboveAndBelow:
        return 3;
    }
  }

  /// getAlignment
  static int getAlignment(Alignment alignment) {
    switch (alignment) {
      case Alignment.left:
        return 0;
      case Alignment.center:
        return 1;
      case Alignment.right:
        return 2;
    }
  }
}
