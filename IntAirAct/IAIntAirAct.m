#import "IAIntAirAct.h"

#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#else
#import <AppKit/AppKit.h>
#endif

#import <ServiceDiscovery/ServiceDiscovery.h>
#import <RoutingHTTPServer/RoutingHTTPServer.h>

#import "IADevice.h"
#import "IALogging.h"
#import "IAServer.h"
#import "IARoute.h"
#import "IAResponse.h"
#import "IARequest.h"
#import "IARoutingHTTPServerAdapter.h"
#import "IANSURLAdapter.h"

NSString * IADeviceFound = @"IADeviceFound";
NSString * IADeviceLost = @"IADeviceLost";

// Log levels: off, error, warn, info, verbose
// Other flags: trace
static const int intAirActLogLevel = IA_LOG_LEVEL_INFO; // | IA_LOG_FLAG_TRACE

@interface IAIntAirAct ()

@property (nonatomic) dispatch_queue_t clientQueue;
@property (nonatomic, strong) NSMutableSet * foundDevices;
@property (nonatomic, strong) NSMutableDictionary * objectManagers;
@property (nonatomic) dispatch_queue_t serverQueue;
@property (nonatomic, strong) NSObject<IAServer> * server;
@property (nonatomic, strong) NSObject<IAClient> * client;
@property (nonatomic, strong) SDServiceDiscovery * serviceDiscovery;
@property (nonatomic, strong) id serviceFoundObserver;
@property (nonatomic, strong) id serviceLostObserver;

@property (nonatomic, strong) IADevice * ownDevice;

@end

@implementation IAIntAirAct

@synthesize isRunning = _isRunning;
@synthesize ownDevice = _ownDevice;

#pragma mark Constructor, Deconstructor

- (id)init
{
    IARoutingHTTPServerAdapter * routingHTTPServerAdapter = [IARoutingHTTPServerAdapter new];
    IANSURLAdapter * nsURLAdapter = [IANSURLAdapter new];

    self = [self initWithServer:routingHTTPServerAdapter client:nsURLAdapter];
    
    // necessary to set the origin on incoming requests
    routingHTTPServerAdapter.intAirAct = self;

    return self;
}

-(id)initWithServer:(NSObject<IAServer> *)server client:(NSObject<IAClient>*)client
{
    self = [super init];
    if (self) {
        IALogTrace();
        
        _supportedRoutes = [NSMutableSet new];
        _isRunning = NO;
        
        _clientQueue = dispatch_queue_create("IntAirActClient", NULL);
        _foundDevices = [NSMutableSet new];
        _objectManagers = [NSMutableDictionary new];
        _serverQueue = dispatch_queue_create("IntAirActServer", NULL);
        _serviceDiscovery = [SDServiceDiscovery new];
#if DEBUG
        [_serviceDiscovery setLogLevel:SD_LOG_LEVEL_INFO];
#endif
        _server = server;
        _client = client;
        
        [self setup];
    }
    return self;
}

-(void)dealloc
{
    IALogTrace();
    
	[self stop];

    [self.serviceDiscovery removeHandler:self.serviceFoundObserver];
    [self.serviceDiscovery removeHandler:self.serviceLostObserver];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark Start, Stop, Setup

-(BOOL)start:(NSError **)errPtr;
{
    IALogTrace();
    
    __block BOOL success = YES;
	__block NSError * err = nil;
    
    if(_isRunning) {
        return success;
    }
    
    dispatch_sync(_serverQueue, ^{ @autoreleasepool {
        success = [_server start:&err];
        
        if (success) {
            IALogInfo3(@"Started IntAirAct.");
            int port = (int)_server.port;
            [self.serviceDiscovery publishServiceOfType:@"_intairact._tcp." onPort:port];
            [self.serviceDiscovery searchForServicesOfType:@"_intairact._tcp."];
            _isRunning = YES;
        } else {
            IALogError(@"%@[%p]: Failed to start IntAirAct: %@", THIS_FILE, self, err);
        }
	}});
	
	if (errPtr) {
		*errPtr = err;
    }
	
	return success;
}

-(void)stop
{
    IALogTrace();
    
    dispatch_sync(_serverQueue, ^{ @autoreleasepool {
        [_server stop];
        [_serviceDiscovery stop];
        [_foundDevices removeAllObjects];
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:IADeviceLost object:nil];
        });
        _ownDevice = nil;
        _isRunning = NO;
    }});
}

