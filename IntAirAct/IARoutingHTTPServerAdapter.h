#import "IAServer.h"

@class RoutingHTTPServer;

@interface IARoutingHTTPServerAdapter : NSObject<IAServer>

-(id)initWithRoutingHTTPServer:(RoutingHTTPServer*)routingHTTPServer;

@end
