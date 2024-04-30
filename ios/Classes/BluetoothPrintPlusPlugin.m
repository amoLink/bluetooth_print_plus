#import "BluetoothPrintPlusPlugin.h"
#import "ConnecterManager.h"
#import "EscCommand.h"
#import "TscCommand.h"
#import "TscCommandPlugin.h"

@interface BluetoothPrintPlusPlugin ()
@property(nonatomic, retain) NSObject<FlutterPluginRegistrar> *registrar;
@property(nonatomic, retain) FlutterMethodChannel *channel;
@property(nonatomic, retain) BluetoothPrintStreamHandler *stateStreamHandler;
@property(nonatomic, assign) int stateID;
@property(nonatomic) NSMutableDictionary *scannedPeripherals;
@end

@implementation BluetoothPrintPlusPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  FlutterMethodChannel* channel = [FlutterMethodChannel
      methodChannelWithName:@"bluetooth_print_plus/methods"
            binaryMessenger:[registrar messenger]];
    BluetoothPrintPlusPlugin* instance = [[BluetoothPrintPlusPlugin alloc] init];

  instance.channel = channel;
    FlutterEventChannel* stateChannel = [FlutterEventChannel eventChannelWithName:NAMESPACE @"/state" binaryMessenger:[registrar messenger]];
   //STATE
  BluetoothPrintStreamHandler* stateStreamHandler = [[BluetoothPrintStreamHandler alloc] init];
  [stateChannel setStreamHandler:stateStreamHandler];
      instance.stateStreamHandler = stateStreamHandler;
      [registrar addMethodCallDelegate:instance channel:channel];
    
//    FlutterEventChannel *eventChannel = [FlutterEventChannel eventChannelWithName:NAMESPACE @"/event" binaryMessenger:[registrar messenger]];
    
    instance.scannedPeripherals = [NSMutableDictionary new];
    
    FlutterMethodChannel *blueChannel = [FlutterMethodChannel methodChannelWithName:@"bluetooth_print_plus"
              binaryMessenger:[registrar messenger]];
    BluetoothPrintPlusPlugin *printPlus = [[BluetoothPrintPlusPlugin alloc] init];
    [registrar addMethodCallDelegate:printPlus channel:blueChannel];
      
    FlutterMethodChannel *tscChannel = [FlutterMethodChannel methodChannelWithName:@"bluetooth_print_plus_tsc" binaryMessenger:[registrar messenger]];
    TscCommandPlugin *tsc = [[TscCommandPlugin alloc] init];
    [registrar addMethodCallDelegate:tsc channel:tscChannel];
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
  NSLog(@"call method -> %@", call.method);
    if ([@"getPlatformVersion" isEqualToString:call.method]) {
        result([@"iOS " stringByAppendingString:[[UIDevice currentDevice] systemVersion]]);
    }
  if ([@"state" isEqualToString:call.method]) {
    result([NSNumber numberWithInt:self.stateID]);
  } else if([@"isAvailable" isEqualToString:call.method]) {

    result(@(YES));
  } else if([@"isConnected" isEqualToString:call.method]) {

    bool isConnected = self.stateID == 1;

    result(@(isConnected));
  } else if([@"isOn" isEqualToString:call.method]) {
    result(@(YES));
  }else if([@"startScan" isEqualToString:call.method]) {
      NSLog(@"getDevices method -> %@", call.method);
      [self.scannedPeripherals removeAllObjects];

      if (Manager.bleConnecter == nil) {
          [Manager didUpdateState:^(NSInteger state) {
              switch (state) {
                  case CBManagerStateUnsupported:
                      NSLog(@"The platform/hardware doesn't support Bluetooth Low Energy.");
                      break;
                  case CBManagerStateUnauthorized:
                      NSLog(@"The app is not authorized to use Bluetooth Low Energy.");
                      break;
                  case CBManagerStatePoweredOff:
                      NSLog(@"Bluetooth is currently powered off.");
                      break;
                  case CBManagerStatePoweredOn:
                      [self startScan];
                      NSLog(@"Bluetooth power on");
                      break;
                  case CBManagerStateUnknown:
                  default:
                      break;
              }
          }];
      } else {
          [self startScan];
      }

    result(nil);
  } else if([@"stopScan" isEqualToString:call.method]) {
    [Manager stopScan];
    result(nil);
  } else if([@"connect" isEqualToString:call.method]) {
    NSDictionary *device = [call arguments];
    @try {
      NSLog(@"connect device begin -> %@", [device objectForKey:@"name"]);
      CBPeripheral *peripheral = [_scannedPeripherals objectForKey:[device objectForKey:@"address"]];

      self.state = ^(ConnectState state) {
        [self updateConnectState:state];
      };
      [Manager connectPeripheral:peripheral options:nil timeout:2 connectBlack: self.state];

      result(nil);
    } @catch(FlutterError *e) {
      result(e);
    }
  } else if([@"disconnect" isEqualToString:call.method]) {
    @try {
      [Manager close];
      result(nil);
    } @catch(FlutterError *e) {
      result(e);
    }
  } else if([@"print" isEqualToString:call.method]) {
     @try {
       result(nil);
     } @catch(FlutterError *e) {
       result(e);
     }
  } else if([@"write" isEqualToString:call.method]) {
       @try {
         NSDictionary *args = [call arguments];
         FlutterStandardTypedData *command = [args objectForKey:@"data"];
           NSData *ddd = command.data;
         [Manager write:command.data];
         result(nil);
       } @catch(FlutterError *e) {
         result(e);
       }
  } else {
      result(FlutterMethodNotImplemented);
  }
}

