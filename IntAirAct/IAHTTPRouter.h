#import "IARouter.h"

@class RoutingHTTPServer;

@interface IAHTTPRouter : NSObject<IARouter>

-(id)initWithRoutingHTTPServer:(RoutingHTTPServer*)routingHTTPServer;

@end
