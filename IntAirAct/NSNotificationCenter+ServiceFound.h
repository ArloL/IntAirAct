#import "SDService.h"

typedef void (^SDServiceHandler)(SDService * service);

@interface NSNotificationCenter (ServiceFound)

+(id)addHandlerForServiceFound:(SDServiceHandler)handler;
-(id)addHandlerForServiceFound:(SDServiceHandler)handler;

@end
