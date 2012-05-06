#import "IAIntAirAct.h"

#import <RestKit/RestKit.h>
#import <RoutingHTTPServer/RoutingHTTPServer.h>
#import <RestKit+Blocks/RKObjectManager+Blocks.h>

#import "IAAction.h"
#import "IADevice.h"
#import "IALogging.h"
#import "IARouteRequest+BodyAsString.h"
#import "IARouteResponse+Serializer.h"

// Log levels: off, error, warn, info, verbose
// Other flags: trace
static const int intAirActLogLevel = IA_LOG_LEVEL_VERBOSE; // | IA_LOG_FLAG_TRACE;

@interface IAIntAirAct ()

@property (nonatomic) dispatch_queue_t clientQueue;
@property (strong) NSMutableDictionary * deviceList;
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

@synthesize client = _client;
@synthesize defaultMimeType = _defaultMimeType;
@synthesize httpServer = _httpServer;
@synthesize isRunning = _isRunning;
@synthesize objectMappingProvider = _objectMappingProvider;
@synthesize ownDevice = _ownDevice;
@synthesize router = _router;
@synthesize server = _server;
@synthesize serverQueue = _serverQueue;

@synthesize clientQueue = _clientQueue;
@synthesize deviceList = _deviceList;
@synthesize isSetup = _isSetup;
@synthesize netServiceBrowser = _netServiceBrowser;
@synthesize objectManagers = _objectManagers;
@synthesize services = _services;

-(id)init
{
    self = [super init];
    if (self) {
        IALogTrace();
        
        _serverQueue = dispatch_queue_create("IntAirActServer", NULL);
        _clientQueue = dispatch_queue_create("IntAirActClient", NULL);
        
        _objectMappingProvider = [RKObjectMappingProvider new];
        _router = [RKObjectRouter new];
        
        self.deviceList = [NSMutableDictionary new];
        self.defaultMimeType = RKMIMETypeJSON;
        self.objectManagers = [NSMutableDictionary new];
        self.services = [NSMutableSet new];
        
        _server = YES;
        _client = YES;
        _isRunning = NO;
        _isSetup = NO;
    }
    return self;
}

-(void)dealloc
{
    IALogTrace();
    
	[self stop];
    
    dispatch_release(_serverQueue);
    dispatch_release(_clientQueue);
}

