#import "IAServer.h"
#import "IAClient.h"

@class IADevice;
@class IARoute;
@class IARequest;
@class IAResponse;

/**
 The names of the notifications used to notify about found/lost devices.
 */
extern NSString * IADeviceFound;
extern NSString * IADeviceLost;

/**
 The block definitions for when a device was found/lost.
 */
typedef void (^IADeviceFoundHandler)(IADevice * device, BOOL ownDevice);
typedef void (^IADeviceLostHandler)(IADevice * device);

@interface IAIntAirAct : NSObject

/**
 The supported routes of this device.
 */
@property (nonatomic, strong) NSMutableSet * supportedRoutes;

/**
 All the currently available devices.
 */
@property (nonatomic, readonly) NSSet * devices;

/**
 `YES` if IntAirAct is running, `NO` otherwise.
 */
@property (nonatomic, readonly) BOOL isRunning;

/**
 Returns the current device if it has been found yet, `nil` otherwise.

 You can use addHandlerForDeviceFound and check the BOOL ownDevice.
 */
@property (nonatomic, strong, readonly) IADevice * ownDevice;

/**
 The port on which to listen on.
 
 Default is 0. This means the system will find a free port.
 */
@property (nonatomic) NSInteger port;

/**
 Instantiates IntAirAct with RoutingHTTPServerAdapter as the server and IANSURLAdapter as the client.
 */
-(id)init;

/**
 Instantiates IntAirAct.

 @param server The server to use for publishing routes.
 @param client The client to use when sending requests to other devices.
 */
-(id)initWithServer:(NSObject<IAServer> *)server client:(NSObject<IAClient> *)client;

/**
 Standard Deconstructor.

 Stops the server and releases any resources connected with this instance.
 */
-(void)dealloc;

/**
 Attempts to start IntAirAct.

 A usage example:

    NSError *err = nil;
    if (![intairact start:&er]]) {
        NSLog(@"Error starting IntAirAct: %@", err);
    }

 @param errPtr An optional NSError instance.

 @return Returns `YES` if successful, `NO` on failure and sets the errPtr (if given).
 */
-(BOOL)start:(NSError **)errPtr;

/** Stops IntAirAct. */
-(void)stop;

/**
 Get an array of devices that support a certain route.

 @param route The route which the devices should support.

 @return Returns an array of devices that support the specified route.
 */
-(NSArray *)devicesSupportingRoute:(IARoute *)route;

/**
 Get the IADevice for a device name.

 @param name The name of the device.

 @return Returns an IADevice if a device with the name exists.
 */
-(IADevice *)deviceWithName:(NSString *)name;

/**
 Add a handler for a specific route.

 @param route The route to add.
 @param handler The handler to execute.

 @return Returns `YES` if successful, `NO` on failure e.g. the route already exists.
 */
-(BOOL)route:(IARoute*)route withHandler:(IARequestHandler)handler;

/**
 Send a request to a device without listening for a response or error case.

 @param request The request to send.
 @param device The target device.
 */
-(void)sendRequest:(IARequest*)request toDevice:(IADevice*)device;

/**
 Send a request to a device. The handler gets executed in a response or error case.

 @param request The request to send.
 @param device The target device.
 @param handler The handler to execute in a response or error case.
 */
-(void)sendRequest:(IARequest*)request toDevice:(IADevice*)device withHandler:(IAResponseHandler)handler;

/**
 Send a request to all devices supporting a route. The handler gets executed in a response or error case.

 @param request The request to send.
 @param route The route the target devices have to support.
 @param handler The handler to execute in a response or error case.

 @return Returns `YES` if there were devices supporting the route, `NO` otherwise.
 */
-(BOOL)sendRequest:(IARequest*)request toDevicesSupportingRoute:(IARoute*)route withHandler:(IAResponseHandler)handler;

/**
 Remove a handler.

 Be sure to invoke `removeHandler:` before any object used in a handler
 is deallocated.

 @param handler The handler to remove.
 */
-(void)removeHandler:(id)handler;

/**
 Add a block to be executed when a device is found.

 To unregister the handler, you pass the object returned by this method to
 `removeHandler:`. You *must* invoke `removeHandler:` before any object
 used in the handler is deallocated.

 @param handler The block to be executed when a device is found.

 @return Returns an opaque object to identify the handler.
 */
-(id)addHandlerForDeviceFound:(IADeviceFoundHandler)handler;

/**
 Add a block to be executed when a device is lost.

 To unregister the handler, you pass the object returned by this method to
 `removeHandler:`. You *must* invoke `removeHandler:` before any object
 used in the handler is deallocated.

 @param handler The block to be executed when a device is lost.

 @return Returns an opaque object to identify the handler.
 */
-(id)addHandlerForDeviceLost:(IADeviceLostHandler)handler;

@end
