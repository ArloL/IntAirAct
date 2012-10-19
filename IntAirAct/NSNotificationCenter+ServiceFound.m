#import "NSNotificationCenter+ServiceFound.h"

#import "SDServiceDiscovery.h"

@implementation NSNotificationCenter (ServiceFound)

+(id)addHandlerForServiceFound:(SDServiceHandler)handler
{
    return [[self defaultCenter] addHandlerForServiceFound:handler];
}

+(id)addHandlerForServiceLost:(SDServiceHandler)handler
{
    return [[self defaultCenter] addHandlerForServiceLost:handler];
}

+(id)addHandlerForServiceDiscoveryError:(SDErrorHandler)handler
{
    return [[self defaultCenter] addHandlerForServiceDiscoveryError:handler];
}

-(id)addHandlerForServiceFound:(SDServiceHandler)handler
{
    return [self addObserverForName:SDServiceFound object:nil queue:nil usingBlock:^(NSNotification *note) {
        if([note.object isKindOfClass:[SDService class]]) {
            handler(note.object);
        } else {
            handler(nil);
        }
    }];
}

-(id)addHandlerForServiceLost:(SDServiceHandler)handler
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
