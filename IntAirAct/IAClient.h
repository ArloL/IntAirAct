@class IADevice;
@class IARequest;
@class IAResponse;

/**
 A block that is called when the response is received or an error occured.

 @param request The received request.
 @param error The received error. `nil` if there was no error.
 */
typedef void (^IAResponseHandler)(IAResponse *response, NSError * error);

@protocol IAClient <NSObject>

/**
 Send a request to a device.
 
 The handler is executed when the response is received or an error occured.

 @param request The request to send.
 @param device The target device.
 @param handler The handler to execute in a response or error case.
 */
-(void)sendRequest:(IARequest*)request toDevice:(IADevice*)device withHandler:(IAResponseHandler)handler;

@end
