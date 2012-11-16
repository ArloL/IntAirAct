#import "IntAirActTests.h"

#import <CocoaLumberjack/DDLog.h>
#import <CocoaLumberjack/DDTTYLogger.h>
#import <IntAirAct/IntAirAct.h>

#import "IANumber.h"

// Log levels : off, error, warn, info, verbose
static const int ddLogLevel = LOG_LEVEL_VERBOSE;

#define WAIT_TIME 5

@interface IntAirActTests()

@property (nonatomic, strong) IAIntAirAct * intAirAct;

@end

@implementation IntAirActTests

@synthesize intAirAct;

-(void)logging
{
    static dispatch_once_t once;
    dispatch_once(&once, ^ {
        [DDLog addLogger:[DDTTYLogger sharedInstance]];
        [[DDTTYLogger sharedInstance] setColorsEnabled:YES];
    });
}

-(void)setUp
{
    [super setUp];
    
    // Set-up code here.
    [self logging];

    // Given
    self.intAirAct = [IAIntAirAct new];
}

-(void)tearDown
{
    // Tear-down code here.
    if(self.intAirAct.isRunning) {
        [self.intAirAct stop];
        // Bonjour takes a while to shutdown everything properly
        sleep(1);
    }
    
    [super tearDown];
}

-(void)testOwnDeviceShouldBeNil
{
    // Then
    STAssertNil(self.intAirAct.ownDevice, @"Own Device should be nil");
}

-(void)testDefaultPortShouldBeZero
{
    NSInteger expectedPort = 0;
    // Then
    STAssertEquals(expectedPort, self.intAirAct.port, @"Default port should be %i but was %i", expectedPort, self.intAirAct.port);
}

-(void)testDefaultSupportedRoutesShouldBeEmpty
{
    // Then
    STAssertNotNil(self.intAirAct.supportedRoutes, @"Supported routes should not be nil");
    STAssertTrue([self.intAirAct.supportedRoutes count] == 1, @"Supported routes only have GET /routes");
}

-(void)testDefaultDevicesShouldBeEmpty
{
    // Then
    STAssertNotNil(self.intAirAct.devices, @"Devices should not be nil");
    STAssertTrue([self.intAirAct.devices count] == 0, @"Devices should be empty");
}

-(void)testIsRunningShouldBeNO
{
    // Then
    STAssertFalse(self.intAirAct.isRunning, @"isRunning should be NO");
}

-(void)testIntAirActShouldStart
{
    // Then
    NSError * error = nil;
    if (![self.intAirAct start:&error]) {
        STFail(@"HTTP server failed to start: %@", error);
    }
    
    [self.intAirAct stop];
}

-(void)testIntAirActShouldNotStart
{
    // And
    self.intAirAct.port = 80;

    // Then
    NSError * error = nil;
    if ([self.intAirAct start:&error]) {
        STFail(@"Server should fail to start");
    }
}

-(void)testIntAirActShouldFindOwnDeviceInFiveSeconds
{
    // Then
    NSError * error = nil;
    if (![self.intAirAct start:&error]) {
        STFail(@"HTTP server failed to start: %@", error);
        return;
    }
    NSDate * start = [NSDate new];
    while(self.intAirAct.ownDevice == nil) {
        if([start timeIntervalSinceNow] < -5) {
            STFail(@"IntAirAct should find own Device in five seconds");
            return;
        }
        [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
    }
}

-(void)testOwnDeviceSupportedRoutesShouldBeEqualToResolved
{
    // And
    [self.intAirAct.supportedRoutes addObject:[IARoute routeWithAction:@"GET" resource:@"/example"]];
    
    // Then
    NSError * error = nil;
    if (![self.intAirAct start:&error]) {
        STFail(@"HTTP server failed to start: %@", error);
    } else {
        NSDate * start = [NSDate new];
        while(self.intAirAct.ownDevice == nil) {
            [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
            if([start timeIntervalSinceNow] < -5) {
                STFail(@"IntAirAct should find own Device in five seconds");
                return;
            }
        }
    }
    
    STAssertEqualObjects(self.intAirAct.supportedRoutes, self.intAirAct.ownDevice.supportedRoutes, @"ownDevice.supportedRoutes and supportedRoutes should be equal");
}

-(void)testIntAirActShouldFindOtherDeviceInFiveSeconds
{
    // And
    NSError * error = nil;
    IAIntAirAct * iAA = [IAIntAirAct new];
    if (![iAA start:&error]) {
        STFail(@"IntAirAct failed to start: %@", error);
    } else if (![self.intAirAct start:&error]) {
    // And
        STFail(@"IntAirAct failed to start: %@", error);
    } else {
        NSDate * start = [NSDate new];
        while(self.intAirAct.ownDevice == nil || iAA.ownDevice == nil) {
            [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
            if([start timeIntervalSinceNow] < -5) {
                STFail(@"IntAirAct should find own Device in five seconds");
                return;
            }
        }
        
        STAssertNotNil(self.intAirAct.ownDevice, @"ownDevice should not be nil");
        STAssertNotNil(iAA.ownDevice, @"ownDevice should not be nil");
        
        // Then
        start = [NSDate new];
        while(![self.intAirAct.devices containsObject:iAA.ownDevice] && ![iAA.devices containsObject:self.intAirAct.ownDevice]) {
            [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
            if([start timeIntervalSinceNow] < -5) {
                STFail(@"IntAirAct should find other Device in five seconds");
                return;
            }
        }
    }

    [iAA stop];
    sleep(1);
}

-(void)testIntAirActShouldFindOwnDeviceInFiveSeconds2
{
    NSDate * startTimePlusWaitTime;
    __block BOOL found = NO;
    __block NSCondition * cond = [NSCondition new];
    id deviceFoundObserver;
    
    deviceFoundObserver = [self.intAirAct addHandlerForDeviceFound:^(IADevice *device, BOOL ownDevice) {
        if(ownDevice) {
            found = YES;
            [cond signal];
        }
    }];
    
    // Then
    NSError * error = nil;
    if (![self.intAirAct start:&error]) {
        STFail(@"HTTP server failed to start: %@", error);
        return;
    }
    
    startTimePlusWaitTime = [NSDate dateWithTimeIntervalSinceNow:WAIT_TIME];
    
    [cond lock];
    while(!found && [startTimePlusWaitTime timeIntervalSinceNow] > 0) {
        [cond waitUntilDate:startTimePlusWaitTime];
    }
    [cond unlock];
    
    STAssertNotNil(self.intAirAct.ownDevice, @"ownDevice should be set");

    [self.intAirAct stop];
    sleep(1);
    
    if (!found) {
        STFail(@"Did not find service");
    }
}

@end
