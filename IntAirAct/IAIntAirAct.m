#import "IAIntAirAct.h"

#import <RestKit/RestKit.h>
#import <RoutingHTTPServer/RoutingHTTPServer.h>
#import <RestKit+Blocks/RKObjectManager+Blocks.h>

#import "IAAction.h"
#import "IADevice.h"
#import "IALogging.h"

// Log levels: off, error, warn, info, verbose
// Other flags: trace
static const int intAirActLogLevel = IA_LOG_LEVEL_INFO; // | IA_LOG_FLAG_TRACE;

@interface IAIntAirAct () {
    dispatch_queue_t serverQueue;
    dispatch_queue_t clientQueue;
    
    NSString * defaultMimeType;
    
    RoutingHTTPServer * httpServer;
    
    IADevice * ownDevice;
    
    BOOL isServer;
    BOOL isClient;
    BOOL isRunning;
    BOOL didSetup;
}

@property (strong) NSMutableDictionary * deviceList;
@property (nonatomic, strong) NSNetServiceBrowser * netServiceBrowser;
@property (nonatomic, strong) NSMutableDictionary * objectManagers;
@property (strong) NSMutableSet * services;

-(void)startBonjour;
-(void)stopBonjour;

+(void)startBonjourThreadIfNeeded;
+(void)performBonjourBlock:(dispatch_block_t)block;

@end

@implementation IAIntAirAct

@synthesize objectMappingProvider = _objectMappingProvider;
@synthesize router = _router;

@synthesize deviceList = _deviceList;
@synthesize netServiceBrowser = _netServiceBrowser;
@synthesize objectManagers = _objectManagers;
@synthesize services = _services;

-(id)init
{
    self = [super init];
    if (self) {
        IALogTrace();
        
        serverQueue = dispatch_queue_create("IntAirActServer", NULL);
        clientQueue = dispatch_queue_create("IntAirActClient", NULL);
        
        _objectMappingProvider = [RKObjectMappingProvider new];
        _router = [RKObjectRouter new];
        
        self.deviceList = [NSMutableDictionary new];
        self.defaultMimeType = RKMIMETypeJSON;
        self.objectManagers = [NSMutableDictionary new];
        self.services = [NSMutableSet new];
        
        isServer = YES;
        isClient = YES;
        isRunning = NO;
        didSetup = NO;
    }
    return self;
}

-(void)dealloc
{
    IALogTrace();
    
	[self stop];
    
    dispatch_release(serverQueue);
    dispatch_release(clientQueue);
}

-(BOOL)start:(NSError **)errPtr;
{
    IALogTrace();
    
    __block BOOL success = YES;
	__block NSError *err = nil;
    
    dispatch_sync(serverQueue, ^{ @autoreleasepool {
        [self setup];
        if(isServer) {
            success = [httpServer start:&err];
            if (success) {
                IALogInfo(@"%@: Started IntAirActServer.", THIS_FILE);
                
                if(isClient) {
                    [self startBonjour];
                }
                isRunning = YES;
            } else {
                IALogError(@"%@: Failed to start IntAirActServer: %@", THIS_FILE, err);
            }
        } else if (isClient) {
            IALogInfo(@"%@: Started IntAirActServer.", THIS_FILE);
            [self startBonjour];
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
        [_netServiceBrowser stop];
        [_services removeAllObjects];
        [_deviceList removeAllObjects];
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:@"DeviceUpdate" object:nil];
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
		result = isServer;
	});
	
	return result;
}

-(void)setServer:(BOOL)value
{
    IALogTrace();
    
    dispatch_async(serverQueue, ^{
        isServer = value;
    });
}

-(BOOL)client
{
    __block BOOL result;
	
	dispatch_sync(serverQueue, ^{
		result = isClient;
	});
	
	return result;
}

-(void)setClient:(BOOL)value
{
    IALogTrace();
    
    dispatch_async(serverQueue, ^{
        isClient = value;
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
    [self.deviceList removeObjectForKey:ns.name];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"DeviceUpdate" object:self];
}

-(void)netServiceBrowserDidStopSearch:(NSNetServiceBrowser *)sender
{
    IALogTrace();
}

-(void)netService:(NSNetService *)ns didNotResolve:(NSDictionary *)errorDict
{
    IALogWarn(@"Could not resolve Bonjour Service: domain(%@) type(%@) name(%@)", [ns domain], [ns type], [ns name]);

    [self.services removeObject:ns];
    [self.deviceList removeObjectForKey:ns];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"DeviceUpdate" object:self];
}

-(void)netServiceDidResolveAddress:(NSNetService *)sender
{
	IALogTrace2(@"Bonjour Service resolved: %@:%i", [sender hostName], [sender port]);

    IADevice * device = [IADevice new];
    device.name = sender.name;
    device.host = sender.hostName;
    device.port = sender.port;
    [self.deviceList setObject:device forKey:device.name];
    if ([self.httpServer.publishedName isEqual:device.name]) {
        ownDevice = device;
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"DeviceUpdate" object:self];
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

-(RKObjectMappingResult*)deserializeObject:(NSData*)data
{
    IALogTrace();
    
    NSString * bodyAsString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
    NSError* error = nil;
    id<RKParser> parser = [[RKParserRegistry sharedRegistry] parserForMIMEType:self.defaultMimeType];
    id parsedData = [parser objectFromString:bodyAsString error:&error];
    
    if (parsedData == nil && error) {
        // Parser error...
        IALogError(@"%@: An error ocurred: %@", THIS_FILE, error);
        return nil;
    } else {
        RKObjectMapper* mapper = [RKObjectMapper mapperWithObject:parsedData mappingProvider:self.objectMappingProvider];
        return [mapper performMapping];
    }
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
        result = [self.deviceList allValues];
	});
	
	return result;
}

