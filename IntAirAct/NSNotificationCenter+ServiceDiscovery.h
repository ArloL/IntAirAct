#import "SDService.h"

typedef void (^SDServiceHandler)(SDService * service);
typedef void (^SDErrorHandler)(NSDictionary * service);

@interface NSNotificationCenter (ServiceDiscovery)

+(id)addHandlerForServiceFound:(SDServiceHandler)handler;
+(id)addHandlerForServiceLost:(SDServiceHandler)handler;
+(id)addHandlerForServiceDiscoveryError:(SDErrorHandler)handler;

-(id)addHandlerForServiceFound:(SDServiceHandler)handler;
-(id)addHandlerForServiceLost:(SDServiceHandler)handler;
-(id)addHandlerForServiceDiscoveryError:(SDErrorHandler)handler;

@end
