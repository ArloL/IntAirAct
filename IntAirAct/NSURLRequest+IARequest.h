@class IADevice;
@class IARequest;

@interface NSURLRequest (IARequest)

+(NSURLRequest*)requestWithIARequest:(IARequest*)request andDevice:(IADevice*)device;

@end
