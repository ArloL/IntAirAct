#import "IAIntAirAct.h"

#if !(TARGET_OS_IPHONE)
#import <AppKit/AppKit.h>
#endif

#import <RestKit/RestKit.h>
#import <RestKit+Blocks/RKObjectManager+Blocks.h>
#import <ServiceDiscovery/ServiceDiscovery.h>

#import "IAAction.h"
#import "IACapability.h"
#import "IADevice.h"
#import "IALogging.h"
#import "IARouteRequest+BodyAsString.h"
#import "IARouteResponse+Serializer.h"
#import "IAServer.h"
#import "IARoute.h"
#import "IAResponse.h"
#import "IARequest.h"
#import "IARoutingHTTPServerAdapter.h"

NSString * IADeviceFound = @"IADeviceFound";
NSString * IADeviceLost = @"IADeviceLost";

// Log levels: off, error, warn, info, verbose
// Other flags: trace
static const int intAirActLogLevel = IA_LOG_LEVEL_WARN; // | IA_LOG_FLAG_TRACE

@interface IAIntAirAct ()

@property (nonatomic) dispatch_queue_t clientQueue;
@property (nonatomic, strong) NSMutableSet * mDevices;
@property (nonatomic, strong) NSMutableDictionary * objectManagers;
@property (nonatomic) dispatch_queue_t serverQueue;
@property (nonatomic, strong) NSObject<IAServer> * server;
@property (nonatomic, strong) SDServiceDiscovery * serviceDiscovery;
@property (nonatomic, strong) id serviceFoundObserver;
@property (nonatomic, strong) id serviceLostObserver;
@property (nonatomic, strong) NSNotificationCenter * notificationCenter;

@property (nonatomic, strong) IADevice * ownDevice;

@end

@implementation IAIntAirAct

@synthesize isRunning = _isRunning;
@synthesize ownDevice = _ownDevice;

#pragma mark Constructor, Deconstructor

- (id)init
{
    self = [super init];
    if (self) {
        @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"-init is not a valid initializer for the class IAIntAirAct" userInfo:nil];
    }
    return self;
}

-(id)initWithServer:(NSObject<IAServer> *)server andServiceDiscovery:(SDServiceDiscovery*)serviceDiscovery
{
    self = [super init];
    if (self) {
        IALogTrace();
        
        _supportedRoutes = [NSMutableSet new];
        _isRunning = NO;
        _objectMappingProvider = [RKObjectMappingProvider new];
        _router = [RKObjectRouter new];
        
        _clientQueue = dispatch_queue_create("IntAirActClient", NULL);
        _mDevices = [NSMutableSet new];
        _objectManagers = [NSMutableDictionary new];
        _serverQueue = dispatch_queue_create("IntAirActServer", NULL);
        _serviceDiscovery = serviceDiscovery;
        _server = server;
        _notificationCenter = [NSNotificationCenter defaultCenter];
        
        [self setup];
    }
    return self;
}

-(void)dealloc
{
    IALogTrace();
    
	[self stop];
    
#if NEEDS_DISPATCH_RETAIN_RELEASE
    dispatch_release(_serverQueue);
    dispatch_release(_clientQueue);
#endif
    
    [[NSNotificationCenter defaultCenter] removeObserver:self.serviceFoundObserver];
    [[NSNotificationCenter defaultCenter] removeObserver:self.serviceLostObserver];
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
        [_mDevices removeAllObjects];
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
            IALogTrace2(@"%@[%p]: %@", THIS_FILE, myself, @"Found own device");
            myself.ownDevice = [IADevice deviceWithName:service.name host:service.hostName port:service.port capabilities:self.supportedRoutes];
            [myself.notificationCenter postNotificationName:IADeviceFound object:myself userInfo:@{@"device":myself.ownDevice, @"ownDevice":@YES}];
        } else {
            IALogTrace2(@"%@[%p]: %@", THIS_FILE, myself, @"Found other device");
            IADevice * device = [IADevice deviceWithName:service.name host:service.hostName port:service.port capabilities:nil];
            [[myself objectManagerForDevice:device] loadObjectsAtResourcePath:@"/capabilities" handler:^(NSArray * objects, NSError * error) {
                if (error) {
                    IALogError(@"%@[%p]: Could not get device capabilities for device %@: %@", THIS_FILE, myself, device, error);
                } else {
                    IADevice * dev = [IADevice deviceWithName:service.name host:service.hostName port:service.port capabilities:[NSSet setWithArray:objects]];
                    [myself.mDevices addObject:dev];
                    
                    [myself.notificationCenter postNotificationName:IADeviceFound object:myself userInfo:@{@"device":dev}];
                }
            }];
        }
    }];
    
    self.serviceLostObserver = [self.serviceDiscovery addHandlerForServiceLost:^(SDService *service) {
        IADevice * dev = [IADevice deviceWithName:service.name host:service.hostName port:service.port capabilities:nil];
        [myself.mDevices removeObject:dev];
        [myself.notificationCenter postNotificationName:IADeviceLost object:myself userInfo:@{@"device":dev}];
    }];
    
    [self addMappingForClass:[IADevice class] withKeypath:@"devices" withAttributes:@"name", @"host", @"port", nil];
    [self addMappingForClass:[IACapability class] withKeypath:@"capabilities" withAttributes:@"capability", nil];
    
    [self route:[IARoute routeWithAction:@"GET" resource:@"/capabilities"] withHandler:^(IARequest *request, IAResponse *response) {
        IALogTrace3(@"GET /capabilities");
        [response respondWith:self.supportedRoutes withIntAirAct:self];
    }];
    
    RKObjectMapping * actionSerialization = [RKObjectMapping mappingForClass:[NSDictionary class]];
    actionSerialization.rootKeyPath = @"actions";
    [actionSerialization mapAttributes:@"action", nil];
    RKDynamicObjectMapping * parametersSerialization = [RKDynamicObjectMapping dynamicMappingUsingBlock:^(RKDynamicObjectMapping *dynamicMapping) {
        dynamicMapping.forceRootKeyPath = YES;
        dynamicMapping.objectMappingForDataBlock = ^ RKObjectMapping* (id mappableData) {
            return [self.objectMappingProvider serializationMappingForClass:[mappableData class]];
        };
    }];
    [actionSerialization hasMany:@"parameters" withMapping:parametersSerialization];
    [_objectMappingProvider setSerializationMapping:actionSerialization forClass:[IAAction class]];
    
    RKObjectMapping * actionMapping = [RKObjectMapping mappingForClass:[IAAction class]];
    [actionMapping mapAttributes:@"action", @"parameters", nil];
    [_objectMappingProvider setMapping:actionMapping forKeyPath:@"actions"];
    
    [_router routeClass:[IAAction class] toResourcePath:@"/action/:action" forMethod:RKRequestMethodPUT];
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
        result = [_mDevices copy];
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


