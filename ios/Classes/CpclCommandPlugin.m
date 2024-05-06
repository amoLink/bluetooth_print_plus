//
//  cpclCommand.m
//  bluetooth_print_plus
//
//  Created by kaka on 2024/4/27.
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
    NSLog(@"Cpcl call.method : %@", call.method);
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
        [self.cpclCommand addGraphics:EXPANDED WithXstart:x withYstart:y withImage:image withMaxWidth:image.size.width];
        result(@(YES));
    } else if([@"print" isEqualToString:call.method]) {
        [self.cpclCommand addPrint];
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
