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
    NSError * error = nil;
    NSString * response;
    
    if([data isKindOfClass:[NSArray class]]) {
        RKObjectSerializer * serializer;
        id serialized = [NSMutableArray new];
        for(id entry in data) {
            serializer = [intAirAct serializerForObject:entry];
            id serializedObject = [serializer serializedObject:&error withRootKeyPath:NO];
            if(error) {
                IALogWarn(@"Could not serialize Object: %@", entry);
                continue;
            }
            [serialized addObject:serializedObject];
        }
        if(serializer && serializer.mapping.rootKeyPath) {
            serialized = [NSDictionary dictionaryWithObjectsAndKeys:serialized, serializer.mapping.rootKeyPath, nil];
        }
        id<RKParser> parser = [[RKParserRegistry sharedRegistry] parserForMIMEType:intAirAct.defaultMimeType];
        response = [parser stringFromObject:serialized error:&error];
    } else {
        RKObjectSerializer* serializer = [intAirAct serializerForObject:data];
        id serializedObject = [serializer serializedObject:&error];
        if(!error) {
            id<RKParser> parser = [[RKParserRegistry sharedRegistry] parserForMIMEType:intAirAct.defaultMimeType];
            response = [parser stringFromObject:serializedObject error:&error];
        }
    }
        
    if (error) {
        self.statusCode = 500;
        IALogError(@"Serializing failed for source object %@: %@", data, [error localizedDescription]);
    } else {
        self.statusCode = 200;
        [self respondWithString:response];
        IALogInfo(@"%@: Serialization of data: %@", THIS_FILE, response);
    }
}

@end
