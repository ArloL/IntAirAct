#import "IANSURLAdapter.h"

#import "IAResponse.h"
#import "NSURLRequest+IARequest.h"
#import "IALogging.h"

// Log levels: off, error, warn, info, verbose
// Other flags: trace
static const int intAirActLogLevel = IA_LOG_LEVEL_WARN; // | IA_LOG_FLAG_TRACE

@interface IANSURLAdapter ()

@property (nonatomic, strong) NSOperationQueue * operationQueue;

@end

@implementation IANSURLAdapter

- (id)init
{
    self = [super init];
    if (self) {
        _operationQueue = [NSOperationQueue new];
    }
    return self;
}

-(void)sendRequest:(IARequest *)request toDevice:(IADevice *)device
{
    [self sendRequest:request toDevice:device withHandler:nil];
}

-(void)sendRequest:(IARequest *)request toDevice:(IADevice *)device withHandler:(IAResponseHandler)handler
{
    NSAssert(device != nil, @"Device should not be nil");
    NSURLRequest * nsRequest = [NSURLRequest requestWithIARequest:request andDevice:device];
    [NSURLConnection sendAsynchronousRequest:nsRequest queue:self.operationQueue completionHandler:^(NSURLResponse * response, NSData * data, NSError * error) {
        if (error) {
            IALogError(@"An error ocurred: %@", error);
        }
        NSHTTPURLResponse * httpURLResponse = (NSHTTPURLResponse*)response;
        IAResponse * iaResponse = [IAResponse new];
        iaResponse.statusCode = @(httpURLResponse.statusCode);
        iaResponse.body = data;
        [iaResponse.metadata addEntriesFromDictionary:httpURLResponse.allHeaderFields];
        IALogVerbose(@"Response: %@", iaResponse);
        if (handler) {
            handler(iaResponse, error);
        }
    }];
}

@end