-(void)callAction:(IAAction *)action onDevice:(IADevice *)device
{
    dispatch_async(clientQueue, ^{
        RKObjectManager * manager = [self objectManagerForDevice:device];
        [manager putObject:action delegate:nil];
    });
}

-(void)callAction:(IAAction *)action onDevice:(IADevice *)device withHandler:(void (^)(IAAction * action, NSError * error))handler
{
    dispatch_async(clientQueue, ^{
        RKObjectManager * manager = [self objectManagerForDevice:device];
        [manager putObject:action handler:^(RKObjectLoader * loader, NSError * error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                handler(action, error);
            });
        }];
        
    });
}

-(void)setup
{
    if(didSetup) {
        return;
    }

    if(isServer) {
        if(!httpServer) {
            httpServer = [RoutingHTTPServer new];
        }
        
        // Tell the server to broadcast its presence via Bonjour.
        // This allows browsers such as Safari to automatically discover our service.
        [httpServer setType:@"_intairact._tcp."];
        
        // Normally there's no need to run our server on any specific port.
        // Technologies like Bonjour allow clients to dynamically discover the server's port at runtime.
        // However, for easy testing you may want force a certain port so you can just hit the refresh button.
        //[_httpServer setPort:12345];
        
        [httpServer setDefaultHeader:@"Content-Type" value:defaultMimeType];
    }
    
    RKObjectMapping * deviceMapping = [RKObjectMapping mappingForClass:[IADevice class]];
    [deviceMapping mapAttributes:@"name", @"host", @"port", nil];
    [_objectMappingProvider setMapping:deviceMapping forKeyPath:@"devices"];
    
    RKObjectMapping * deviceSerialization = [deviceMapping inverseMapping];
    deviceSerialization.rootKeyPath = @"devices";
    [_objectMappingProvider setSerializationMapping:deviceSerialization forClass:[IADevice class]];
    
    RKObjectMapping * actionSerialization = [RKObjectMapping mappingForClass:[NSDictionary class]];
    actionSerialization.rootKeyPath = @"actions";
    [actionSerialization mapAttributes:@"action", nil];
    RKDynamicObjectMapping * parametersSerialization = [RKDynamicObjectMapping dynamicMappingUsingBlock:^(RKDynamicObjectMapping *dynamicMapping) {
        dynamicMapping.objectMappingForDataBlock = ^ RKObjectMapping* (id mappableData) {
            RKObjectMapping * mapping = [RKObjectMapping mappingForClass:[NSMutableDictionary class]];
            for(NSString * parameterName in [mappableData allKeys]) {
                id value = [mappableData valueForKey:parameterName];
                RKObjectMapping * serializationMapping = [self.objectMappingProvider serializationMappingForClass:[value class]];
                if(serializationMapping) {
                    [mapping mapKeyPath:parameterName toRelationship:[serializationMapping.rootKeyPath stringByAppendingFormat:@"-%@", parameterName] withMapping:serializationMapping];
                } else {
                    [mapping mapAttributes:parameterName, nil];
                }
            }
            return mapping;
        };
    }];
    [actionSerialization hasMany:@"parameters" withMapping:parametersSerialization];
    [_objectMappingProvider setSerializationMapping:actionSerialization forClass:[IAAction class]];
    
    RKObjectMapping * actionMapping = [RKObjectMapping mappingForClass:[IAAction class]];
    [actionMapping mapAttributes:@"action", nil];
    RKDynamicObjectMapping * parametersMapping = [RKDynamicObjectMapping dynamicMappingUsingBlock:^(RKDynamicObjectMapping *dynamicMapping) {
        dynamicMapping.objectMappingForDataBlock = ^ RKObjectMapping* (id mappableData) {
            NSDictionary * allRegisteredMappings = [self.objectMappingProvider mappingsByKeyPath];
            RKObjectMapping * mapping = [RKObjectMapping mappingForClass:[NSMutableDictionary class]];
            for(NSString * key in [mappableData allKeys]) {
                NSArray * keyComponents = [key componentsSeparatedByString:@"-"];
                if([keyComponents count] == 2) {
                    NSString * rootKeyPath = [keyComponents objectAtIndex:0];
                    if (!rootKeyPath) {
                        continue;
                    }
                    NSString * parameterName = [keyComponents objectAtIndex:1];
                    if (!parameterName) {
                        continue;
                    }
                    RKObjectMapping * originalMapping = [allRegisteredMappings valueForKey:rootKeyPath];
                    if(!originalMapping) {
                        continue;
                    }
                    [mapping mapKeyPath:key toRelationship:parameterName withMapping:originalMapping];
                } else {
                    [mapping mapAttributes:key, nil];
                }
            }
            return mapping;
        };
    }];
    [actionMapping hasMany:@"parameters" withMapping:parametersMapping];
    [_objectMappingProvider setMapping:actionMapping forKeyPath:@"actions"];
    
    [_router routeClass:[IAAction class] toResourcePath:@"/action/:action" forMethod:RKRequestMethodPUT];
    
    didSetup = YES;
}

-(RKObjectManager *)objectManagerForDevice:(IADevice *)device
{
    IALogTrace();
    
    NSString * hostAndPort = device.hostAndPort;
    if ([device isEqual:self.ownDevice]) {
        hostAndPort = [NSString stringWithFormat:@"http://127.0.0.1:%i" , device.port];
    }
    RKObjectManager * manager = [_objectManagers objectForKey:hostAndPort];
    
    if(!manager) {
        manager = [[RKObjectManager alloc] initWithBaseURL:[RKURL URLWithBaseURLString:hostAndPort]];
        
        // Ask for & generate JSON
        manager.acceptMIMEType = defaultMimeType;
        manager.serializationMIMEType = defaultMimeType;
        
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

@end
