//
//  cpclCommand.m
//  bluetooth_print_plus
//
//  Created by kaka on 2024/4/27.
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
    NSLog(@"Cpcl call.method : %@", call.method);
    int x = [[argumentsDict valueForKey:@"x"] intValue];
    int y = [[argumentsDict valueForKey:@"y"] intValue];
    int width = [[argumentsDict valueForKey:@"width"] intValue];
    int height = [[argumentsDict valueForKey:@"height"] intValue];
    int rotation = [[argumentsDict valueForKey:@"rotation"] intValue];
    NSString *content = [argumentsDict valueForKey:@"content"];
    
    if ([@"cleanCommand" isEqualToString:call.method]) {
        self.escCommand = nil;
        result(@(YES));
    } else if ([@"getCommand" isEqualToString:call.method]) {
        result([self.escCommand getCommand]);
    } else if ([@"image" isEqualToString:call.method]) {
        FlutterStandardTypedData *imageData = call.arguments[@"image"];
        UIImage *image = [UIImage imageWithData:imageData.data];
        [self.escCommand addOriginrastBitImage:image width:image.size.width];
        result(@(YES));
    } else if([@"print" isEqualToString:call.method]) {
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
