@class IADevice;
@class IARequest;
@class IAResponse;

typedef void (^IAResponseHandler)(IAResponse *response, NSError * error);

@protocol IAClient <NSObject>

-(void)sendRequest:(IARequest*)request toDevice:(IADevice*)device;

-(void)sendRequest:(IARequest*)request toDevice:(IADevice*)device withHandler:(IAResponseHandler)handler;

@end