-(void)addMappingForClass:(Class)className withKeypath:(NSString *)keyPath withAttributes:(NSString *)attributeKeyPath, ...
{
    va_list args;
    va_start(args, attributeKeyPath);
    NSMutableSet* attributeKeyPaths = [NSMutableSet set];
    
    for (NSString* keyPath = attributeKeyPath; keyPath != nil; keyPath = va_arg(args, NSString*)) {
        [attributeKeyPaths addObject:keyPath];
    }
    
    va_end(args);
    
    RKObjectMapping * mapping = [RKObjectMapping mappingForClass:className];
    [mapping mapAttributesFromSet:attributeKeyPaths];
    [self.objectMappingProvider setMapping:mapping forKeyPath:keyPath];
    
    RKObjectMapping * serialization = [mapping inverseMapping];
    serialization.rootKeyPath = keyPath;
    [self.objectMappingProvider setSerializationMapping:serialization forClass:className];
}

-(RKObjectMappingResult*)deserializeObject:(id)data
{
    IALogTrace();
    
    NSError* error = nil;
    id parsedData;
    
    if(![data isKindOfClass:[NSDictionary class]]) {
        NSString * bodyAsString = @"";
        
        if([data isKindOfClass:[NSData class]]) {
            bodyAsString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        } else if ([data isKindOfClass:[NSString class]]) {
            bodyAsString = data;
        }
        id<RKParser> parser = [[RKParserRegistry sharedRegistry] parserForMIMEType:@"application/json"];
        parsedData = [parser objectFromString:bodyAsString error:&error];
    } else {
        parsedData = data;
    }
    
    if (parsedData == nil && error) {
        // Parser error...
        IALogError(@"%@[%p]: An error ocurred while parsing: %@", THIS_FILE, self, error);
        return nil;
    } else {
        RKObjectMapper* mapper = [RKObjectMapper mapperWithObject:parsedData mappingProvider:self.objectMappingProvider];
        return [mapper performMapping];
    }
}

-(NSArray *)devicesWithCapability:(IACapability *)capability
{
    __block NSMutableArray * result;
    
    dispatch_sync(_serverQueue, ^{
        result = [NSMutableArray new];
        for(IADevice * dev in _mDevices) {
            if([dev.capabilities containsObject:capability]) {
                [result addObject:dev];
            }
        }
	});

    return result;
}

-(void)callAction:(IAAction *)action onDevice:(IADevice *)device withHandler:(void (^)(IAAction * action, NSError * error))handler
{
    dispatch_async(_clientQueue, ^{
        RKObjectManager * manager = [self objectManagerForDevice:device];
        if(handler) {
            [manager putObject:action handler:^(RKObjectLoader * loader, NSError * error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    handler(action, error);
                });
            }];
        } else {
            [manager putObject:action delegate:nil];
        }
    });
}

