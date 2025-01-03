//
//  cpclCommand.m
//  bluetooth_print_plus
//
//  Created by amoLink on 2024/4/27.
//

#import "cpclCommandPlugin.h"
#import "CPCLCommand.h"

@interface CpclCommandPlugin ()

@property (nonatomic, strong) CPCLCommand *cpclCommand;

@end

@implementation CpclCommandPlugin
+ (void)registerWithRegistrar:(nonnull NSObject<FlutterPluginRegistrar> *)registrar { }

- (void)handleMethodCall:(FlutterMethodCall *)call result:(FlutterResult)result {
    NSMutableDictionary *argumentsDict = call.arguments;
    // NSLog(@"Cpcl call.method : %@", call.method);
    int x = [[argumentsDict valueForKey:@"x"] intValue];
    int y = [[argumentsDict valueForKey:@"y"] intValue];
    int width = [[argumentsDict valueForKey:@"width"] intValue];
    int height = [[argumentsDict valueForKey:@"height"] intValue];
    int rotation = [[argumentsDict valueForKey:@"rotation"] intValue];
    NSString *content = [argumentsDict valueForKey:@"content"];
    
    if ([@"cleanCommand" isEqualToString:call.method]) {
        self.cpclCommand = nil;
        result(@(YES));
    } else if ([@"getCommand" isEqualToString:call.method]) {
        result([self.cpclCommand getCommand]);
    } else if ([@"size" isEqualToString:call.method]) {
        int copies = [[argumentsDict valueForKey:@"copies"] intValue];
        [self.cpclCommand addInitializePrinterwithOffset:0 withHeight:height withQTY:copies];
        [self.cpclCommand addPagewidth:width];
        result(@(YES));
    } else if ([@"image" isEqualToString:call.method]) {
        FlutterStandardTypedData *imageData = call.arguments[@"image"];
        UIImage *image = [UIImage imageWithData:imageData.data];
        [self.cpclCommand addGraphics:COMPRESSED WithXstart:x withYstart:y withImage:image withMaxWidth:image.size.width];
        result(@(YES));
    } else if ([@"text" isEqualToString:call.method]) {
        int xMulti = [[argumentsDict valueForKey:@"xMulti"] intValue];
        int yMulti = [[argumentsDict valueForKey:@"yMulti"] intValue];
        int bold = [[argumentsDict valueForKey:@"bold"] boolValue];
        TEXTCOMMAND tc = T;
        switch (rotation) {
            case 0:
                tc = T;
                break;
            case 90:
                tc = T90;
                break;
            case 180:
                tc = T180;
                break;
            case 270:
                tc = T270;
                break;
        }
        if (bold) {
            [self.cpclCommand setBold:YES];
        }
        [self.cpclCommand addSetmagWithWidthScale:xMulti withHeightScale:yMulti];
        [self.cpclCommand addText:tc withFont:3 withXstart:x withYstart:y withContent:content];
        if (bold) {
            [self.cpclCommand setBold:NO];
        }
        result(@(YES));
    } else if ([@"qrCode" isEqualToString:call.method]) {
        [self.cpclCommand addQrcode:BARCODE withXstart:x withYstart:y with:2 with:width withString:content];
        result(@(YES));
    }  else if ([@"barCode" isEqualToString:call.method]) {
        BOOL vertical = [[argumentsDict valueForKey:@"vertical"] boolValue];
        NSString *codeType = [argumentsDict valueForKey:@"codeType"];
        CPCLBARCODETYPE ct = Code128;
        if ([codeType isEqualToString:@"UPCA"]) {
            ct = Upc_A;
        } else if ([codeType isEqualToString:@"UPCE"]) {
            ct = Upc_E;
        } else if ([codeType isEqualToString:@"EAN13"]) {
            ct = Ean13;
        } else if ([codeType isEqualToString:@"EAN8"]) {
            ct = Ean8;
        } else if ([codeType isEqualToString:@"39"]) {
            ct = Code39;
        } else if ([codeType isEqualToString:@"93"]) {
            ct = Code93;
        } else if ([codeType isEqualToString:@"CODABAR"]) {
            ct = Codebar;
        }
        [self.cpclCommand addBarcode:vertical == YES ? VBARCODE : BARCODE withType:ct withWidth:width withRatio:Point2 withHeight:height withXstart:x withYstart:y withString:content];
        result(@(YES));
    } else if([@"line" isEqualToString:call.method]) {
        int endX = [[argumentsDict valueForKey:@"endX"] intValue];
        int endY = [[argumentsDict valueForKey:@"endY"] intValue];
        [self.cpclCommand addLineWithXstart:x withYstart:y withXend:endX withYend:endY withWidth:width];
        result(@(YES));
    } else if([@"print" isEqualToString:call.method]) {
        [self.cpclCommand addPrint];
        result(@(YES));
    } else if([@"form" isEqualToString:call.method]) {
//        @"FORM\r\n"
//        [self.cpclCommand ];
        result(@(YES));
    }
    else {
        result(FlutterMethodNotImplemented);
    }
}

- (CPCLCommand *)cpclCommand {
    if (!_cpclCommand) {
        _cpclCommand = [CPCLCommand new];
    }
    return _cpclCommand;
}


@end
