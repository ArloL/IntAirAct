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
