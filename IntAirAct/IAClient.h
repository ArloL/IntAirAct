@class IADevice;
@class IARequest;
@class IAResponse;

typedef void (^IAResponseHandler)(IAResponse *response, NSError * error);

@protocol IAClient <NSObject>

/**
 Send a request to a device. The handler gets executed in a response or error case.

 @param request the request to send.
 @param device the target device.
 @handler the handler to execute in a response or error case.
 */
-(void)sendRequest:(IARequest*)request toDevice:(IADevice*)device withHandler:(IAResponseHandler)handler;

@end
