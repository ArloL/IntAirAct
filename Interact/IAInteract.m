#import "IAInteract.h"

#import <RestKit/RestKit.h>
#import <RoutingHTTPServer/RoutingHTTPServer.h>
#import <RestKit+Blocks/RKObjectManager+Blocks.h>

#import "IAAction.h"
#import "IADevice.h"
#import "IALocator.h"
#import "IALogging.h"

// Log levels: off, error, warn, info, verbose
// Other flags: trace
static const int interactLogLevel = IA_LOG_LEVEL_INFO; // | IA_LOG_FLAG_TRACE;

@interface IAInteract () {
    dispatch_queue_t serverQueue;
    dispatch_queue_t clientQueue;
    
    NSString * defaultMimeType;
    
    BOOL isServer;
    BOOL isClient;
    BOOL isRunning;
}

@property (strong) NSMutableDictionary * deviceList;
@property (nonatomic, strong) NSNetServiceBrowser * netServiceBrowser;
@property (nonatomic, strong) NSMutableDictionary * objectManagers;
@property (nonatomic, strong) IALocator * privLocator;
@property (strong) IADevice * selfDevice;
@property (strong) NSMutableSet * services;

-(void)startBonjour;
-(void)stopBonjour;

+(void)startBonjourThreadIfNeeded;
+(void)performBonjourBlock:(dispatch_block_t)block;

@end

@implementation IAInteract

@synthesize httpServer = _httpServer;
@synthesize objectMappingProvider = _objectMappingProvider;
@synthesize router = _router;

@synthesize deviceList = _deviceList;
@synthesize privLocator = _privLocator;
@synthesize netServiceBrowser = _netServiceBrowser;
@synthesize objectManagers = _objectManagers;
@synthesize selfDevice = _selfDevice;
@synthesize services = _services;

/**
 * Standard Constructor.
 * Instantiates Interact, but does not start it.
 **/
-(id)init
{
    self = [super init];
    if (self) {
        IALogTrace();
        
        serverQueue = dispatch_queue_create("InteractServer", NULL);
        clientQueue = dispatch_queue_create("InteractClient", NULL);

        self.objectMappingProvider = [RKObjectMappingProvider new];
        self.router = [RKObjectRouter new];
        
        self.deviceList = [NSMutableDictionary new];
        self.defaultMimeType = RKMIMETypeJSON;
        self.objectManagers = [NSMutableDictionary new];
        self.privLocator = [IALocator new];
        self.services = [NSMutableSet new];
        
        [self setup];
        
        isServer = YES;
        isClient = YES;
        isRunning = NO;
    }
    return self;
}

/**
 * Standard Deconstructor.
 * Stops the server, and clients, and releases any resources connected with this instance.
 **/
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
        
        if(isServer) {
            success = [self.httpServer start:&err];
            if (success) {
                IALogInfo(@"%@: Started Interact.", THIS_FILE);
                
                if(isClient) {
                    [self.locator startTracking];
                    [self startBonjour];
                }
                isRunning = YES;
            } else {
                IALogError(@"%@: Failed to start Interact: %@", THIS_FILE, err);
            }
        } else if (isClient) {
            IALogInfo(@"%@: Started Interact.", THIS_FILE);
            [self.locator startTracking];
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
        
        [self.httpServer stop];
        [self.netServiceBrowser stop];
        [self.services removeAllObjects];
        self.selfDevice = nil;
        
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
        [theNetServiceBrowser searchForServicesOfType:@"_interact._tcp." inDomain:@"local."];
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
    device.hostAndPort = [NSString stringWithFormat:@"http://%@:%i/", sender.hostName, sender.port];
    [self.deviceList setObject:device forKey:device.name];
    if ([self.httpServer.publishedName isEqual:device.name]) {
        self.selfDevice = device;
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
        return [self deserializeDictionary:parsedData];
    }
}

-(RKObjectMappingResult*)deserializeDictionary:(NSDictionary*)dictionary
{
    IALogTrace();
    
    RKObjectMapper* mapper = [RKObjectMapper mapperWithObject:dictionary mappingProvider:self.objectMappingProvider];
    return [mapper performMapping];
}

-(IADevice *)ownDevice
{
    return self.selfDevice;
}

-(NSArray *)devices
{
    return [self.deviceList allValues];
}

-(IALocator *)locator
{
    return self.privLocator;
}

-(void)callAction:(IAAction *)action onDevice:(IADevice *)device
{
    dispatch_async(clientQueue, ^{
        RKObjectManager * manager = [self objectManagerForDevice:device];
        [manager putObject:action delegate:nil];
    });
}

-(void)loadObjectsAtResourcePath:(NSString *)resourcePath fromDevice:(IADevice *)device handler:(void (^)(RKObjectLoader *, NSError *))handler
{
    dispatch_async(clientQueue, ^{
        RKObjectManager * manager = [self objectManagerForDevice:device];
        [manager loadObjectsAtResourcePath:@"/images" handler:handler];
    });
}

