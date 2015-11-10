#import "CDVAlipayBase.h"

#import <AlipaySDK/AlipaySDK.h>

@interface CDVAlipayBase()
@property NSString* aliPID;
@property NSString* currentCallbackId;
@end

@implementation CDVAlipayBase

@synthesize aliPID, currentCallbackId;

-(void)pluginInitialize
{
    self.aliPID = [[self.commandDelegate settings] objectForKey:@"ali_pid"];
    NSLog(@"Loaded alipay plugin with %@", self.aliPID);
}


- (void) pay:(CDVInvokedUrlCommand*)command
{
    if ([aliPID length] == 0)
    {
        CDVPluginResult *commandResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"支付PID错误"];
        [self.commandDelegate sendPluginResult:commandResult callbackId:command.callbackId];
        return;
    }

    //从参数中合成paymentString，绝不能把private_key放在客户端中，阿里给的例子太有误导性，新手很容易图简单直接拿来用，殊不知危险性有多高。
    NSMutableDictionary *args = [command argumentAtIndex:0];
    NSMutableString * orderString = [NSMutableString string];
    for (NSString * key in [args allKeys]) {
        [orderString appendFormat:@"%@=\"%@\"&", key, [args objectForKey:key]];
    }
    NSRange lastChar = NSMakeRange([orderString length] -1, 1);
    [orderString deleteCharactersInRange:lastChar];

    NSLog(@"Calling Alipay using %@", orderString);
    self.currentCallbackId = command.callbackId;
    [[AlipaySDK defaultService] payOrder:orderString fromScheme:aliPID callback:^(NSDictionary *resultDic) {
        NSLog(@"Alipay returns immediately with %@",resultDic);
        dispatch_async(dispatch_get_main_queue(), ^{
            self.currentCallbackId = nil;
            CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:resultDic];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
        });
    }];
}


- (void)handleOpenURL:(NSNotification *)notification
{
    NSURL* url = [notification object];
    
    if ([url.scheme isEqualToString:self.aliPID] && currentCallbackId != nil)
    {
        //跳转支付宝钱包进行支付，处理支付结果
        [[AlipaySDK defaultService] processOrderWithPaymentResult:url standbyCallback:^(NSDictionary *resultDic) {
            NSLog(@"Alipay return from openURL with %@",resultDic);
            dispatch_async(dispatch_get_main_queue(), ^{
                CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:resultDic];
                [self.commandDelegate sendPluginResult:pluginResult callbackId:currentCallbackId];
                currentCallbackId = nil;
            });
        }];
    }
}

@end
