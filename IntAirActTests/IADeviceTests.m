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
    XCTAssertEqual(name, service.name, @"Name should be the same");
    XCTAssertEqual(host, service.host, @"Hostname should be the same");
    XCTAssertEqual(port, service.port, @"Port should be the same");
    XCTAssertEqual(supportedRoutes, service.supportedRoutes, @"TXTRecord should be the same");
}

- (void)testEquals
{
    NSString * name = @"name";
    NSString * host = @"host";
    NSInteger port = 8080;
    NSSet * supportedRoutes = [NSSet new];
    IADevice * service = [IADevice deviceWithName:name host:host port:port supportedRoutes:supportedRoutes];
    IADevice * other = [IADevice deviceWithName:name host:host port:port supportedRoutes:supportedRoutes];
    XCTAssertEqualObjects(service, other, @"Should be equal");
    XCTAssertEqual(service.hash, other.hash, @"Hashes should be equal");
}

- (void)testEqualsWithSelf
{
    NSString * name = @"name";
    NSString * host = @"host";
    NSInteger port = 8080;
    NSSet * supportedRoutes = [NSSet new];
    IADevice * service = [IADevice deviceWithName:name host:host port:port supportedRoutes:supportedRoutes];
    XCTAssertTrue([service isEqual:service], @"Should be equal");
    XCTAssertEqual(service.hash, service.hash, @"Hashes should be equal");
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
    XCTAssertFalse([service isEqual:other], @"Should not be equal");
    XCTAssertFalse(service.hash == other.hash, @"Hashes should not be equal");
}

- (void)testEqualsWithDifferentObject
{
    NSString * name = @"name";
    NSString * host = @"host";
    NSInteger port = 8080;
    NSSet * supportedRoutes = [NSSet new];
    IADevice * service = [IADevice deviceWithName:name host:host port:port supportedRoutes:supportedRoutes];

    NSString * other = @"name";
    XCTAssertFalse([service isEqual:other], @"Should not be equal");
    XCTAssertFalse(service.hash == other.hash, @"Hashes should not be equal");
}

- (void)testDescription
{
    NSString * name = @"name";
    NSString * host = @"host";
    NSInteger port = 8080;
    NSSet * supportedRoutes = [NSSet new];
    IADevice * service = [IADevice deviceWithName:name host:host port:port supportedRoutes:supportedRoutes];
    XCTAssertNotNil(service.description, @"Description should not be nil");
}

@end
