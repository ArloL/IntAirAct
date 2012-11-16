#import "IAServer.h"
#import "IAClient.h"

@class SDServiceDiscovery;

@class IAAction;
@class IADevice;
@class IARoute;
@class IARequest;
@class IAResponse;

extern NSString * IADeviceFound;
extern NSString * IADeviceLost;

typedef void (^IADeviceFoundHandler)(IADevice * device, BOOL ownDevice);
typedef void (^IADeviceLostHandler)(IADevice * device);

@interface IAIntAirAct : NSObject

/** A Set of all the supported routes this device has. */
@property (nonatomic, strong) NSMutableSet * supportedRoutes;

/** A list of all the currently available devices. */
@property (nonatomic, readonly) NSSet * devices;

/** `YES` if IntAirAct is running, `NO` otherwise. */
@property (nonatomic, readonly) BOOL isRunning;

/** Returns the current device if it has been found yet, `nil` otherwise. */
@property (nonatomic, strong, readonly) IADevice * ownDevice;

/** The port on which to listen on. Default is 0. This means the system will find a free port. */
@property (nonatomic) NSInteger port;

/**
 Instantiates IntAirAct with RoutingHTTPServerAdapter as the server and IANSURLAdapter as the client.
 */
-(id)init;

/** Standard Constructor.
 
 Instantiates IntAirAct, but does not start it.
 
 @param server An optional NSError instance.
 @param serviceDiscovery An optional NSError instance.
 */
-(id)initWithServer:(NSObject<IAServer> *)server client:(NSObject<IAClient> *)client;

/** Standard Deconstructor.
 
 Stops the server, and clients, and releases any resources connected with this instance.
 */
-(void)dealloc;

/** Attempts to start IntAirAct.
 
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

/** Get an array of devices that support a certain route.
 
 @param route the route which the devices should support.
 @return an array of devices that support the specified route.
 */
-(NSArray *)devicesSupportingRoute:(IARoute *)route;

-(IADevice *)deviceWithName:(NSString *)name;

-(BOOL)route:(IARoute*)route withHandler:(IARequestHandler)handler;

-(void)sendRequest:(IARequest*)request toDevice:(IADevice*)device;

-(void)sendRequest:(IARequest*)request toDevice:(IADevice*)device withHandler:(IAResponseHandler)handler;

-(void)removeObserver:(id)observer;

-(id)addHandlerForDeviceFound:(IADeviceFoundHandler)handler;

-(id)addHandlerForDeviceLost:(IADeviceLostHandler)handler;

@end