-(void)setup
{
    // Reference myself weakly from inside the block to avoid a retain cycle like:
    // IAIntAiract -> SDServiceDisovery -> block -> IAIntAirAct
    __weak IAIntAirAct * myself = self;
    
    self.serviceFoundObserver = [self.serviceDiscovery addHandlerForServiceFound:^(SDService *service, BOOL ownService) {
        if (ownService) {
            myself.ownDevice = [IADevice deviceWithName:service.name host:service.hostname port:service.port supportedRoutes:myself.supportedRoutes];
            IALogInfo(@"%@[%p]: Own device: %@:%"FMTNSINT, THIS_FILE, myself, myself.ownDevice.host, myself.ownDevice.port);
            [[NSNotificationCenter defaultCenter] postNotificationName:IADeviceFound object:myself userInfo:@{@"device":myself.ownDevice, @"ownDevice":@YES}];
        } else {
            IALogTrace2(@"%@[%p]: %@", THIS_FILE, myself, @"Found other device");
            IADevice * device = [IADevice deviceWithName:service.name host:service.hostname port:service.port supportedRoutes:nil];
            IARequest * request = [IARequest requestWithRoute:[IARoute get:@"/routes"] metadata:nil parameters:nil origin:myself.ownDevice body:nil];
            [myself sendRequest:request toDevice:device withHandler:^(IAResponse *response, NSError *error) {
                if (error) {
                    IALogError(@"%@[%p]: Could not get supported routes of device %@: %@", THIS_FILE, myself, device, error);
                } else {
                    IADevice * dev = [IADevice deviceWithName:service.name host:service.hostname port:service.port supportedRoutes:[NSSet setWithArray:[response bodyAs:[IARoute class]]]];
                    [myself.foundDevices addObject:dev];

                    [[NSNotificationCenter defaultCenter] postNotificationName:IADeviceFound object:myself userInfo:@{@"device":dev}];
                }
            }];
        }
    }];
    
    self.serviceLostObserver = [self.serviceDiscovery addHandlerForServiceLost:^(SDService *service) {
        IADevice * dev = [IADevice deviceWithName:service.name host:service.hostname port:service.port supportedRoutes:nil];
        [myself.foundDevices removeObject:dev];
        [[NSNotificationCenter defaultCenter] postNotificationName:IADeviceLost object:myself userInfo:@{@"device":dev}];
    }];
    
    [self route:[IARoute routeWithAction:@"GET" resource:@"/routes"] withHandler:^(IARequest *request, IAResponse *response) {
        IALogTrace3(@"GET /routes");
        [response setBodyWith:self.supportedRoutes];
    }];

#if TARGET_OS_IPHONE
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(stop)
                                                 name:UIApplicationWillResignActiveNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(stop)
                                                 name:UIApplicationWillTerminateNotification
                                               object:nil];
#else
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(stop)
                                                 name:NSApplicationWillTerminateNotification
                                               object:nil];
#endif
}

#pragma mark Properties

-(BOOL)isRunning
{
	__block BOOL result;
	
	dispatch_sync(_serverQueue, ^{
		result = _isRunning;
	});
	
	return result;
}

-(IADevice *)ownDevice
{
    __block IADevice * result;
	
	dispatch_sync(_serverQueue, ^{
        result = _ownDevice;
	});
	
	return result;
}

-(NSArray *)devices
{
    __block NSArray * result;
	
	dispatch_sync(_serverQueue, ^{
        result = [_foundDevices copy];
	});
	
	return result;
}

-(void)setPort:(NSInteger)port
{
    self.server.port = port;
}

-(NSInteger)port
{
    return self.server.port;
}

#pragma mark Methods

-(NSArray *)devicesSupportingRoute:(IARoute *)route
{
    __block NSMutableArray * result;

    dispatch_sync(_serverQueue, ^{
        result = [NSMutableArray new];
        for(IADevice * dev in _foundDevices) {
            if([dev.supportedRoutes containsObject:route]) {
                [result addObject:dev];
            }
        }
	});

    return result;
}

-(IADevice *)deviceWithName:(NSString *)name
{
    __block IADevice * result;

    dispatch_sync(_serverQueue, ^{
        if ([_ownDevice.name isEqualToString:name]) {
            result = _ownDevice;
        } else {
            [_foundDevices enumerateObjectsUsingBlock:^(IADevice * dev, BOOL *stop) {
                if([dev.name isEqualToString:name]) {
                    result = dev;
                    *stop = YES;
                }
            }];
        }
	});

    return result;
}

-(BOOL)route:(IARoute *)route withHandler:(IARequestHandler)handler
{
    [self.supportedRoutes addObject:route];
    return [self.server route:route withHandler:handler];
}

-(void)sendRequest:(IARequest *)request toDevice:(IADevice *)device
{
    [self sendRequest:request toDevice:device withHandler:nil];
}

-(void)sendRequest:(IARequest *)request toDevice:(IADevice *)device withHandler:(IAResponseHandler)handler
{
    /* This is super dumb too*/
    if(!request.origin)
        request.origin = self.ownDevice; 
    
    [self.client sendRequest:request toDevice:device withHandler:handler];
}

-(BOOL)sendRequest:(IARequest*)request toDevicesSupportingRoute:(IARoute*)route withHandler:(IAResponseHandler)handler
{
    NSArray * devices = [self devicesSupportingRoute:route];
    if (devices.count == 0) {
        return NO;
    }
    
    for(IADevice * device in devices)
    {
        [self sendRequest:request toDevice:device withHandler:handler];
    }
    return YES;
}

#pragma mark Notification support

-(void)removeHandler:(id)handler
{
    [[NSNotificationCenter defaultCenter] removeObserver:handler];
}

-(id)addHandlerForDeviceFound:(IADeviceFoundHandler)handler
{
    return [[NSNotificationCenter defaultCenter] addObserverForName:IADeviceFound object:self queue:nil usingBlock:^(NSNotification *note) {
        if(note.userInfo) {
            NSObject * obj = note.userInfo[@"device"];
            if(obj && [obj isKindOfClass:[IADevice class]]) {
                if([note.userInfo[@"ownDevice"] isEqual: @YES]) {
                    handler((IADevice *)obj, YES);
                } else {
                    handler((IADevice *)obj, NO);
                }
            }
        }
    }];
}

-(id)addHandlerForDeviceLost:(IADeviceLostHandler)handler
{
    return [[NSNotificationCenter defaultCenter] addObserverForName:IADeviceLost object:self queue:nil usingBlock:^(NSNotification *note) {
        if(note.userInfo) {
            NSObject * obj = note.userInfo[@"device"];
            if(obj && [obj isKindOfClass:[IADevice class]]) {
                handler((IADevice *)obj);
            }
        }
    }];
}

@end
