//
//  cpclCommand.m
//  bluetooth_print_plus
//
//  Created by amoLink on 2024/4/27.
//

#import "EscCommandPlugin.h"
#import "EscCommand.h"

@interface EscCommandPlugin ()

@property (nonatomic, strong) EscCommand *escCommand;

@end

@implementation EscCommandPlugin
+ (void)registerWithRegistrar:(nonnull NSObject<FlutterPluginRegistrar> *)registrar { }

- (void)handleMethodCall:(FlutterMethodCall *)call result:(FlutterResult)result {
    NSMutableDictionary *argumentsDict = call.arguments;
    // NSLog(@"esc call.method : %@", call.method);
    int x = [[argumentsDict valueForKey:@"x"] intValue];
    int y = [[argumentsDict valueForKey:@"y"] intValue];
    int width = [[argumentsDict valueForKey:@"width"] intValue];
    int height = [[argumentsDict valueForKey:@"height"] intValue];
    int rotation = [[argumentsDict valueForKey:@"rotation"] intValue];
    int alignment = [[argumentsDict valueForKey:@"alignment"] intValue];
    NSString *content = [argumentsDict valueForKey:@"content"];
    
    if ([@"cleanCommand" isEqualToString:call.method]) {
        self.escCommand = nil;
        result(@(YES));
    } else if ([@"getCommand" isEqualToString:call.method]) {
        result([self.escCommand getCommand]);
    } else if ([@"text" isEqualToString:call.method]) {
        int printMode = [[argumentsDict valueForKey:@"printMode"] intValue];
        int size = [[argumentsDict valueForKey:@"size"] intValue];
        int charcterSize = 0;
        switch (size) {
            case 0:
                charcterSize = 0;
                break;
            case 1:
                charcterSize = 0x12;
                break;
            case 2:
                charcterSize = 0x22;
                break;
            case 3:
                charcterSize = 0x33;
                break;
            case 4:
                charcterSize = 0x44;
                break;
            case 5:
                charcterSize = 0x55;
                break;
            case 6:
                charcterSize = 0x666;
                break;
            case 7:
                charcterSize = 0x77;
                break;
            default:
                charcterSize = 0;
                break;
        }
        [self.escCommand addSetJustification:alignment];
        [self.escCommand addPrintMode:printMode];
        [self.escCommand addSetCharcterSize:charcterSize];
        [self.escCommand addText:content];
        
        [self.escCommand addPrintMode:0];
        [self.escCommand addSetCharcterSize:0];
        result(@(YES));
    } else if ([@"code128" isEqualToString:call.method]) {
        [self.escCommand addSetJustification:alignment];
        int hri = [[argumentsDict valueForKey:@"hri"] intValue];
        [self.escCommand addSetBarcodeWidth:width];
        [self.escCommand addSetBarcodeHeight:height];
        [self.escCommand addSetBarcodeHRPosition:hri];
        [self.escCommand addCODE128:'B' :content];
        result(@(YES));
    } else if ([@"qrCode" isEqualToString:call.method]) {
        int size = [[argumentsDict valueForKey:@"size"] intValue];
        [self.escCommand addSetJustification:alignment];
        [self.escCommand addQRCodeSizewithpL:0 withpH:0 withcn:0 withyfn:0 withn:size];
        [self.escCommand addQRCodeSavewithpL:0x0b withpH:0 withcn:0x31 withyfn:0x50 withm:0x30 withData:[content dataUsingEncoding:NSUTF8StringEncoding]];
        [self.escCommand addQRCodePrintwithpL:0 withpH:0 withcn:0 withyfn:0 withm:0];
        result(@(YES));
    } else if ([@"image" isEqualToString:call.method]) {
        FlutterStandardTypedData *imageData = call.arguments[@"image"];
        UIImage *image = [UIImage imageWithData:imageData.data];
        [self.escCommand addSetJustification:alignment];
        [self.escCommand addOriginrastBitImage:image width:image.size.width];
        result(@(YES));
    } else if ([@"newline" isEqualToString:call.method]) {
        [self.escCommand addPrintAndLineFeed];
        result(@(YES));
    }else if([@"cutPaper" isEqualToString:call.method]) {
        BOOL fullCut = [[argumentsDict valueForKey:@"fullCut"] boolValue];
        [self.escCommand addCutPaper:fullCut];
        result(@(YES));
    } else if([@"sound" isEqualToString:call.method]) {
        int number = [[argumentsDict valueForKey:@"number"] intValue];
        int time = [[argumentsDict valueForKey:@"time"] intValue];
        [self.escCommand addSound:number :time :1];
        result(@(YES));
    }  else if([@"print" isEqualToString:call.method]) {
        int feedLines = [[argumentsDict valueForKey:@"feedLines"] intValue];
        [self.escCommand addPrintAndFeedLines:feedLines];
        result(@(YES));
    }
    else {
        result(FlutterMethodNotImplemented);
    }
}

- (EscCommand *)escCommand {
    if (!_escCommand) {
        _escCommand = [EscCommand new];
        [_escCommand addInitializePrinter];
    }
    return _escCommand;
}


@end
