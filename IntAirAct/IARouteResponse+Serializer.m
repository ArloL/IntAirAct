#import "IARouteResponse+Serializer.h"

#import <RestKit/RestKit.h>

#import "IAIntAirAct.h"
#import "IALogging.h"

// Log levels: off, error, warn, info, verbose
// Other flags: trace
static const int intAirActLogLevel = IA_LOG_LEVEL_INFO; // | IA_LOG_FLAG_TRACE;

@implementation RouteResponse (Serializer)

-(void)respondWith:(id)data withIntAirAct:(IAIntAirAct *)intAirAct
{
    RKObjectSerializer* serializer = [intAirAct serializerForObject:data];
    
    NSError * error = nil;
    id params = [serializer serializationForMIMEType:intAirAct.defaultMimeType error:&error];
    
    if (error) {
        self.statusCode = 500;
        IALogError(@"Serializing failed for source object %@: %@", data, [error localizedDescription]);
    } else {
        self.statusCode = 200;
        [self respondWithData:[params data]];
        IALogInfo(@"%@: Serialization of data: %@", THIS_FILE, [[NSString alloc] initWithData:[params data] encoding:NSUTF8StringEncoding]);
    }
}

@end
