#import "SDServiceDiscovery.h"

#if !(TARGET_OS_IPHONE)
    #import <AppKit/AppKit.h>
#endif

#import "IALogging.h"

// Log levels: off, error, warn, info, verbose
// Other flags: trace
static const int intAirActLogLevel = IA_LOG_LEVEL_VERBOSE | IA_LOG_FLAG_TRACE; // | IA_LOG_FLAG_TRACE

@interface SDServiceDiscovery ()

@property (nonatomic, strong) NSMutableDictionary * netServiceBrowsers;
@property (nonatomic, strong) NSMutableDictionary * netServices;
@property (nonatomic) dispatch_queue_t queue;
@property (nonatomic, strong) NSMutableArray * resolvingServices;

@end

@implementation SDServiceDiscovery

+(id)new
{
    return [[self alloc] initWithQueue:dispatch_queue_create("SDServiceDiscovery", NULL)];
}

- (id)initWithQueue:(dispatch_queue_t)queue
{
    self = [super init];
    if (self) {
        _netServiceBrowsers = [NSMutableDictionary new];
        _netServices = [NSMutableDictionary new];
        _resolvingServices = [NSMutableArray new];
        
        if(queue) {
            _queue = queue;
            // we need to retain queues that are handed in in iOS < 6 and OS X < 10.8
            #if NEEDS_DISPATCH_RETAIN_RELEASE
                dispatch_retain(queue);
            #endif
        } else {
            _queue = dispatch_queue_create("SDServiceDiscovery", NULL);
        }
        
        // Automatically stop when the app becomes inactive on iOS
        #if TARGET_OS_IPHONE
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
    
    #if NEEDS_DISPATCH_RETAIN_RELEASE
    if (self.queue) {
        dispatch_release(self.queue);
    }
    #endif
}

-(void)stop
{
    [self stopSearching];
    [self stopPublishing];
}

#pragma mark Searching

-(void)searchForServicesOfType:(NSString *)type
{
    return [self searchForServicesOfType:type inDomain:@"local."];
}

-(void)searchForServicesOfType:(NSString*)type
                      inDomain:(NSString*)domain
{
    IALogTrace();
    
    if(self.netServiceBrowsers[[[self class] keyForType:type domain:domain]] != nil) {
        IALogWarn(@"%@[%p]: Already searching for type %@ in domain %@", THIS_FILE, self, type, domain);
        return NO;
    }
    
    dispatch_async(self.queue, ^{
        NSNetServiceBrowser * netServiceBrowser = [NSNetServiceBrowser new];
        [netServiceBrowser setDelegate:self];
        NSString * key = [[self class] keyForType:type domain:domain];
        _netServiceBrowsers[key] = netServiceBrowser;
        
        dispatch_block_t bonjourBlock = ^{
            [netServiceBrowser removeFromRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
            [netServiceBrowser scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
            [netServiceBrowser searchForServicesOfType:type inDomain:domain];
            IALogInfo(@"%@[%p]: Bonjour search started for type %@ in domain %@", THIS_FILE, self, type, domain);
        };
        
        [[self class] startBonjourThreadIfNeeded];
        [[self class] performBonjourBlock:bonjourBlock];
    });
}

-(void)stopSearching
{
    IALogTrace();
	
	dispatch_sync(self.queue, ^{
        for(NSNetServiceBrowser * netServiceBrowser in [_netServiceBrowsers allValues]) {
            dispatch_block_t bonjourBlock = ^{
                [netServiceBrowser stop];
            };
            [[self class] performBonjourBlock:bonjourBlock];
        }
        [_netServiceBrowsers removeAllObjects];
    });
}

-(void)stopSearchingForServicesOfType:(NSString *)type
{
    [self stopSearchingForServicesOfType:type inDomain:@"local."];
}

-(void)stopSearchingForServicesOfType:(NSString*)type
                             inDomain:(NSString*)domain
{
    IALogTrace();
	
	dispatch_sync(self.queue, ^{
        NSString * key = [[self class] keyForType:type domain:domain];
        NSNetServiceBrowser * netServiceBrowser = _netServiceBrowsers[key];
        
        if (netServiceBrowser)
        {
            dispatch_block_t bonjourBlock = ^{
                [netServiceBrowser stop];
            };
            
            [[self class] performBonjourBlock:bonjourBlock];
            
            [_netServiceBrowsers removeObjectForKey:key];
        }
    });
}

#pragma mark Publishing

-(void)publishServiceOfType:(NSString*)type
                     onPort:(int)port
{
    [self publishServiceOfType:type onPort:port withName:@""];
}

-(void)publishServiceOfType:(NSString*)type
                     onPort:(int)port
                   withName:(NSString*)name
{
    [self publishServiceOfType:type onPort:port withName:name inDomain:@"local."];
}

-(void)publishServiceOfType:(NSString*)type
                     onPort:(int)port
                   withName:(NSString*)name
                   inDomain:(NSString*)domain
{
    [self publishServiceOfType:type onPort:port withName:name inDomain:domain txtRecord:nil];
}

-(void)publishServiceOfType:(NSString*)type
                     onPort:(int)port
                   withName:(NSString*)name
                   inDomain:(NSString*)domain
                  txtRecord:(NSDictionary*)txtRecord
{
    IALogTrace();
	
	dispatch_sync(self.queue, ^{
        NSNetService * netService = [[NSNetService alloc] initWithDomain:domain type:type name:name port:port];
		[netService setDelegate:self];
        NSString * key = [[self class] keyForType:type domain:domain port:port];
        self.netServices[key] = netService;
		
		NSNetService *theNetService = netService;
		NSData *txtRecordData = nil;
		if (txtRecord)
            txtRecordData = [NSNetService dataFromTXTRecordDictionary:txtRecord];
		
		dispatch_block_t bonjourBlock = ^{
			
			[theNetService removeFromRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
			[theNetService scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
			[theNetService publish];
			
			// Do not set the txtRecordDictionary prior to publishing!!!
			// This will cause the OS to crash!!!
			if (txtRecordData)
			{
				[theNetService setTXTRecordData:txtRecordData];
			}
		};
		
		[[self class] startBonjourThreadIfNeeded];
		[[self class] performBonjourBlock:bonjourBlock];
    });
}

-(void)stopPublishing
{
    IALogTrace();
	
	dispatch_sync(self.queue, ^{
        for(NSNetService * netService in [_netServices allValues]) {
            dispatch_block_t bonjourBlock = ^{
                [netService stop];
            };
            [[self class] performBonjourBlock:bonjourBlock];
        }
        [_netServices removeAllObjects];
    });
}

-(void)stopPublishingServiceOfType:(NSString *)type
                            onPort:(int)port
{
    [self stopPublishingServiceOfType:type onPort:port inDomain:@"local."];
}

-(void)stopPublishingServiceOfType:(NSString *)type
                            onPort:(int)port
                          inDomain:(NSString *)domain
{
	IALogTrace();
	
	dispatch_sync(self.queue, ^{
        NSString * key = [[self class] keyForType:type domain:domain port:port];
        NSNetService * netService = _netServices[key];
        if (netService) {
            dispatch_block_t bonjourBlock = ^{
                [netService stop];
            };
            [[self class] performBonjourBlock:bonjourBlock];
            [_netServices removeObjectForKey:key];
        }
    });
}

#pragma mark Delegate functions of Browser

-(void)netServiceBrowser:(NSNetServiceBrowser *)sender
            didNotSearch:(NSDictionary *)errorInfo
{
    IALogError(@"%@[%p]: Bonjour could not search: %@", THIS_FILE, self, errorInfo);
}

-(void)netServiceBrowser:(NSNetServiceBrowser *)sender
          didFindService:(NSNetService *)netService
              moreComing:(BOOL)moreServicesComing
{
    IALogTrace2(@"%@[%p]: Bonjour Service found: name(%@) type(%@) domain(%@)", THIS_FILE, self, netService.name, netService.type, netService.domain);
    [self.resolvingServices addObject:netService];
    [netService setDelegate:self];
    [netService resolveWithTimeout:0.0];
}

-(void)netServiceBrowser:(NSNetServiceBrowser *)sender
        didRemoveService:(NSNetService *)netService
              moreComing:(BOOL)moreServicesComing
{
    IALogVerbose(@"%@[%p]: Bonjour Service went away: name(%@) type(%@) domain(%@)", THIS_FILE, self, netService.name, netService.type, netService.domain);
    [self.resolvingServices removeObject:netService];
}

-(void)netServiceBrowserDidStopSearch:(NSNetServiceBrowser *)sender
{
    IALogTrace();
}

-(void)netService:(NSNetService *)netService
    didNotResolve:(NSDictionary *)errorDict
{
    IALogWarn(@"%@[%p]: Could not resolve Bonjour Service: name(%@) type(%@) domain(%@)", THIS_FILE, self, netService.name, netService.type, netService.domain);
    [self.resolvingServices removeObject:netService];
}

-(void)netServiceDidResolveAddress:(NSNetService *)netService
{
	IALogVerbose(@"%@[%p]: Bonjour Service resolved: name(%@) host(%@:%"FMTNSINT") type(%@) domain(%@)", THIS_FILE, self, netService.name, netService.hostName, netService.port, netService.type, netService.domain);
    [self.resolvingServices removeObject:netService];
}

#pragma mark Delegate functions of publishing

- (void)netServiceDidPublish:(NSNetService *)netService
{
    IALogVerbose(@"%@[%p]: Bonjour Service published: name(%@) type(%@) domain(%@)", THIS_FILE, self, netService.name, netService.type, netService.domain);
}

- (void)netService:(NSNetService *)netService didNotPublish:(NSDictionary *)errorDict
{
    IALogError(@"%@[%p]: Failed to publish Bonjour Service: name(%@) type(%@) domain(%@) error(%@)", THIS_FILE, self, netService.name, netService.type, netService.domain, errorDict);
}

#pragma mark Bonjour Thread

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
        IALogTrace3(@"Starting Bonjour Thread");
        
		bonjourThread = [[NSThread alloc] initWithTarget:self
                                                selector:@selector(bonjourThread)
                                                  object:nil];
		[bonjourThread start];
	});
}

+ (void)bonjourThread
{
	@autoreleasepool {
        
        IALogTrace3(@"Bonjour Thread: Started");
		
		// We can't run the run loop unless it has an associated input source or a timer.
		// So we'll just create a timer that will never fire - unless the server runs for 10,000 years.
		
		[NSTimer scheduledTimerWithTimeInterval:[[NSDate distantFuture] timeIntervalSinceNow]
                                         target:self
                                       selector:@selector(donothingatall:)
                                       userInfo:nil
                                        repeats:YES];
		
		[[NSRunLoop currentRunLoop] run];
        
        IALogTrace3(@"Bonjour Thread: Aborted");
        
	}
}

+ (void)executeBonjourBlock:(dispatch_block_t)block
{
	IALogTrace();
	
	NSAssert([NSThread currentThread] == bonjourThread, @"Executed on wrong Thread");
	
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

#pragma mark Methods for creating the keys that store the nsnetservice and browser objects

+(NSString*)keyForType:(NSString*)type domain:(NSString*)domain
{
    return [NSString stringWithFormat:@"%@.%@", type, domain];
}

+(NSString*)keyForType:(NSString*)type domain:(NSString*)domain port:(int)port
{
    return [NSString stringWithFormat:@"%@%@%i", type, domain, port];
}

@end
