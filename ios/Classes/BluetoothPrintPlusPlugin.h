#import <Flutter/Flutter.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import <GSDK/BLEConnecter.h>

@interface BluetoothPrintPlusPlugin : NSObject<FlutterPlugin>

@property(nonatomic,copy) ConnectDeviceState state;

@end

@interface BluetoothPrintStreamHandler : NSObject<FlutterStreamHandler>

@property FlutterEventSink sink;

@end
