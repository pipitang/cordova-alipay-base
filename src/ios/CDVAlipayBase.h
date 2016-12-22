#import <Cordova/CDV.h>

@interface CDVAlipayBase : CDVPlugin

@property(nonatomic,strong)NSString *appId;
@property(nonatomic,strong)NSString *currentCallbackId;

- (void) pay:(CDVInvokedUrlCommand*)command;
@end