-(BOOL)start:(NSError **)errPtr;
{
    IALogTrace();
    
    __block BOOL success = YES;
	__block NSError *err = nil;
    
    dispatch_sync(_serverQueue, ^{ @autoreleasepool {
        [self setup];
        if(_server) {
            success = [_httpServer start:&err];
            if (success) {
                IALogInfo(@"%@: Started IntAirActServer.", THIS_FILE);
                
                if(_client) {
                    [self startBonjour];
                }
                _isRunning = YES;
            } else {
                IALogError(@"%@: Failed to start IntAirActServer: %@", THIS_FILE, err);
            }
        } else if (_client) {
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
    
    dispatch_sync(_serverQueue, ^{ @autoreleasepool {
        [_httpServer stop];
        [_netServiceBrowser stop];
        [_services removeAllObjects];
        [_deviceList removeAllObjects];
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

-(BOOL)server
{
    __block BOOL result;
	
	dispatch_sync(_serverQueue, ^{
		result = _server;
	});
	
	return result;
}

-(void)setServer:(BOOL)value
{
    IALogTrace();
    
    dispatch_async(_serverQueue, ^{
        _server = value;
    });
}

-(BOOL)client
{
    __block BOOL result;
	
	dispatch_sync(_serverQueue, ^{
		result = _client;
	});
	
	return result;
}

-(void)setClient:(BOOL)value
{
    IALogTrace();
    
    dispatch_async(_serverQueue, ^{
        _client = value;
    });
}

-(NSString *)defaultMimeType
{
    __block NSString * result;
	
	dispatch_sync(_serverQueue, ^{
		result = _defaultMimeType;
	});
	
	return result;
}

-(void)setDefaultMimeType:(NSString *)value
{
    IALogTrace();
    
    dispatch_async(_serverQueue, ^{
        _defaultMimeType = value;
    });
}

-(void)startBonjour
{
	IALogTrace();
	
	NSAssert(dispatch_get_current_queue() == _serverQueue, @"Invalid queue");
	
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
	
	NSAssert(dispatch_get_current_queue() == _serverQueue, @"Invalid queue");
	
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
    [self.deviceList removeObjectForKey:ns];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:IADeviceUpdate object:self];
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
        _ownDevice = device;
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:IADeviceUpdate object:self];
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
        result = [self.deviceList allValues];
	});
	
	return result;
}

-(void)callAction:(IAAction *)action onDevice:(IADevice *)device
{
    dispatch_async(_clientQueue, ^{
        RKObjectManager * manager = [self objectManagerForDevice:device];
        [manager putObject:action delegate:nil];
    });
}

-(void)callAction:(IAAction *)action onDevice:(IADevice *)device withHandler:(void (^)(IAAction * action, NSError * error))handler
{
    dispatch_async(_clientQueue, ^{
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
    if(_isSetup) {
        return;
    }

    if(_server) {
        if(!_httpServer) {
            _httpServer = [RoutingHTTPServer new];
        }
        
        // Tell the server to broadcast its presence via Bonjour.
        // This allows browsers such as Safari to automatically discover our service.
        [_httpServer setType:@"_intairact._tcp."];
        
        // Normally there's no need to run our server on any specific port.
        // Technologies like Bonjour allow clients to dynamically discover the server's port at runtime.
        // However, for easy testing you may want force a certain port so you can just hit the refresh button.
        [_httpServer setPort:12345];
        
        [_httpServer setDefaultHeader:@"Content-Type" value:_defaultMimeType];
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
    
    _isSetup = YES;
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
        manager.acceptMIMEType = _defaultMimeType;
        manager.serializationMIMEType = _defaultMimeType;
        
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
	
	dispatch_sync(_serverQueue, ^{
        if(!_httpServer) {
            _httpServer = [RoutingHTTPServer new];
        }
        result = _httpServer;
	});
	
	return result;
}

-(RKObjectSerializer *)serializerForObject:(id)object
{
    RKObjectMapping * mapping = [self.objectMappingProvider serializationMappingForClass:[object class]];
    return [RKObjectSerializer serializerWithObject:object mapping:mapping];
}

-(void)addAction:(NSString *)action withSelector:(SEL)selector andTarget:(id)target
{
    NSMethodSignature * signature = [[target class] instanceMethodSignatureForSelector:selector];
    __block NSInvocation * invocation = [NSInvocation invocationWithMethodSignature:signature];
    [invocation setSelector:selector];
    [invocation setTarget:target];
    
    NSString * returnType = [NSString stringWithFormat:@"%s", [[invocation methodSignature] methodReturnType]];
    
    // keep this here because otherwise we run into a memory release issue
    __block id returnValue;
    
    [self.httpServer put:[@"/action/" stringByAppendingString:action] withBlock:^(RouteRequest *request, RouteResponse *response) {
        IALogVerbose(@"%@", [@"PUT /action/" stringByAppendingString:action]);
        IALogTrace2(@"Request: %@", request.bodyAsString);
        
        RKObjectMappingResult * result = [self deserializeObject:[request body]];
        if(!result && [[result asObject] isKindOfClass:[IAAction class]]) {
            IALogError(@"Could not parse request body: %@", [request bodyAsString]);
            response.statusCode = 500;
            return;
        }
        
        IAAction * req = [result asObject];
        if((signature.numberOfArguments - 2) != [req.parameters count]) {
            response.statusCode = 500;
            return;
        }
        
        int i = 0;
        while (i < [req.parameters count]) {
            id obj = [req.parameters objectAtIndex:i];
            if(![self isNativeObject:obj]) {
                obj = [[self deserializeObject:obj] asObject];
            }
            [invocation setArgument:&obj atIndex:i+2];
            i++;
        }
        [invocation invoke];
        if (![returnType isEqualToString:@"v"]) {
            [invocation getReturnValue:&returnValue];
            IAAction * returnAction = [IAAction new];
            returnAction.action = @"";
            returnAction.parameters = [NSArray arrayWithObjects:returnValue, nil];
            response.statusCode = 201;
            [response respondWith:returnAction withIntAirAct:self];
        }
    }];
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
