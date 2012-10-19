#import "SDService.h"

typedef void (^SDServiceFoundHandler)(SDService * service, BOOL ownDevice);
typedef void (^SDServiceLostHandler)(SDService * service);
typedef void (^SDErrorHandler)(NSDictionary * service);

@interface NSNotificationCenter (ServiceDiscovery)

+(id)addHandlerForServiceFound:(SDServiceFoundHandler)handler;
+(id)addHandlerForServiceLost:(SDServiceLostHandler)handler;
+(id)addHandlerForServiceDiscoveryError:(SDErrorHandler)handler;

-(id)addHandlerForServiceFound:(SDServiceFoundHandler)handler;
-(id)addHandlerForServiceLost:(SDServiceLostHandler)handler;
-(id)addHandlerForServiceDiscoveryError:(SDErrorHandler)handler;

@end
