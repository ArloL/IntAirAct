#import "IADeviceTests.h"

#import <CocoaLumberjack/DDLog.h>
#import <CocoaLumberjack/DDTTYLogger.h>
#import <IntAirAct/IntAirAct.h>

// Log levels : off, error, warn, info, verbose
//static const int ddLogLevel = LOG_LEVEL_VERBOSE;

@implementation IADeviceTests

-(void)setUp
{
    [super setUp];

    // Set-up code here.
    [DDLog addLogger:[DDTTYLogger sharedInstance]];
    [[DDTTYLogger sharedInstance] setColorsEnabled:YES];
}

-(void)tearDown
{
    // Tear-down code here.
    [DDLog removeAllLoggers];

    [super tearDown];
}

- (void)testConstructor
{
    NSString * name = @"name";
    NSString * host = @"host";
    NSInteger port = 8080;
    NSSet * supportedRoutes = [NSSet new];
    IADevice * service = [IADevice deviceWithName:name host:host port:port supportedRoutes:supportedRoutes];
    STAssertEquals(name, service.name, @"Name should be the same");
    STAssertEquals(host, service.host, @"Hostname should be the same");
    STAssertEquals(port, service.port, @"Port should be the same");
    STAssertEquals(supportedRoutes, service.supportedRoutes, @"TXTRecord should be the same");
}

- (void)testEquals
{
    NSString * name = @"name";
    NSString * host = @"host";
    NSInteger port = 8080;
    NSSet * supportedRoutes = [NSSet new];
    IADevice * service = [IADevice deviceWithName:name host:host port:port supportedRoutes:supportedRoutes];
    IADevice * other = [IADevice deviceWithName:name host:host port:port supportedRoutes:supportedRoutes];
    STAssertEqualObjects(service, other, @"Should be equal");
    STAssertEquals(service.hash, other.hash, @"Hashes should be equal");
}

- (void)testEqualsWithSelf
{
    NSString * name = @"name";
    NSString * host = @"host";
    NSInteger port = 8080;
    NSSet * supportedRoutes = [NSSet new];
    IADevice * service = [IADevice deviceWithName:name host:host port:port supportedRoutes:supportedRoutes];
    STAssertTrue([service isEqual:service], @"Should be equal");
    STAssertEquals(service.hash, service.hash, @"Hashes should be equal");
}

- (void)testEqualsFails
{
    NSString * name = @"name";
    NSString * differentName = @"differentName";

    NSString * host = @"host";
    NSInteger port = 8080;
    NSSet * supportedRoutes = [NSSet new];
    IADevice * service = [IADevice deviceWithName:name host:host port:port supportedRoutes:supportedRoutes];
    IADevice * other = [IADevice deviceWithName:differentName host:host port:port supportedRoutes:supportedRoutes];
    STAssertFalse([service isEqual:other], @"Should not be equal");
    STAssertFalse(service.hash == other.hash, @"Hashes should not be equal");
}

- (void)testEqualsWithDifferentObject
{
    NSString * name = @"name";
    NSString * host = @"host";
    NSInteger port = 8080;
    NSSet * supportedRoutes = [NSSet new];
    IADevice * service = [IADevice deviceWithName:name host:host port:port supportedRoutes:supportedRoutes];

    NSString * other = @"name";
    STAssertFalse([service isEqual:other], @"Should not be equal");
    STAssertFalse(service.hash == other.hash, @"Hashes should not be equal");
}

- (void)testDescription
{
    NSString * name = @"name";
    NSString * host = @"host";
    NSInteger port = 8080;
    NSSet * supportedRoutes = [NSSet new];
    IADevice * service = [IADevice deviceWithName:name host:host port:port supportedRoutes:supportedRoutes];
    STAssertNotNil(service.description, @"Description should not be nil");
}

@end
