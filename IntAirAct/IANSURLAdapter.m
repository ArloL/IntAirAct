#import "IANSURLAdapter.h"

#import "IAResponse.h"
#import "NSURLRequest+IARequest.h"

@implementation IANSURLAdapter

-(void)sendRequest:(IARequest *)request toDevice:(IADevice *)device
{
    [self sendRequest:request toDevice:device withHandler:nil];
}

-(void)sendRequest:(IARequest *)request toDevice:(IADevice *)device withHandler:(IAResponseHandler)handler
{
    NSAssert(device != nil, @"Device should not be nil");
    NSURLRequest * nsRequest = [NSURLRequest requestWithIARequest:request andDevice:device];
    [NSURLConnection sendAsynchronousRequest:nsRequest queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse * response, NSData * data, NSError * error) {
        if (handler) {
            NSHTTPURLResponse * httpURLResponse = (NSHTTPURLResponse*)response;
            IAResponse * iaResponse = [IAResponse new];
            iaResponse.statusCode = @(httpURLResponse.statusCode);
            iaResponse.body = data;
            [iaResponse.metadata addEntriesFromDictionary:httpURLResponse.allHeaderFields];
            handler(iaResponse, error);
        }
    }];
}

@end
