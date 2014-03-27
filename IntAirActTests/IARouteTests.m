#import "IARouteTests.h"

#import <CocoaLumberjack/DDLog.h>
#import <CocoaLumberjack/DDTTYLogger.h>
#import <IntAirAct/IntAirAct.h>

// Log levels : off, error, warn, info, verbose
//static const int ddLogLevel = LOG_LEVEL_VERBOSE;

@implementation IARouteTests

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
    IARoute * route = [IARoute routeWithAction:@"GET" resource:@"/example"];
    XCTAssertEqualObjects(route.action, @"GET");
    XCTAssertEqualObjects(route.resource, @"/example");
}

- (void)testEquals
{
    IARoute * route = [IARoute routeWithAction:@"GET" resource:@"/example"];
    IARoute * other = [IARoute routeWithAction:@"GET" resource:@"/example"];
    XCTAssertTrue([route isEqual:other]);
    XCTAssertEqual(route.hash, other.hash);
}

- (void)testEqualsSelf
{
    IARoute * route = [IARoute routeWithAction:@"GET" resource:@"/example"];
    IARoute * other = route;
    XCTAssertTrue([route isEqual:other]);
    XCTAssertEqual(route.hash, other.hash);
}

- (void)testEqualsNil
{
    IARoute * route = [IARoute routeWithAction:@"GET" resource:@"/example"];
    IARoute * other = nil;
    XCTAssertFalse([route isEqual:other]);
}

- (void)testEqualsDifferentAction
{
    IARoute * route = [IARoute routeWithAction:@"GET" resource:@"/example"];
    IARoute * other = [IARoute routeWithAction:@"PUT" resource:@"/example"];
    XCTAssertFalse([route isEqual:other]);
    XCTAssertFalse(route.hash == other.hash);
}

- (void)testEqualsDifferentResource
{
    IARoute * route = [IARoute routeWithAction:@"GET" resource:@"/example"];
    IARoute * other = [IARoute routeWithAction:@"GET" resource:@"/example2"];
    XCTAssertFalse([route isEqual:other]);
    XCTAssertFalse(route.hash == other.hash);
}

- (void)testEqualsActionIsNull
{
    IARoute * route = [IARoute routeWithAction:nil resource:@"/example"];
    IARoute * other = [IARoute routeWithAction:@"GET" resource:@"/example"];
    XCTAssertFalse([route isEqual:other]);
    XCTAssertFalse(route.hash == other.hash);
}

- (void)testEqualsResourceIsNull
{
    IARoute * route = [IARoute routeWithAction:@"GET" resource:nil];
    IARoute * other = [IARoute routeWithAction:@"GET" resource:@"/example"];
    XCTAssertFalse([route isEqual:other]);
    XCTAssertFalse(route.hash == other.hash);
}

- (void)testEqualsWithDifferentObject
{
    NSString * action = @"GET";
    NSString * resource = @"/example";
    IARoute * route = [IARoute routeWithAction:action resource:resource];

    NSString * other = @"name";
    XCTAssertFalse([route isEqual:other], @"Should not be equal");
    XCTAssertFalse(route.hash == other.hash, @"Hashes should not be equal");
}

- (void)testShortHandPut
{
    IARoute * request = [IARoute put:@""];
    XCTAssertEqualObjects(@"PUT", request.action, @"action should be PUT");
}

- (void)testShortHandGet
{
    IARoute * request = [IARoute get:@""];
    XCTAssertEqualObjects(@"GET", request.action, @"action should be GET");
}

- (void)testShortHandDelete
{
    IARoute * request = [IARoute delete:@""];
    XCTAssertEqualObjects(@"DELETE", request.action, @"action should be DELETE");
}

- (void)testShortHandPost
{
    IARoute * request = [IARoute post:@""];
    XCTAssertEqualObjects(@"POST", request.action, @"action should be POST");
}

- (void)testDescription
{
    IARoute * request = [IARoute routeWithAction:@"GET" resource:@"/example"];
    XCTAssertNotNil(request.description, @"Description should not be nil");
}

@end
