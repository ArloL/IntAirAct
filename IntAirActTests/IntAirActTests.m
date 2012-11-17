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

-(void)setUp
{
    [super setUp];
    
    // Set-up code here.
    [DDLog addLogger:[DDTTYLogger sharedInstance]];
    [[DDTTYLogger sharedInstance] setColorsEnabled:YES];

    // Given
    self.intAirAct = [IAIntAirAct new];
}

-(void)tearDown
{
    // Tear-down code here.
    [DDLog removeAllLoggers];
    
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
    
    [self.intAirAct removeObserver:deviceFoundObserver];
    
    [self.intAirAct stop];
    sleep(1);
    
    if (!found) {
        STFail(@"Did not find service");
    }
}

-(void)testOwnDeviceSupportedRoutesShouldBeEqualToResolved
{
    [self.intAirAct.supportedRoutes addObject:[IARoute routeWithAction:@"GET" resource:@"/example"]];
    
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
    
    STAssertEqualObjects(self.intAirAct.supportedRoutes, self.intAirAct.ownDevice.supportedRoutes, @"ownDevice.supportedRoutes and supportedRoutes should be equal");
    
    [self.intAirAct removeObserver:deviceFoundObserver];
    
    [self.intAirAct stop];
    sleep(1);
}

-(void)testIntAirActShouldFindOtherDeviceInFiveSeconds
{
    NSDate * startTimePlusWaitTime;
    __block NSCondition * cond = [NSCondition new];
    __block BOOL foundOne = NO;
    __block BOOL foundTwo = NO;
    id deviceFoundObserverOne;
    id deviceFoundObserverTwo;
    
    deviceFoundObserverOne = [self.intAirAct addHandlerForDeviceFound:^(IADevice *device, BOOL ownDevice) {
        if(!ownDevice && [device.supportedRoutes containsObject:[IARoute get:@"/two"]]) {
            foundOne = YES;
            [cond signal];
        }
    }];
    
    NSError * error = nil;
    if (![self.intAirAct start:&error]) {
        STFail(@"HTTP server failed to start: %@", error);
        return;
    }
    
    [self.intAirAct.supportedRoutes addObject:[IARoute get:@"/one"]];
    
    IAIntAirAct * iAA = [IAIntAirAct new];
    
    [iAA.supportedRoutes addObject:[IARoute get:@"/two"]];
    
    deviceFoundObserverTwo = [iAA addHandlerForDeviceFound:^(IADevice *device, BOOL ownDevice) {
        if(!ownDevice && [device.supportedRoutes containsObject:[IARoute get:@"/one"]]) {
            foundTwo = YES;
            [cond signal];
        }
    }];
    
    if (![iAA start:&error]) {
        STFail(@"HTTP server failed to start: %@", error);
        return;
    }
    
    startTimePlusWaitTime = [NSDate dateWithTimeIntervalSinceNow:WAIT_TIME];
    
    [cond lock];
    while((!foundOne || !foundTwo) && [startTimePlusWaitTime timeIntervalSinceNow] > 0) {
        [cond waitUntilDate:startTimePlusWaitTime];
    }
    [cond unlock];
    
    [self.intAirAct removeObserver:deviceFoundObserverOne];
    [iAA removeObserver:deviceFoundObserverTwo];
    
    [self.intAirAct stop];
    [iAA stop];
    sleep(1);
    
    if (!foundOne || !foundTwo) {
        STFail(@"Did not find each other");
    }
}

@end
