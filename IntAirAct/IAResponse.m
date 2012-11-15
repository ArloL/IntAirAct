#import "IAResponse.h"

#import <RestKit/RestKit.h>

#import "IAIntAirAct.h"
#import "IALogging.h"

// Log levels: off, error, warn, info, verbose
// Other flags: trace
static const int intAirActLogLevel = IA_LOG_LEVEL_INFO; // | IA_LOG_FLAG_TRACE;

@implementation IAResponse

- (id)init
{
    self = [super init];
    if (self) {
        _metadata = [NSMutableDictionary new];
        _statusCode = OK;
    }
    return self;
}

-(NSString *)description
{
    return [NSString stringWithFormat:@"IAResponse[statusCode: %@, metadata: %@]", self.statusCode, self.metadata];
}

-(void)respondWith:(id)data withIntAirAct:(IAIntAirAct *)intAirAct
{
    NSError * error = nil;
    NSString * response;
    
    if([data isKindOfClass:[NSArray class]] || [data isKindOfClass:[NSSet class]]) {
        RKObjectSerializer * serializer;
        id serialized = [NSMutableArray new];
        for(id entry in data) {
#warning serializer is nil
            serializer = nil;
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
        id<RKParser> parser = [[RKParserRegistry sharedRegistry] parserForMIMEType:@"application/json"];
        response = [parser stringFromObject:serialized error:&error];
    } else {
#warning serializer is nil
        RKObjectSerializer* serializer = nil;
        id serializedObject = [serializer serializedObject:&error];
        if(!error) {
            id<RKParser> parser = [[RKParserRegistry sharedRegistry] parserForMIMEType:@"application/json"];
            response = [parser stringFromObject:serializedObject error:&error];
        }
    }
    
    if (error) {
        self.statusCode = @500;
        IALogError(@"Serializing failed for source object %@: %@", data, [error localizedDescription]);
    } else {
        self.statusCode = @200;
        [self respondWithString:response];
        self.metadata[@"Content-Type"] = @"application/json";
        IALogVerbose(@"%@: Serialization of data: %@", THIS_FILE, response);
    }
}

- (void)respondWithString:(NSString *)string {
	[self respondWithString:string encoding:NSUTF8StringEncoding];
}

- (void)respondWithString:(NSString *)string encoding:(NSStringEncoding)encoding {
	[self respondWithData:[string dataUsingEncoding:encoding]];
}

- (void)respondWithData:(NSData *)data {
    self.body = data;
}


@end
