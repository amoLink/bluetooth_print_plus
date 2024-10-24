//
//  TscCommand.m
//  bluetooth_print_plus
//
//  Created by amoLink on 2024/4/27.
//

#import "TscCommandPlugin.h"
#import "TscCommand.h"

@interface TscCommandPlugin ()

@property (nonatomic, strong) TscCommand *tscCommand;

@end

@implementation TscCommandPlugin
+ (void)registerWithRegistrar:(nonnull NSObject<FlutterPluginRegistrar> *)registrar {}

- (void)handleMethodCall:(FlutterMethodCall *)call result:(FlutterResult)result {
    NSMutableDictionary *argumentsDict = call.arguments;
    // NSLog(@"tsc call.method : %@", call.method);
    int x = [[argumentsDict valueForKey:@"x"] intValue];
    int y = [[argumentsDict valueForKey:@"y"] intValue];
    int width = [[argumentsDict valueForKey:@"width"] intValue];
    int height = [[argumentsDict valueForKey:@"height"] intValue];
    int rotation = [[argumentsDict valueForKey:@"rotation"] intValue];
    NSString *content = [argumentsDict valueForKey:@"content"];
    
    if ([@"selfTest" isEqualToString:call.method]) {
        [self.tscCommand addSelfTest];
        result(@(YES));
    } else if ([@"cleanCommand" isEqualToString:call.method]) {
        self.tscCommand = nil;
        result(@(YES));
    } else if ([@"getCommand" isEqualToString:call.method]) {
        result([self.tscCommand getCommand]);
    } else if ([@"print" isEqualToString:call.method]) {
        int copies = [[argumentsDict valueForKey:@"copies"] intValue];
        [self.tscCommand addPrint:1 :copies];
        result(@(YES));
    } else if ([@"gap" isEqualToString:call.method]) {
        int gap = [[argumentsDict valueForKey:@"gap"] intValue];
        [self.tscCommand addGapWithM:gap withN:0];
        result(@(YES));
    } else if ([@"speed" isEqualToString:call.method]) {
        int speed = [[argumentsDict valueForKey:@"speed"] intValue];
        [self.tscCommand addSpeed:speed];
        result(@(YES));
    } else if ([@"density" isEqualToString:call.method]) {
        int density = [[argumentsDict valueForKey:@"density"] intValue];
        [self.tscCommand addSpeed:density];
        result(@(YES));
    } else if ([@"cls" isEqualToString:call.method]) {
        [self.tscCommand addCls];
        result(@(YES));
    } else if ([@"size" isEqualToString:call.method]) {
        [self.tscCommand addSize:width :height];
        result(@(YES));
    } else if ([@"text" isEqualToString:call.method]) {
        int xMulti = [[argumentsDict valueForKey:@"xMulti"] intValue];
        int yMulti = [[argumentsDict valueForKey:@"yMulti"] intValue];
        [self.tscCommand addTextwithX:x withY:y withFont:@"TSS24.BF2" withRotation:rotation withXscal:xMulti withYscal:yMulti withText:content];
        result(@(YES));
    } else if ([@"image" isEqualToString:call.method]) {
        FlutterStandardTypedData *imageData = call.arguments[@"image"];
        UIImage *image = [UIImage imageWithData:imageData.data];
        
        [self.tscCommand addBitmapwithX:x withY:y withMode:0  withImage:image];
        result(@(YES));
    } else if ([@"barCode" isEqualToString:call.method]) {
        NSString *codeType = [argumentsDict valueForKey:@"codeType"];
        BOOL readable = [[argumentsDict valueForKey:@"readable"] boolValue];
        int narrow = [[argumentsDict valueForKey:@"narrow"] intValue];
        int wide = [[argumentsDict valueForKey:@"wide"] intValue];
        [self.tscCommand add1DBarcode:x :y :codeType :height :readable :rotation :narrow :wide :content];
        result(@(YES));
    } else if ([@"qrCode" isEqualToString:call.method]) {
        int cellWidth = [[argumentsDict valueForKey:@"cellWidth"] intValue];
        [self.tscCommand addQRCode:x :y :@"M" :cellWidth :@"A" :rotation :content];
        result(@(YES));
    }
    else if ([@"bar" isEqualToString:call.method]) {
        [self.tscCommand addBar:x :y :width :height];
        result(@(YES));
    }
    else if ([@"box" isEqualToString:call.method]) {
        int endX = [[argumentsDict valueForKey:@"endX"] intValue];
        int endY = [[argumentsDict valueForKey:@"endY"] intValue];
        int linThickness = [[argumentsDict valueForKey:@"linThickness"] intValue];
        [self.tscCommand addBox:x :y :endX :endY :linThickness];
        result(@(YES));
    }
    else {
        result(FlutterMethodNotImplemented);
    }
}

- (TscCommand *)tscCommand {
    if (!_tscCommand) {
        _tscCommand = [TscCommand new];
    }
    return _tscCommand;
}


@end