-(void)setup
{
    [self.httpServer setDefaultHeader:@"Content-Type" value:self.defaultMimeType];
    
    RKObjectMapping * deviceMapping = [RKObjectMapping mappingForClass:[IADevice class]];
    [deviceMapping mapAttributes:@"name", @"hostAndPort", nil];
    [self.objectMappingProvider setMapping:deviceMapping forKeyPath:@"devices"];
    
    RKObjectMapping * deviceSerialization = [deviceMapping inverseMapping];
    deviceSerialization.rootKeyPath = @"devices";
    [self.objectMappingProvider setSerializationMapping:deviceSerialization forClass:[IADevice class]];
    
    RKObjectMapping * actionSerialization = [RKObjectMapping mappingForClass:[NSDictionary class]];
    actionSerialization.rootKeyPath = @"actions";
    [actionSerialization mapAttributes:@"action", nil];
    RKDynamicObjectMapping * parametersSerialization = [RKDynamicObjectMapping dynamicMappingUsingBlock:^(RKDynamicObjectMapping *dynamicMapping) {
        dynamicMapping.objectMappingForDataBlock = ^ RKObjectMapping* (id mappableData) {
            RKObjectMapping * mapping = [RKObjectMapping mappingForClass:[NSMutableDictionary class]];
            for(NSString * parameterName in [mappableData allKeys]) {
                id value = [mappableData valueForKey:parameterName];
                RKObjectMapping * serializationMapping = [self.objectMappingProvider serializationMappingForClass:[value class]];
                [mapping mapKeyPath:parameterName toRelationship:[serializationMapping.rootKeyPath stringByAppendingFormat:@"-%@", parameterName] withMapping:serializationMapping];
            }
            return mapping;
        };
    }];
    [actionSerialization hasMany:@"parameters" withMapping:parametersSerialization];
    [self.objectMappingProvider setSerializationMapping:actionSerialization forClass:[IAAction class]];
    
    RKObjectMapping * actionMapping = [RKObjectMapping mappingForClass:[IAAction class]];
    [actionMapping mapAttributes:@"action", nil];
    RKDynamicObjectMapping * parametersMapping = [RKDynamicObjectMapping dynamicMappingUsingBlock:^(RKDynamicObjectMapping *dynamicMapping) {
        dynamicMapping.objectMappingForDataBlock = ^ RKObjectMapping* (id mappableData) {
            NSDictionary * allRegisteredMappings = [self.objectMappingProvider mappingsByKeyPath];
            RKObjectMapping * mapping = [RKObjectMapping mappingForClass:[NSMutableDictionary class]];
            for(NSString * key in [mappableData allKeys]) {
                NSArray * keyComponents = [key componentsSeparatedByString:@"-"];
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
            }
            return mapping;
        };
    }];
    [actionMapping hasMany:@"parameters" withMapping:parametersMapping];
    [self.objectMappingProvider setMapping:actionMapping forKeyPath:@"actions"];
    
    [self.router routeClass:[IAAction class] toResourcePath:@"/action/:action" forMethod:RKRequestMethodPUT];
}

-(RKObjectManager *)objectManagerForDevice:(IADevice *)device
{
    IALogTrace();
    
    RKObjectManager * manager = [self.objectManagers objectForKey:device.hostAndPort];
    
    if(!manager) {
        manager = [[RKObjectManager alloc] initWithBaseURL:[RKURL URLWithBaseURLString:device.hostAndPort]];
        
        // Ask for & generate JSON
        manager.acceptMIMEType = self.defaultMimeType;
        manager.serializationMIMEType = self.defaultMimeType;
        
        manager.mappingProvider = self.objectMappingProvider;
        
        // Register the router
        manager.router = self.router;
        
        [self.objectManagers setObject:manager forKey:device.hostAndPort];
        
        return manager;
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
    IALogTrace();
    
    if(!_httpServer) {
        _httpServer = [RoutingHTTPServer new];
        
        // Tell server to use our custom MyHTTPConnection class.
        // [httpServer setConnectionClass:[RESTConnection class]];
        
        // Tell the server to broadcast its presence via Bonjour.
        // This allows browsers such as Safari to automatically discover our service.
        [_httpServer setType:@"_interact._tcp."];
        
        // Normally there's no need to run our server on any specific port.
        // Technologies like Bonjour allow clients to dynamically discover the server's port at runtime.
        // However, for easy testing you may want force a certain port so you can just hit the refresh button.
        //[_httpServer setPort:12345];
        
        // Serve files from our embedded Web folder
        NSString *webPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"Web"];
        IALogTrace2(@"%@: Setting document root: %@", THIS_FILE, webPath);
        
        [_httpServer setDocumentRoot:webPath];
    }
    return _httpServer;
}

-(RKObjectSerializer *)serializerForObject:(id)object
{
    RKObjectMapping * mapping = [self.objectMappingProvider serializationMappingForClass:[object class]];
    return [RKObjectSerializer serializerWithObject:object mapping:mapping];
}

@end