-(RKObjectManager *)objectManagerForDevice:(IADevice *)device
{
    IALogTrace();
    
    NSString * hostAndPort;
    if ([device isEqual:self.ownDevice]) {
        hostAndPort = [NSString stringWithFormat:@"http://127.0.0.1:%"FMTNSINT , device.port];
    } else {
        hostAndPort = [NSString stringWithFormat:@"http://%@:%"FMTNSINT, device.host, device.port];
    }

    RKObjectManager * manager = [_objectManagers objectForKey:hostAndPort];
    
    if(!manager) {
        manager = [[RKObjectManager alloc] initWithBaseURL:[RKURL URLWithBaseURLString:hostAndPort]];
        
        // Ask for & generate JSON
        manager.acceptMIMEType = @"application/json";
        manager.serializationMIMEType = @"application/json";
        
        manager.mappingProvider = _objectMappingProvider;
        
        // Register the router
        manager.router = _router;
        
        [_objectManagers setObject:manager forKey:hostAndPort];
    }
    
    return manager;
}

-(NSString *)resourcePathFor:(NSObject *)resource forObjectManager:(RKObjectManager *)manager
{
    IALogTrace();
    return [manager.router resourcePathForObject:resource method:RKRequestMethodPUT];
}

-(RKObjectSerializer *)serializerForObject:(id)object
{
    RKObjectMapping * mapping = [self.objectMappingProvider serializationMappingForClass:[object class]];
    return [RKObjectSerializer serializerWithObject:object mapping:mapping];
}

-(void)addAction:(NSString *)actionName withSelector:(SEL)selector andTarget:(id)target
{
    NSMethodSignature * signature = [[target class] instanceMethodSignatureForSelector:selector];
    __block NSInvocation * invocation = [NSInvocation invocationWithMethodSignature:signature];
    [invocation setSelector:selector];
    [invocation setTarget:target];
    
    NSString * returnType = [NSString stringWithFormat:@"%s", [[invocation methodSignature] methodReturnType]];
    
    // keep this here because otherwise we run into a memory release issue
    __block id returnValue;
    
    [self route:[IARoute routeWithAction:@"PUT" resource:[@"/action/" stringByAppendingString:actionName]] withHandler:^(IARequest *request, IAResponse *response) {
        IALogVerbose(@"%@", [@"PUT /action/" stringByAppendingString:actionName]);
        IALogTrace2(@"Request: %@", [request bodyAsString]);
        
        RKObjectMappingResult * result = [self deserializeObject:[request body]];
        if(!result || ![[result asObject] isKindOfClass:[IAAction class]]) {
            IALogError(@"%@[%p]: Could not parse request body: %@", THIS_FILE, self, [request bodyAsString]);
            response.statusCode = @500;
            return;
        }
        
        IAAction * action = [result asObject];
        if((signature.numberOfArguments - 2) != [action.parameters count]) {
            response.statusCode = @500;
            return;
        }
        
        int i = 0;
        while (i < [action.parameters count]) {
            id obj = [action.parameters objectAtIndex:i];
            if(![self isNativeObject:obj]) {
                obj = [[self deserializeObject:obj] asObject];
            }
            [invocation setArgument:&obj atIndex:i+2];
            i++;
        }
        [invocation invoke];
        response.statusCode = @201;
        if (![returnType isEqualToString:@"v"]) {
            [invocation getReturnValue:&returnValue];
            action.parameters = [NSArray arrayWithObjects:returnValue, nil];
            [response respondWith:action withIntAirAct:self];
        }
    }];
    
    IACapability * cap = [IACapability new];
    cap.capability = [@"PUT /action/" stringByAppendingString:actionName];
    [self.supportedRoutes addObject:cap];
}


-(BOOL)isNativeObject:(id)object
{
    NSArray * classes = [NSArray arrayWithObjects:[NSNumber class], [NSString class], nil];
    for(id class in classes) {
        if([object isKindOfClass:class]) {
            return YES;
        }
    }
    return NO;
}

-(BOOL)route:(IARoute *)route withHandler:(IARequestHandler)block
{
    return [self.server route:route withHandler:block];
}

#pragma mark Notification support

-(void)removeObserver:(id)observer
{
    [self.notificationCenter removeObserver:observer];
}

-(id)addHandlerForDeviceFound:(IADeviceFoundHandler)handler
{
    return [self.notificationCenter addObserverForName:IADeviceFound object:self queue:nil usingBlock:^(NSNotification *note) {
        if(note.userInfo) {
            NSObject * obj = note.userInfo[@"device"];
            if(obj && [obj isKindOfClass:[IADevice class]]) {
                if(note.userInfo[@"ownDevice"] == @YES) {
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
    return [self.notificationCenter addObserverForName:IADeviceLost object:self queue:nil usingBlock:^(NSNotification *note) {
        if(note.userInfo) {
            NSObject * obj = note.userInfo[@"device"];
            if(obj && [obj isKindOfClass:[IADevice class]]) {
                handler((IADevice *)obj);
            }
        }
    }];
}

@end
