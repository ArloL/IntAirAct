#import "IntAirActTests.h"

#import <CocoaLumberjack/DDLog.h>
#import <CocoaLumberjack/DDTTYLogger.h>
#import <IntAirAct/IntAirAct.h>
#import <RestKit/RestKit.h>

#import "IANumber.h"

@interface IntAirActTests()

@property (nonatomic, strong) IAIntAirAct * intAirAct;

@end

@implementation IntAirActTests

@synthesize intAirAct;

- (id)init
{
    self = [super init];
    if (self) {
        // Configure logging framework to log to the Xcode console.
        [DDLog addLogger:[DDTTYLogger sharedInstance]];
    }
    return self;
}

-(void)setUp
{
    [super setUp];
    
    // Given
    self.intAirAct = [IAIntAirAct new];
}

-(void)tearDown
{
    [super tearDown];
}

-(void)testOwnDeviceShouldBeNil
{
    // Then
    STAssertNil(self.intAirAct.ownDevice, @"Own Device should be nil");
}

-(void)testRouterShouldNotBeNil
{
    // Then
    STAssertNotNil(self.intAirAct.router, @"Router should not be nil");
}

-(void)testObjectMappingProviderShouldNotBeNil
{   
    // Then
    STAssertNotNil(self.intAirAct.objectMappingProvider, @"ObjectMappingProvider should not be nil");
}

-(void)testDefaultPortShouldBeZero
{   
    // Then
    STAssertEquals((UInt16) 0, self.intAirAct.port, @"Default port should be zero but was %i", self.intAirAct.port);
}

-(void)testDefaultClientShouldBeYES
{   
    // Then
    STAssertTrue(self.intAirAct.client, @"Client should be YES");
}

-(void)testDefaultServerShouldBeYES
{
    // Then
    STAssertTrue(self.intAirAct.server, @"Server should be YES");
}

-(void)testDefaultMimeTypeShouldBeJSON
{
    // Then
    STAssertEqualObjects(@"application/json", self.intAirAct.defaultMimeType, @"defaultMimeType should be JSON");
}

-(void)testDefaultCapabilitiesShouldBeEmpty
{
    // Then
    STAssertNotNil(self.intAirAct.capabilities, @"Capabilities should not be nil");
    STAssertTrue([self.intAirAct.capabilities count] == 0, @"Capabilities should be empty");
}

-(void)testDefaultDevicesShouldBeEmpty
{
    // Then
    STAssertNotNil(self.intAirAct.devices, @"Devices should not be nil");
    STAssertTrue([self.intAirAct.devices count] == 0, @"Devices should be empty");
}

-(void)testHTTPServerShouldNotBeNil
{
    // Then
    STAssertNotNil(self.intAirAct.httpServer, @"httpServer should not be nil");
}

-(void)testIsRunningShouldBeNO
{
    // Then
    STAssertFalse(self.intAirAct.isRunning, @"isRunning should be NO");
}

-(void)testTXTRecordDictionaryShouldNotBeNil
{
    // Then
    STAssertNotNil(self.intAirAct.txtRecordDictionary, @"txtRecordDictionary should not be nil");
}

-(void)testIntAirActShouldStart
{
    // Then
    NSError * error = nil;
    if (![self.intAirAct start:&error]) {
        STFail(@"HTTP server failed to start: %@", error);
    }
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
    } else {
        NSDate * start = [NSDate new];
        while(self.intAirAct.ownDevice == nil) {
            [NSThread sleepForTimeInterval:0.5];
            if([start timeIntervalSinceNow] < -5) {
                STFail(@"IntAirAct should find own Device in five seconds");
                break;
            }
        }
    }
}

-(void)testOwnDeviceCapabilitesShouldBeEqualToResolved
{
    // And
    IACapability * cap = [IACapability new];
    cap.capability = @"capability string";
    [self.intAirAct.capabilities addObject:cap];
    
    // Then
    NSError * error = nil;
    if (![self.intAirAct start:&error]) {
        STFail(@"HTTP server failed to start: %@", error);
    } else {
        NSDate * start = [NSDate new];
        while(self.intAirAct.ownDevice == nil) {
            [NSThread sleepForTimeInterval:0.5];
            if([start timeIntervalSinceNow] < -5) {
                STFail(@"IntAirAct should find own Device in five seconds");
                break;
            }
        }
    }
    
    STAssertEqualObjects(self.intAirAct.capabilities, self.intAirAct.ownDevice.capabilities, @"ownDevice.capabilities and capabilities should be equal");
}

-(void)testDefaultObjectMappings
{
    // Then
    STAssertNotNil([self.intAirAct.objectMappingProvider serializationMappingForClass:[IADevice class]], @"A serialization mapping should exist");
    STAssertNotNil([self.intAirAct.objectMappingProvider mappingForKeyPath:@"devices"], @"A deserialization mapping should exist");
    
    STAssertNotNil([self.intAirAct.objectMappingProvider serializationMappingForClass:[IAAction class]], @"A serialization mapping should exist");
    STAssertNotNil([self.intAirAct.objectMappingProvider mappingForKeyPath:@"actions"], @"A deserialization mapping should exist");
    
    STAssertNotNil([self.intAirAct.objectMappingProvider serializationMappingForClass:[IACapability class]], @"A serialization mapping should exist");
    STAssertNotNil([self.intAirAct.objectMappingProvider mappingForKeyPath:@"capabilities"], @"A deserialization mapping should exist");
}

-(void)testAddMappingForClass
{
    // And
    [self.intAirAct addMappingForClass:[IANumber class] withKeypath:@"numbers" withAttributes:@"number", nil];
 
    // Then
    STAssertNotNil([self.intAirAct.objectMappingProvider serializationMappingForClass:[IANumber class]], @"A serialization mapping should exist");
    STAssertNotNil([self.intAirAct.objectMappingProvider mappingForKeyPath:@"numbers"], @"A deserialization mapping should exist");
}

-(void)testObjectManagerForOwnDeviceShouldHaveLocalInterface
{
    // Then
    NSError * error = nil;
    if (![self.intAirAct start:&error]) {
        STFail(@"HTTP server failed to start: %@", error);
    } else {
        NSDate * start = [NSDate new];
        while(self.intAirAct.ownDevice == nil) {
            [NSThread sleepForTimeInterval:0.5];
            if([start timeIntervalSinceNow] < -5) {
                STFail(@"IntAirAct should find own Device in five seconds");
                break;
            }
        }
    }
    
    RKObjectManager * man = [self.intAirAct objectManagerForDevice:self.intAirAct.ownDevice];
    STAssertNotNil(man, @"Should return an RKObjectManager");
    STAssertTrue([[man.baseURL absoluteString] hasPrefix:@"http://127.0.0.1"], @"Should be a local interface");
}

@end
