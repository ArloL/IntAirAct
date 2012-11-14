@class IADevice;
@class IARequest;
@class IAResponse;

typedef void (^IAResponseHandler)(IAResponse *response);

@protocol IAClient <NSObject>

-(void)sendRequest:(IARequest*)request toDevice:(IADevice*)device withHandler:(IAResponseHandler)handler;

@end
