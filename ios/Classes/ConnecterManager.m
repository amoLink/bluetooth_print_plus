//
//  ConnecterManager.m
//  GPSDKDemo
//
//  Created by max on 2020/7/22.
//  Copyright © 2020 max. All rights reserved.
//

#import "ConnecterManager.h"
#define WeakSelf(type) __weak typeof(type) weak##type = type
@interface ConnecterManager()
@property(nonatomic,copy)ConnectDeviceState connecterState;
@property(nonatomic,copy)UpdateState updateState;
@end

@implementation ConnecterManager

static ConnecterManager *manager;
static dispatch_once_t once;

+(instancetype)sharedInstance {
    dispatch_once(&once, ^{
        manager = [[ConnecterManager alloc]init];
    });
    return manager;
}

/**
 *  方法说明：连接指定ip和端口号的网络设备
 *  @param ip 设备的ip地址
 *  @param port 设备端口号
 *  @param connectState 连接状态
 *  @param callback 读取数据接口
 */
-(void)connectIP:(NSString *)ip port:(int)port connectState:(void (^)(ConnectState state))connectState callback:(void (^)(NSData *data))callback {
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        self.state = connectState;
        [self updateConnectState];
        if (_ethernetConnecter == nil) {
            self.currentConnMethod = ETHERNET;
            [self initConnecter:self.currentConnMethod];
        }
        [_ethernetConnecter connectIP:ip port:port connectState:self.connecterState callback:callback];
    });
}

/**
 *  方法说明: 更新连接状态
 */
-(void)updateConnectState {
    WeakSelf(self);
    self.connecterState = ^(ConnectState state) {
        if (state == CONNECT_STATE_DISCONNECT) {
            [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:@"deviceDisconnect" object:nil userInfo:nil]];
            NSLog(@"发送通知。。。");
        }
        
        switch (state) {
            case CONNECT_STATE_CONNECTED:
                NSLog(@"连接成功");
                weakself.isConnected = YES;
                weakself.state(state);
                break;
            case CONNECT_STATE_DISCONNECT:
                //发送通知
                NSLog(@"断开连接");
                weakself.peripheral = nil;
                weakself.state(state);
                weakself.isConnected = NO;
                weakself.type = UNKNOWN;
                break;
            default:
                weakself.state(state);
                break;
        }
    };
}

-(void)updateBluetoothState {
    WeakSelf(self);
    self.updateState = ^(NSInteger state) {
        switch (state) {
            case CBCentralManagerStatePoweredOff:
                [weakself close];
                weakself.updateCenterBluetoothState(state);
                break;
            default:
                weakself.updateCenterBluetoothState(state);
                break;
        }
    };
}

/**
 *  方法说明：扫描外设
 *  @param serviceUUIDs 需要发现外设的UUID，设置为nil则发现周围所有外设
 *  @param options  其它可选操作
 *  @param discover 发现的设备
 */
-(void)scanForPeripheralsWithServices:(nullable NSArray<CBUUID *> *)serviceUUIDs options:(nullable NSDictionary<NSString *, id> *)options discover:(void(^_Nullable)(CBPeripheral *_Nullable peripheral,NSDictionary<NSString *, id> *_Nullable advertisementData,NSNumber *_Nullable RSSI))discover {
    [_bleConnecter scanForPeripheralsWithServices:serviceUUIDs options:options discover:discover];
}

/**
 *  方法说明：更新蓝牙状态
 *  @param state 蓝牙状态
 */
-(void)didUpdateState:(void(^)(NSInteger state))state {
    self.updateCenterBluetoothState = state;
    [self updateBluetoothState];
    if (_bleConnecter == nil) {
        self.currentConnMethod = BLUETOOTH;
        [self initConnecter:self.currentConnMethod];
    }
    [_bleConnecter didUpdateState:self.updateState];
}

-(void)initConnecter:(ConnectMethod)connectMethod {
    self.isConnected = NO;
    switch (connectMethod) {
        case BLUETOOTH:
            _bleConnecter = [BLEConnecter new];
            _connecter = _bleConnecter;
            break;
        case ETHERNET:
            _ethernetConnecter = [EthernetConnecter new];
            _connecter = _ethernetConnecter;
            break;
        default:
            break;
    }
}

/**
 *  方法说明：停止扫描
 */
-(void)stopScan {
    [_bleConnecter stopScan];
}

/**
 *  连接
 */
-(void)connectPeripheral:(CBPeripheral *)peripheral options:(nullable NSDictionary<NSString *,id> *)options timeout:(NSUInteger)timeout connectBlack:(void(^_Nullable)(ConnectState state)) connectState{
    self.peripheral = peripheral;
    self.state = connectState;
    [self updateConnectState];
    [_bleConnecter connectPeripheral:peripheral options:options timeout:timeout connectBlack:self.connecterState];
}

-(void)connectPeripheral:(CBPeripheral * _Nullable)peripheral options:(nullable NSDictionary<NSString *,id> *)options {
    self.peripheral = peripheral;
    [_bleConnecter connectPeripheral:peripheral options:options];
}

-(void)write:(NSData *_Nullable)data progress:(void(^_Nullable)(NSUInteger total,NSUInteger progress))progress receCallBack:(void (^_Nullable)(NSData *_Nullable))callBack {
    [_bleConnecter write:data progress:progress receCallBack:callBack];
}

-(void)write:(NSData *)data receCallBack:(void (^)(NSData *))callBack {
//#ifdef DEBUG
    NSLog(@"[ConnecterManager] write:receCallBack:");
    if (self.currentConnMethod == 1) {
        _connecter = _ethernetConnecter;
    }else {
        _connecter = _bleConnecter;
    }
//#endif
    _bleConnecter.writeProgress = nil;
    [_connecter write:data receCallBack:callBack];
}

-(void)write:(NSData *)data {
#ifdef DEBUG
    NSLog(@"[ConnecterManager] write:");
#endif
    _bleConnecter.writeProgress = nil;
    [_connecter write:data];
}

-(void)close {
    if (_connecter) {
        [_connecter close];
    }
}

@end
