#import <Flutter/Flutter.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import <GSDK/BLEConnecter.h>

#define NAMESPACE @"bluetooth_print_plus"

@interface BluetoothPrintPlusPlugin : NSObject<FlutterPlugin>

@property(nonatomic,copy) ConnectDeviceState state;

@end

@interface BluetoothPrintStreamHandler : NSObject<FlutterStreamHandler>

@property FlutterEventSink sink;

@end

typedef enum NSUInteger {
    CharacterSizeEnumDefault = 0,
    CharacterSizeEnumDoubleHeight = 2,
    CharacterSizeEnumDoubleWidth = 16,
    PrintModeEnumDefault = 0,
    PrintModeEnumBold = 8,
    PrintModeEnumUnderline = 128
}TextTypeEnum;
