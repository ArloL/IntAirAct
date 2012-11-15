#import "IAServer.h"

@class RoutingHTTPServer;
@class IAIntAirAct;

@interface IARoutingHTTPServerAdapter : NSObject<IAServer>

-(id)initWithRoutingHTTPServer:(RoutingHTTPServer*)routingHTTPServer;

@property (strong) IAIntAirAct * intAirAct;

@end
