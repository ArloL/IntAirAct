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

// Log levels: off, error, warn, info, verbose
// Other flags: trace
static const int intAirActLogLevel = IA_LOG_LEVEL_WARN; // | IA_LOG_FLAG_TRACE;

@interface IAIntAirAct ()

@property (nonatomic) dispatch_queue_t clientQueue;
@property (nonatomic, strong) NSMutableDictionary * deviceDictionary;
@property (nonatomic) BOOL isSetup;
@property (nonatomic, strong) NSNetServiceBrowser * netServiceBrowser;
@property (nonatomic, strong) NSMutableDictionary * objectManagers;
@property (nonatomic) dispatch_queue_t serverQueue;
@property (strong) NSMutableSet * services;

-(void)startBonjour;
-(void)stopBonjour;

+(void)startBonjourThreadIfNeeded;
+(void)performBonjourBlock:(dispatch_block_t)block;

@end

@implementation IAIntAirAct

@synthesize capabilities;
@synthesize client;
@synthesize defaultMimeType;
@synthesize devices;
@synthesize httpServer;
@synthesize isRunning;
@synthesize objectMappingProvider;
@synthesize ownDevice;
@synthesize router;
@synthesize server;
@synthesize txtRecordDictionary;

@synthesize clientQueue;
@synthesize deviceDictionary;
@synthesize isSetup;
@synthesize netServiceBrowser;
@synthesize objectManagers;
@synthesize serverQueue;
@synthesize services;

-(id)init
{
    self = [super init];
    if (self) {
        IALogTrace();
        
        capabilities = [NSMutableSet new];
        client = YES;
        defaultMimeType = RKMIMETypeJSON;
        isRunning = NO;
        objectMappingProvider = [RKObjectMappingProvider new];
        router = [RKObjectRouter new];
        server = YES;
        txtRecordDictionary = [NSMutableDictionary new];
        
        clientQueue = dispatch_queue_create("IntAirActClient", NULL);
        deviceDictionary = [NSMutableDictionary new];
        isSetup = NO;
        objectManagers = [NSMutableDictionary new];
        serverQueue = dispatch_queue_create("IntAirActServer", NULL);
        services = [NSMutableSet new];
        

#if TARGET_OS_IPHONE
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive) name:UIApplicationDidBecomeActiveNotification object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(stop) name:UIApplicationWillResignActiveNotification object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(stop) name:UIApplicationWillTerminateNotification object:nil];
#else
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive) name:NSApplicationDidBecomeActiveNotification object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(stop) name:NSApplicationWillTerminateNotification object:nil];
#endif
    }
    return self;
}

-(void)dealloc
{
    IALogTrace();
    
	[self stop];
    
    dispatch_release(serverQueue);
    dispatch_release(clientQueue);
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void)applicationDidBecomeActive
{
    NSError * error;
    if(![self start:&error]) {
        IALogError(@"%@: Error starting IntAirAct: %@", THIS_FILE, error);
    }
}

