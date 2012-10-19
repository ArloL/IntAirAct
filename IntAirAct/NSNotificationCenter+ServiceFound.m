#import "NSNotificationCenter+ServiceFound.h"

#import "SDServiceDiscovery.h"

@implementation NSNotificationCenter (ServiceFound)

+(id)addHandlerForServiceFound:(SDServiceHandler)handler
{
    return [[self defaultCenter] addHandlerForServiceFound:handler];
}

-(id)addHandlerForServiceFound:(SDServiceHandler)handler
{
    return [self addObserverForName:SDServiceFound object:nil queue:nil usingBlock:^(NSNotification *note) {
        handler(note.object);
    }];
}

@end
