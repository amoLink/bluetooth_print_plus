#import "BluetoothPrintPlusPlugin.h"
#import "ConnecterManager.h"
#import "EscCommand.h"
#import "TscCommand.h"
#import "TscCommandPlugin.h"
#import "CpclCommandPlugin.h"
#import "EscCommandPlugin.h"

#define WeakSelf(type) __weak typeof(type) weak##type = type

typedef NS_ENUM(NSInteger, BPPState) {
    BlueOn = 0,
    BlueOff,
    DeviceConnected,
    DeviceDisconnected
};

@interface BluetoothPrintPlusPlugin ()

@property(nonatomic, retain) NSObject<FlutterPluginRegistrar> *registrar;
@property(nonatomic, retain) FlutterMethodChannel *channel;
@property(nonatomic, retain) BluetoothPrintStreamHandler *stateStreamHandler;
@property(nonatomic, assign) BPPState stateID;
@property(nonatomic) NSMutableDictionary *scannedPeripherals;

@end

@implementation BluetoothPrintPlusPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    FlutterMethodChannel* channel = [FlutterMethodChannel
                                     methodChannelWithName:@"bluetooth_print_plus/methods"
                                     binaryMessenger:[registrar messenger]];
    BluetoothPrintPlusPlugin* instance = [[BluetoothPrintPlusPlugin alloc] init];
    
    instance.channel = channel;
    FlutterEventChannel* stateChannel = [FlutterEventChannel eventChannelWithName:@"bluetooth_print_plus/state" binaryMessenger:[registrar messenger]];
    //STATE
    BluetoothPrintStreamHandler* stateStreamHandler = [[BluetoothPrintStreamHandler alloc] init];
    [stateChannel setStreamHandler:stateStreamHandler];
    instance.stateStreamHandler = stateStreamHandler;
    [registrar addMethodCallDelegate:instance channel:channel];
    
    instance.scannedPeripherals = [NSMutableDictionary new];
    
    FlutterMethodChannel *blueChannel = [FlutterMethodChannel methodChannelWithName:@"bluetooth_print_plus"
                                                                    binaryMessenger:[registrar messenger]];
    BluetoothPrintPlusPlugin *printPlus = [[BluetoothPrintPlusPlugin alloc] init];
    [registrar addMethodCallDelegate:printPlus channel:blueChannel];
    
    FlutterMethodChannel *tscChannel = [FlutterMethodChannel methodChannelWithName:@"bluetooth_print_plus_tsc" binaryMessenger:[registrar messenger]];
    TscCommandPlugin *tsc = [[TscCommandPlugin alloc] init];
    [registrar addMethodCallDelegate:tsc channel:tscChannel];
    
    FlutterMethodChannel *cpclChannel = [FlutterMethodChannel methodChannelWithName:@"bluetooth_print_plus_cpcl" binaryMessenger:[registrar messenger]];
    CpclCommandPlugin *cpcl = [CpclCommandPlugin new];
    [registrar addMethodCallDelegate:cpcl channel:cpclChannel];
    
    FlutterMethodChannel *escChannel = [FlutterMethodChannel methodChannelWithName:@"bluetooth_print_plus_esc" binaryMessenger:[registrar messenger]];
    EscCommandPlugin *esc = [EscCommandPlugin new];
    [registrar addMethodCallDelegate:esc channel:escChannel];
    
    instance.stateID = BlueOff;
    [Manager didUpdateState:^(NSInteger state) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSNumber *ret = @(BlueOff);
            switch (state) {
                case CBManagerStatePoweredOn:
                    NSLog(@"Bluetooth Powered On");
                    ret = @(BlueOn);
                    instance.stateID = BlueOn;
                    break;
                case CBManagerStatePoweredOff:
                    NSLog(@"Bluetooth Powered Off");
                    ret = @(BlueOff);
                    instance.stateID = BlueOff;
                    break;
                default:
                    return;
            }
            NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:ret ,@"id",nil];
            if(instance.stateStreamHandler.sink != nil) {
                instance.stateStreamHandler.sink([dict objectForKey:@"id"]);
            }
        });
    }];
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    WeakSelf(self);
    // NSLog(@"call method -> %@", call.method);
    if ([@"getPlatformVersion" isEqualToString:call.method]) {
        result([@"iOS " stringByAppendingString:[[UIDevice currentDevice] systemVersion]]);
    }
    if ([@"state" isEqualToString:call.method]) {
        result([NSNumber numberWithInteger:self.stateID]);
    } else if([@"startScan" isEqualToString:call.method]) {
        [self.scannedPeripherals removeAllObjects];
        [self startScan];
        result(nil);
    } else if([@"stopScan" isEqualToString:call.method]) {
        [Manager stopScan];
        result(nil);
    } else if([@"connect" isEqualToString:call.method]) {
        [Manager stopScan];
        NSDictionary *device = [call arguments];
        @try {
            NSLog(@"connect device begin -> %@", [device objectForKey:@"name"]);
            CBPeripheral *peripheral = [_scannedPeripherals objectForKey:[device objectForKey:@"address"]];
            self.state = ^(ConnectState state) {
                [weakself updateConnectState:state];
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
            [Manager write:command.data receCallBack:^(NSData *data) {
                if (data == nil) return;
                // NSLog(@"Received Data: %@", data);
                [weakself.channel invokeMethod:@"ReceivedData" arguments:data];
            }];
            result(nil);
        } @catch(FlutterError *e) {
            result(e);
        }
    } else {
        result(FlutterMethodNotImplemented);
    }
}

-(void)startScan {
    WeakSelf(self);
    [Manager scanForPeripheralsWithServices:nil options:nil discover:^(CBPeripheral * _Nullable peripheral, NSDictionary<NSString *,id> * _Nullable advertisementData, NSNumber * _Nullable RSSI) {
        if (peripheral.name.length > 0) {
            NSLog(@"find device -> %@", peripheral.name);
            [weakself.scannedPeripherals setObject:peripheral forKey:[[peripheral identifier] UUIDString]];
            NSMutableDictionary *dict = [NSMutableDictionary dictionary];
            [dict setValue:peripheral.name forKey:@"name"];
            [dict setValue:peripheral.identifier.UUIDString forKey:@"address"];
            [dict setValue:@(0) forKey:@"type"];
            
            [weakself.channel invokeMethod:@"ScanResult" arguments:dict];
        }
    }];
    
}

-(void)updateConnectState:(ConnectState)state {
    WeakSelf(self);
    dispatch_async(dispatch_get_main_queue(), ^{
        NSNumber *ret = @0;
        switch (state) {
            case CONNECT_STATE_DISCONNECT:
                NSLog(@"status -> %@", @"Connection status：Disconnect");
                ret = @(DeviceDisconnected);
                weakself.stateID = DeviceDisconnected;
                break;
            case CONNECT_STATE_CONNECTED:
                NSLog(@"status -> %@", @"Connection status：Connection successful");
                ret = @(DeviceConnected);
                weakself.stateID = DeviceConnected;
                break;
            default:
                return;
        }
        NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:ret ,@"id",nil];
        if(weakself.stateStreamHandler.sink != nil) {
            weakself.stateStreamHandler.sink([dict objectForKey:@"id"]);
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