-(void)startScan {
    [Manager scanForPeripheralsWithServices:nil options:nil discover:^(CBPeripheral * _Nullable peripheral, NSDictionary<NSString *,id> * _Nullable advertisementData, NSNumber * _Nullable RSSI) {
        if (peripheral.name.length > 0) {
            NSLog(@"find device -> %@", peripheral.name);
            [self.scannedPeripherals setObject:peripheral forKey:[[peripheral identifier] UUIDString]];

            NSDictionary *device = [NSDictionary dictionaryWithObjectsAndKeys:peripheral.identifier.UUIDString,@"address",peripheral.name,@"name",nil,@"type",nil];
            [_channel invokeMethod:@"ScanResult" arguments:device];
        }
    }];

}

-(void)updateConnectState:(ConnectState)state {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSNumber *ret = @0;
        switch (state) {
            case CONNECT_STATE_CONNECTING:
                NSLog(@"status -> %@", @"连接状态：连接中....");
                ret = @0;
                self.stateID = 0;
                break;
            case CONNECT_STATE_CONNECTED:
                NSLog(@"status -> %@", @"连接状态：连接成功");
                ret = @1;
                self.stateID = 1;
                break;
            case CONNECT_STATE_FAILT:
                NSLog(@"status -> %@", @"连接状态：连接失败");
                ret = @0;
                break;
            case CONNECT_STATE_DISCONNECT:
                NSLog(@"status -> %@", @"连接状态：断开连接");
                ret = @0;
                self.stateID = -1;
                break;
            default:
                NSLog(@"status -> %@", @"连接状态：连接超时");
                ret = @0;
                self.stateID = -1;
                break;
        }

         NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:ret,@"id",nil];
        if(_stateStreamHandler.sink != nil) {
          self.stateStreamHandler.sink([dict objectForKey:@"id"]);
        }
    });
}

@end

@implementation BluetoothPrintStreamHandler
- (FlutterError*)onListenWithArguments:(id)arguments eventSink:(FlutterEventSink)eventSink {
  self.sink = eventSink;
  return nil;
}

- (FlutterError*)onCancelWithArguments:(id)arguments {
  self.sink = nil;
  return nil;
}

@end




