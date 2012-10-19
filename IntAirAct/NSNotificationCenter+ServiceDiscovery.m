#import "NSNotificationCenter+ServiceDiscovery.h"

#import "SDServiceDiscovery.h"

@implementation NSNotificationCenter (ServiceDiscovery)

+(id)addHandlerForServiceFound:(SDServiceFoundHandler)handler
{
    return [[self defaultCenter] addHandlerForServiceFound:handler];
}

+(id)addHandlerForServiceLost:(SDServiceLostHandler)handler
{
    return [[self defaultCenter] addHandlerForServiceLost:handler];
}

+(id)addHandlerForServiceDiscoveryError:(SDErrorHandler)handler
{
    return [[self defaultCenter] addHandlerForServiceDiscoveryError:handler];
}

-(id)addHandlerForServiceFound:(SDServiceFoundHandler)handler
{
    return [self addObserverForName:SDServiceFound object:nil queue:nil usingBlock:^(NSNotification *note) {
        if([note.object isKindOfClass:[SDService class]]) {
            handler(note.object, YES);
        } else {
            handler(nil, NO);
        }
    }];
}

-(id)addHandlerForServiceLost:(SDServiceLostHandler)handler
{
    return [self addObserverForName:SDServiceLost object:nil queue:nil usingBlock:^(NSNotification *note) {
        if([note.object isKindOfClass:[SDService class]]) {
            handler(note.object);
        } else {
            handler(nil);
        }
    }];
}

-(id)addHandlerForServiceDiscoveryError:(SDErrorHandler)handler
{
    return [self addObserverForName:SDServiceDiscoveryError object:nil queue:nil usingBlock:^(NSNotification *note) {
        if([note.object isKindOfClass:[NSDictionary class]]) {
            handler(note.object);
        } else {
            handler(nil);
        }
    }];
}

@end