-(BOOL)start:(NSError **)errPtr;
{
    IALogTrace();
    
    __block BOOL success = YES;
	__block NSError * err = nil;
    
    if(isRunning) {
        return success;
    }
    
    dispatch_sync(serverQueue, ^{ @autoreleasepool {
        [self setup];
        if(server) {
            success = [httpServer start:&err];
            if (success) {
                IALogInfo(@"%@: Started IntAirActServer.", THIS_FILE);
                
                if(client) {
                    [self startBonjour];
                }
                isRunning = YES;
            } else {
                IALogError(@"%@: Failed to start IntAirActServer: %@", THIS_FILE, err);
            }
        } else if (client) {
            IALogInfo(@"%@: Started IntAirActServer.", THIS_FILE);
            [self startBonjour];
            isRunning = YES;
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
    
    dispatch_sync(serverQueue, ^{ @autoreleasepool {
        [httpServer stop];
        [netServiceBrowser stop];
        [services removeAllObjects];
        [deviceDictionary removeAllObjects];
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:IADeviceUpdate object:nil];
        });
        ownDevice = nil;
        isRunning = NO;
    }});
}

-(BOOL)isRunning
{
	__block BOOL result;
	
	dispatch_sync(serverQueue, ^{
		result = isRunning;
	});
	
	return result;
}

-(BOOL)server
{
    __block BOOL result;
	
	dispatch_sync(serverQueue, ^{
		result = server;
	});
	
	return result;
}

-(void)setServer:(BOOL)value
{
    IALogTrace();
    
    dispatch_async(serverQueue, ^{
        server = value;
    });
}

-(BOOL)client
{
    __block BOOL result;
	
	dispatch_sync(serverQueue, ^{
		result = client;
	});
	
	return result;
}

-(void)setClient:(BOOL)value
{
    IALogTrace();
    
    dispatch_async(serverQueue, ^{
        client = value;
    });
}

-(NSString *)defaultMimeType
{
    __block NSString * result;
	
	dispatch_sync(serverQueue, ^{
		result = defaultMimeType;
	});
	
	return result;
}

-(void)setDefaultMimeType:(NSString *)value
{
    IALogTrace();
    
    dispatch_async(serverQueue, ^{
        defaultMimeType = value;
    });
}

-(void)startBonjour
{
	IALogTrace();
	
	NSAssert(dispatch_get_current_queue() == serverQueue, @"Invalid queue");
	
    self.netServiceBrowser = [NSNetServiceBrowser new];
    [self.netServiceBrowser setDelegate:self];
    
    NSNetServiceBrowser *theNetServiceBrowser = self.netServiceBrowser;
    
    dispatch_block_t bonjourBlock = ^{
        [theNetServiceBrowser removeFromRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
        [theNetServiceBrowser scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
        [theNetServiceBrowser searchForServicesOfType:@"_intairact._tcp." inDomain:@"local."];
        IALogInfo(@"Bonjour search started.");
    };
    
    [[self class] startBonjourThreadIfNeeded];
    [[self class] performBonjourBlock:bonjourBlock];
}

-(void)stopBonjour
{
	IALogTrace();
	
	NSAssert(dispatch_get_current_queue() == serverQueue, @"Invalid queue");
	
	if (self.netServiceBrowser)
	{
		NSNetServiceBrowser *theNetServiceBrowser = self.netServiceBrowser;
		
		dispatch_block_t bonjourBlock = ^{
			
			[theNetServiceBrowser stop];
		};
		
		[[self class] performBonjourBlock:bonjourBlock];
		
		self.netServiceBrowser = nil;
	}
}

-(void)netServiceBrowser:(NSNetServiceBrowser *)sender didNotSearch:(NSDictionary *)errorInfo
{
    IALogError(@"Bonjour could not search: %@", errorInfo);
}

-(void)netServiceBrowser:(NSNetServiceBrowser *)sender
          didFindService:(NSNetService *)ns
              moreComing:(BOOL)moreServicesComing
{
    IALogTrace2(@"Bonjour Service found: domain(%@) type(%@) name(%@)", [ns domain], [ns type], [ns name]);
    [self.services addObject:ns];
    [ns setDelegate:self];
    [ns resolveWithTimeout:0.0];
}

-(void)netServiceBrowser:(NSNetServiceBrowser *)sender
        didRemoveService:(NSNetService *)ns
              moreComing:(BOOL)moreServicesComing
{
    IALogTrace2(@"Bonjour Service went away: domain(%@) type(%@) name(%@)", [ns domain], [ns type], [ns name]);
    [self.services removeObject:ns];
    [deviceDictionary removeObjectForKey:ns.name];
    [[NSNotificationCenter defaultCenter] postNotificationName:IADeviceUpdate object:self];
}

-(void)netServiceBrowserDidStopSearch:(NSNetServiceBrowser *)sender
{
    IALogTrace();
}

-(void)netService:(NSNetService *)ns didNotResolve:(NSDictionary *)errorDict
{
    IALogWarn(@"Could not resolve Bonjour Service: domain(%@) type(%@) name(%@)", [ns domain], [ns type], [ns name]);

    [self.services removeObject:ns];
    [deviceDictionary removeObjectForKey:ns];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:IADeviceUpdate object:self];
}

-(void)netServiceDidResolveAddress:(NSNetService *)sender
{
	IALogTrace2(@"Bonjour Service resolved: %@:%i", [sender hostName], [sender port]);

    __block IADevice * device = [IADevice new];
    device.name = sender.name;
    device.host = sender.hostName;
    device.port = sender.port;
    
    [[self objectManagerForDevice:device] loadObjectsAtResourcePath:@"/capabilities" handler:^(RKObjectLoader *loader, NSError * error) {
        if (error) {
            IALogError(@"Could not get device capabilities for device %@: %@", device, error);
        } else {
            device.capabilities = [NSSet setWithArray:[[loader result] asCollection]];
            [deviceDictionary setObject:device forKey:device.name];
            if ([self.httpServer.publishedName isEqual:device.name]) {
                ownDevice = device;
            }
            [[NSNotificationCenter defaultCenter] postNotificationName:IADeviceUpdate object:self];
        }
    }];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Bonjour Thread
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 * NSNetService is runloop based, so it requires a thread with a runloop.
 * This gives us two options:
 * 
 * - Use the main thread
 * - Setup our own dedicated thread
 * 
 * Since we have various blocks of code that need to synchronously access the netservice objects,
 * using the main thread becomes troublesome and a potential for deadlock.
 **/

static NSThread *bonjourThread;

+ (void)startBonjourThreadIfNeeded
{
	IALogTrace();
	
	static dispatch_once_t predicate;
	dispatch_once(&predicate, ^{
		
		IALogVerbose(@"%@: Starting bonjour thread...", THIS_FILE);
		
		bonjourThread = [[NSThread alloc] initWithTarget:self
		                                        selector:@selector(bonjourThread)
		                                          object:nil];
		[bonjourThread start];
	});
}

+ (void)bonjourThread
{
	@autoreleasepool {
        
		IALogVerbose(@"%@: BonjourThread: Started", THIS_FILE);
		
		// We can't run the run loop unless it has an associated input source or a timer.
		// So we'll just create a timer that will never fire - unless the server runs for 10,000 years.
		
		[NSTimer scheduledTimerWithTimeInterval:[[NSDate distantFuture] timeIntervalSinceNow]
		                                 target:self
		                               selector:@selector(donothingatall:)
		                               userInfo:nil
		                                repeats:YES];
		
		[[NSRunLoop currentRunLoop] run];
		
		IALogVerbose(@"%@: BonjourThread: Aborted", THIS_FILE);
        
	}
}

+ (void)executeBonjourBlock:(dispatch_block_t)block
{
	IALogTrace();
	
	NSAssert([NSThread currentThread] == bonjourThread, @"Executed on incorrect thread");
	
	block();
}

+ (void)performBonjourBlock:(dispatch_block_t)block
{
	IALogTrace();
	
	[self performSelector:@selector(executeBonjourBlock:)
	             onThread:bonjourThread
	           withObject:block
	        waitUntilDone:YES];
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
        id<RKParser> parser = [[RKParserRegistry sharedRegistry] parserForMIMEType:self.defaultMimeType];
        parsedData = [parser objectFromString:bodyAsString error:&error];
    } else {
        parsedData = data;
    }
    
    if (parsedData == nil && error) {
        // Parser error...
        IALogError(@"%@: An error ocurred: %@", THIS_FILE, error);
        return nil;
    } else {
        RKObjectMapper* mapper = [RKObjectMapper mapperWithObject:parsedData mappingProvider:self.objectMappingProvider];
        return [mapper performMapping];
    }
}

-(NSArray *)devicesWithCapability:(IACapability *)capability
{
    __block NSMutableArray * result;
    
    IALogVerbose(@"%@", [deviceDictionary allValues]);
    
    dispatch_sync(serverQueue, ^{
        result = [NSMutableArray new];
        for(IADevice * dev in [deviceDictionary allValues]) {
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
	
	dispatch_sync(serverQueue, ^{
        result = ownDevice;
	});
	
	return result;
}

-(NSArray *)devices
{
    __block NSArray * result;
	
	dispatch_sync(serverQueue, ^{
        result = [deviceDictionary allValues];
	});
	
	return result;
}

-(void)callAction:(IAAction *)action onDevice:(IADevice *)device withHandler:(void (^)(IAAction * action, NSError * error))handler
{
    dispatch_async(clientQueue, ^{
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

-(void)setup
{
    if(isSetup) {
        return;
    }

    if(server) {
        [txtRecordDictionary setObject:@"1" forKey:@"version"];
        
        if(!httpServer) {
            httpServer = [RoutingHTTPServer new];
        }
        
        // Tell the server to broadcast its presence via ZeroConf.
        [httpServer setType:@"_intairact._tcp."];
        
        // Normally there's no need to run our server on any specific port.
        // Technologies like ZeroConf allow clients to dynamically discover the server's port at runtime.
        // However, for easy testing you may want force a certain port so you can just hit the refresh button.
        //[httpServer setPort:12345];
        
        [httpServer setTXTRecordDictionary:txtRecordDictionary];
        
        [httpServer setDefaultHeader:@"Content-Type" value:defaultMimeType];
        
        [httpServer get:@"/capabilities" withBlock:^(RouteRequest *request, RouteResponse *response) {
            IALogTrace();
            
            [response respondWith:self.capabilities withIntAirAct:self];
        }];
    }
    
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
    [objectMappingProvider setSerializationMapping:actionSerialization forClass:[IAAction class]];
    
    RKObjectMapping * actionMapping = [RKObjectMapping mappingForClass:[IAAction class]];
    [actionMapping mapAttributes:@"action", @"parameters", nil];
    [objectMappingProvider setMapping:actionMapping forKeyPath:@"actions"];
    
    [router routeClass:[IAAction class] toResourcePath:@"/action/:action" forMethod:RKRequestMethodPUT];
    
    isSetup = YES;
}

-(RKObjectManager *)objectManagerForDevice:(IADevice *)device
{
    IALogTrace();
    
    NSString * hostAndPort;
    if ([device isEqual:self.ownDevice]) {
        hostAndPort = [NSString stringWithFormat:@"http://127.0.0.1:%i" , device.port];
    } else {
        hostAndPort = [NSString stringWithFormat:@"http://%@:%i", device.host, device.port];
    }

    RKObjectManager * manager = [objectManagers objectForKey:hostAndPort];
    
    if(!manager) {
        manager = [[RKObjectManager alloc] initWithBaseURL:[RKURL URLWithBaseURLString:hostAndPort]];
        
        // Ask for & generate JSON
        manager.acceptMIMEType = defaultMimeType;
        manager.serializationMIMEType = defaultMimeType;
        
        manager.mappingProvider = objectMappingProvider;
        
        // Register the router
        manager.router = router;
        
        [objectManagers setObject:manager forKey:hostAndPort];
    }
    
    return manager;
}

-(NSString *)resourcePathFor:(NSObject *)resource forObjectManager:(RKObjectManager *)manager
{
    IALogTrace();
    return [manager.router resourcePathForObject:resource method:RKRequestMethodPUT];
}

-(RoutingHTTPServer *)httpServer
{
    __block RoutingHTTPServer * result;
	
	dispatch_sync(serverQueue, ^{
        if(!httpServer) {
            httpServer = [RoutingHTTPServer new];
        }
        result = httpServer;
	});
	
	return result;
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
    
    [self.httpServer put:[@"/action/" stringByAppendingString:actionName] withBlock:^(RouteRequest *request, RouteResponse *response) {
        IALogVerbose(@"%@", [@"PUT /action/" stringByAppendingString:actionName]);
        IALogTrace2(@"Request: %@", request.bodyAsString);
        
        RKObjectMappingResult * result = [self deserializeObject:[request body]];
        if(!result && [[result asObject] isKindOfClass:[IAAction class]]) {
            IALogError(@"Could not parse request body: %@", [request bodyAsString]);
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

@end
