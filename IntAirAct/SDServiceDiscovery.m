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
@property (nonatomic, strong) NSNetService *netService;
@property (nonatomic) dispatch_queue_t queue;
@property (nonatomic, strong) NSMutableArray * resolvingServices;

@end

@implementation SDServiceDiscovery

+(id)new
{
    return [[self alloc] initWithType:@"_http._tcp"
                               domain:@"local."
                            autostart:YES
                                queue:dispatch_queue_create("SDServiceDiscovery", NULL)];
}

- (id)initWithType:(NSString*)type
            domain:(NSString*)domain
         autostart:(BOOL)autostart
             queue:(dispatch_queue_t)queue
{
    self = [super init];
    if (self) {
        _type = type;
        _domain = domain;
        _autostart = autostart;
        
        _netServiceBrowsers = [NSMutableDictionary new];
        
        if(queue) {
            _queue = queue;
            #if NEEDS_DISPATCH_RETAIN_RELEASE
                dispatch_retain(queue);
            #endif
        } else {
            _queue = dispatch_queue_create("SDServiceDiscovery", NULL);
        }
        
        _resolvingServices = [NSMutableArray new];
        
        #if TARGET_OS_IPHONE
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(applicationWillBecomeActive )
                                                         name:UIApplicationDidBecomeActiveNotification
                                                       object:nil];
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(stopSearching)
                                                         name:UIApplicationWillResignActiveNotification
                                                       object:nil];
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(stopSearching)
                                                         name:UIApplicationWillTerminateNotification
                                                       object:nil];
        #else
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(applicationWillBecomeActive)
                                                         name:NSApplicationWillBecomeActiveNotification
                                                       object:nil];
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(stopSearching)
                                                         name:NSApplicationWillTerminateNotification
                                                       object:nil];
        #endif

    }
    return self;
}

-(void)dealloc
{
    IALogTrace();
    
    #if NEEDS_DISPATCH_RETAIN_RELEASE
    if (self.queue) {
        dispatch_release(self.queue);
    }
    #endif
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void)applicationWillBecomeActive
{
    IALogTrace();
    if(self.autostart) {
        [self startSearching];
    }
    // this method should only be called on the first run, therefore myself as an observer
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:NSApplicationWillBecomeActiveNotification
                                                  object:nil];
}

-(void)startSearching
{
    [self startSearchingForType:self.type inDomain:self.domain];
}

-(void)startSearchingForType:(NSString*)type inDomain:(NSString*)domain
{
    IALogTrace();
    
    dispatch_async(self.queue, ^{
        NSNetServiceBrowser * netServiceBrowser = [NSNetServiceBrowser new];
        [netServiceBrowser setDelegate:self];
        self.netServiceBrowsers[[type stringByAppendingString:domain]] = netServiceBrowser;
        
        dispatch_block_t bonjourBlock = ^{
            [netServiceBrowser removeFromRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
            [netServiceBrowser scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
            [netServiceBrowser searchForServicesOfType:type inDomain:domain];
            IALogError(@"%@[%p]: Bonjour search started for type %@ in domain %@", THIS_FILE, self, type, domain);
        };
        
        [[self class] startBonjourThreadIfNeeded];
        [[self class] performBonjourBlock:bonjourBlock];
    });
}

-(void)stopSearching
{
    [self stopSearchingForType:self.type inDomain:self.domain];
}

-(void)stopSearchingForType:(NSString*)type inDomain:(NSString*)domain
{
    IALogTrace();
	
	dispatch_sync(self.queue, ^{
        NSString * key = [type stringByAppendingString:domain];
        NSNetServiceBrowser * netServiceBrowser = self.netServiceBrowsers[key];
        
        if (netServiceBrowser)
        {
            dispatch_block_t bonjourBlock = ^{
                [netServiceBrowser stop];
            };
            
            [[self class] performBonjourBlock:bonjourBlock];
            
            self.netServiceBrowsers[key] = nil;
        }
    });
}

#pragma mark Delegate functions

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

@end
