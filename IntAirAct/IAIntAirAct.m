#import "IAIntAirAct.h"

#if !(TARGET_OS_IPHONE)
#import <AppKit/AppKit.h>
#endif

#import <RestKit/RestKit.h>
#import <RoutingHTTPServer/RoutingHTTPServer.h>
#import <RestKit+Blocks/RKObjectManager+Blocks.h>

#import "IAAction.h"
#import "IACapability.h"
#import "IADevice.h"
#import "IALogging.h"
#import "IARouteRequest+BodyAsString.h"
#import "IARouteResponse+Serializer.h"
#import "IAServer.h"
#import "IARoute.h"
#import "IAResponse.h"
#import "IARoutingHTTPServerAdapter.h"
#import "SDServiceDiscovery.h"

// Log levels: off, error, warn, info, verbose
// Other flags: trace
static const int intAirActLogLevel = IA_LOG_LEVEL_WARN; // | IA_LOG_FLAG_TRACE

@interface IAIntAirAct ()

@property (nonatomic) dispatch_queue_t clientQueue;
@property (nonatomic, strong) NSMutableDictionary * deviceDictionary;
@property (nonatomic, strong) NSMutableDictionary * objectManagers;
@property (nonatomic) dispatch_queue_t serverQueue;
@property (strong) NSObject<IAServer> * server;
@property (strong) RoutingHTTPServer * httpServer;
@property (strong) SDServiceDiscovery * serviceDiscovery;

@end

@implementation IAIntAirAct

@synthesize isRunning = _isRunning;
@synthesize ownDevice = _ownDevice;

- (id)init
{
    self = [super init];
    if (self) {
        @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"-init is not a valid initializer for the class IAIntAirAct" userInfo:nil];
    }
    return self;
}

-(id)initWithServer:(NSObject<IAServer> *)server
{
    self = [super init];
    if (self) {
        IALogTrace();
        
        _capabilities = [NSMutableSet new];
        _isRunning = NO;
        _objectMappingProvider = [RKObjectMappingProvider new];
        _router = [RKObjectRouter new];
        
        _clientQueue = dispatch_queue_create("IntAirActClient", NULL);
        _deviceDictionary = [NSMutableDictionary new];
        _objectManagers = [NSMutableDictionary new];
        _serverQueue = dispatch_queue_create("IntAirActServer", NULL);
        _serviceDiscovery = [[SDServiceDiscovery alloc] initWithQueue:_serverQueue];
        
        [self setupMappingsAndRoutes];
        

#if TARGET_OS_IPHONE
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive) name:UIApplicationDidBecomeActiveNotification object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(stop) name:UIApplicationWillResignActiveNotification object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(stop) name:UIApplicationWillTerminateNotification object:nil];
#endif
    }
    return self;
}

-(void)dealloc
{
    IALogTrace();
    
	[self stop];
    
    dispatch_release(_serverQueue);
    dispatch_release(_clientQueue);
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

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
            [self.serviceDiscovery searchForServicesOfType:@"_intairact._tcp"];
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
    
    dispatch_sync(self.serverQueue, ^{ @autoreleasepool {
        [self.serviceDiscovery stop];
        [_deviceDictionary removeAllObjects];
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:IADeviceUpdate object:nil];
        });
        _ownDevice = nil;
        _isRunning = NO;
    }});
}

-(BOOL)isRunning
{
	__block BOOL result;
	
	dispatch_sync(_serverQueue, ^{
		result = _isRunning;
	});
	
	return result;
}

-(void)netServiceBrowser:(NSNetServiceBrowser *)sender
        didRemoveService:(NSNetService *)ns
              moreComing:(BOOL)moreServicesComing
{
    IALogTrace2(@"%@[%p]: Bonjour Service went away: domain(%@) type(%@) name(%@)", THIS_FILE, self, [ns domain], [ns type], [ns name]);
    [_deviceDictionary removeObjectForKey:ns.name];
    [[NSNotificationCenter defaultCenter] postNotificationName:IADeviceUpdate object:self];
}

-(void)netServiceDidResolveAddress:(NSNetService *)sender
{
	IALogTrace2(@"%@[%p]: Bonjour Service resolved: %@:%"FMTNSINT, THIS_FILE, self, [sender hostName], [sender port]);
    
#warning re-implement using ServiceDiscovery module
    if ([self.httpServer.publishedName isEqualToString:sender.name]) {
        IALogTrace3(@"Found own device");
        IADevice * device = [IADevice deviceWithName:sender.name host:sender.hostName port:sender.port capabilities:self.capabilities];
        _ownDevice = device;
        [_deviceDictionary setObject:device forKey:device.name];
        [[NSNotificationCenter defaultCenter] postNotificationName:IADeviceUpdate object:self];
    } else {
        IALogTrace3(@"Found other device");
        IADevice * device = [IADevice deviceWithName:sender.name host:sender.hostName port:sender.port capabilities:nil];
        [[self objectManagerForDevice:device] loadObjectsAtResourcePath:@"/capabilities" handler:^(NSArray * objects, NSError * error) {
            if (error) {
                IALogError(@"%@[%p]: Could not get device capabilities for device %@: %@", THIS_FILE, self, device, error);
            } else {
                IADevice * dev = [IADevice deviceWithName:sender.name host:sender.hostName port:sender.port capabilities:[NSSet setWithArray:objects]];
                [_deviceDictionary setObject:dev forKey:dev.name];
                
                [[NSNotificationCenter defaultCenter] postNotificationName:IADeviceUpdate object:self];
            }
        }];
    }
}


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
        for(IADevice * dev in [_deviceDictionary allValues]) {
            if([dev.capabilities containsObject:capability]) {
                [result addObject:dev];
            }
        }
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
        result = [_deviceDictionary allValues];
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

-(void)setupMappingsAndRoutes
{
    [self addMappingForClass:[IADevice class] withKeypath:@"devices" withAttributes:@"name", @"host", @"port", nil];
    [self addMappingForClass:[IACapability class] withKeypath:@"capabilities" withAttributes:@"capability", nil];
    
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
    
#warning reimplement using route, or remove action concept all together
    
    [self.httpServer put:[@"/action/" stringByAppendingString:actionName] withBlock:^(RouteRequest *request, RouteResponse *response) {
        IALogVerbose(@"%@", [@"PUT /action/" stringByAppendingString:actionName]);
        IALogTrace2(@"Request: %@", request.bodyAsString);
        
        RKObjectMappingResult * result = [self deserializeObject:[request body]];
        if(!result && [[result asObject] isKindOfClass:[IAAction class]]) {
            IALogError(@"%@[%p]: Could not parse request body: %@", THIS_FILE, self, [request bodyAsString]);
            response.statusCode = 500;
            return;
        }
        
        IAAction * action = [result asObject];
        if((signature.numberOfArguments - 2) != [action.parameters count]) {
            response.statusCode = 500;
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
        response.statusCode = 201;
        if (![returnType isEqualToString:@"v"]) {
            [invocation getReturnValue:&returnValue];
            action.parameters = [NSArray arrayWithObjects:returnValue, nil];
            [response respondWith:action withIntAirAct:self];
        }
    }];
    
    IACapability * cap = [IACapability new];
    cap.capability = [@"PUT /action/" stringByAppendingString:actionName];
    [self.capabilities addObject:cap];
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

-(void)setPort:(NSInteger)port
{
    self.server.port = port;
}

-(NSInteger)port
{
    return self.server.port;
}

-(BOOL)route:(IARoute *)route withHandler:(IARequestHandler)block
{
    return [self.server route:route withHandler:block];
}

@end
