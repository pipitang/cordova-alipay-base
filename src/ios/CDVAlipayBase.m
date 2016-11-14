#import "CDVAlipayBase.h"

#import <AlipaySDK/AlipaySDK.h>

@interface CDVAlipayBase()
@property NSString* aliPID;
@end

@implementation CDVAlipayBase

@synthesize aliPID;

-(void)pluginInitialize
{
    self.aliPID = [[self.commandDelegate settings] objectForKey:@"ali_pid"];
}


- (void) pay:(CDVInvokedUrlCommand*)command
{
    if ([aliPID length] == 0)
    {
        CDVPluginResult *commandResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"支付PID错误"];
        [self.commandDelegate sendPluginResult:commandResult callbackId:command.callbackId];
        return;
    }

    //从参数中合成paymentString，绝不能把private_key放在客户端中，阿里给的例子太有误导性，新手很容易图简单直接拿来用，殊不知危险性有多高。为了保证安全性，支付字符串需要从服务端合成。
    NSMutableDictionary *args = [command argumentAtIndex:0];
    
    //For the client-server based payment, the signed content must be extractly same. In other
    // words, the order of properties matters on both both sides.
    NSArray *sortedKeys = [args.allKeys sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"self" ascending:YES]]];

    NSMutableString * orderString = [NSMutableString string];
    //Let's remove the sign and sign_type properties first
    for (NSString * key in sortedKeys) {
        if ([@"sign" isEqualToString:key] || [@"sign_type" isEqualToString:key]) continue;
        [orderString appendFormat:@"%@=\"%@\"&", key, [args objectForKey:key]];
    }

    [orderString appendFormat:@"%@=\"%@\"&", @"sign", [args objectForKey:@"sign"]];
    [orderString appendFormat:@"%@=\"%@\"&", @"sign_type", [args objectForKey:@"sign_type"]];
    [orderString deleteCharactersInRange:NSMakeRange([orderString length] -1, 1)];
    
    
    NSMutableString * schema = [NSMutableString string];
    [schema appendFormat:@"ALI%@", self.aliPID];
    
    [[AlipaySDK defaultService] payOrder:orderString fromScheme:schema callback:^(NSDictionary *resultDic) {
        dispatch_async(dispatch_get_main_queue(), ^{
            CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:resultDic];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
        });
    }];
}


- (void)handleOpenURL:(NSNotification *)notification
{
    NSURL* url = [notification object];
    
    if ([url.scheme rangeOfString:self.aliPID].length > 0)
    {
        //跳转支付宝钱包进行支付，处理支付结果
        [[AlipaySDK defaultService] processOrderWithPaymentResult:url standbyCallback:^(NSDictionary *resultDic) {
            dispatch_async(dispatch_get_main_queue(), ^{
                CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:resultDic];
                [self.commandDelegate sendPluginResult:pluginResult callbackId:nil];
            });
        }];
    }
}

@end
