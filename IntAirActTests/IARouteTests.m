#import "IARouteTests.h"

#import <CocoaLumberjack/DDLog.h>
#import <CocoaLumberjack/DDTTYLogger.h>
#import <IntAirAct/IntAirAct.h>

// Log levels : off, error, warn, info, verbose
static const int ddLogLevel = LOG_LEVEL_VERBOSE;

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
    STAssertEqualObjects(route.action, @"GET", nil);
    STAssertEqualObjects(route.resource, @"/example", nil);
}

- (void)testEquals
{
    IARoute * route = [IARoute routeWithAction:@"GET" resource:@"/example"];
    IARoute * other = [IARoute routeWithAction:@"GET" resource:@"/example"];
    STAssertTrue([route isEqual:other], nil);
    STAssertEquals(route.hash, other.hash, nil);
}

- (void)testEqualsSelf
{
    IARoute * route = [IARoute routeWithAction:@"GET" resource:@"/example"];
    IARoute * other = route;
    STAssertTrue([route isEqual:other], nil);
    STAssertEquals(route.hash, other.hash, nil);
}

- (void)testEqualsNil
{
    IARoute * route = [IARoute routeWithAction:@"GET" resource:@"/example"];
    IARoute * other = nil;
    STAssertFalse([route isEqual:other], nil);
}

- (void)testEqualsDifferentAction
{
    IARoute * route = [IARoute routeWithAction:@"GET" resource:@"/example"];
    IARoute * other = [IARoute routeWithAction:@"PUT" resource:@"/example"];
    STAssertFalse([route isEqual:other], nil);
    STAssertFalse(route.hash == other.hash, nil);
}

- (void)testEqualsDifferentResource
{
    IARoute * route = [IARoute routeWithAction:@"GET" resource:@"/example"];
    IARoute * other = [IARoute routeWithAction:@"GET" resource:@"/example2"];
    STAssertFalse([route isEqual:other], nil);
    STAssertFalse(route.hash == other.hash, nil);
}

- (void)testEqualsActionIsNull
{
    IARoute * route = [IARoute routeWithAction:nil resource:@"/example"];
    IARoute * other = [IARoute routeWithAction:@"GET" resource:@"/example"];
    STAssertFalse([route isEqual:other], nil);
    STAssertFalse(route.hash == other.hash, nil);
}

- (void)testEqualsResourceIsNull
{
    IARoute * route = [IARoute routeWithAction:@"GET" resource:nil];
    IARoute * other = [IARoute routeWithAction:@"GET" resource:@"/example"];
    STAssertFalse([route isEqual:other], nil);
    STAssertFalse(route.hash == other.hash, nil);
}

- (void)testEqualsWithDifferentObject
{
    NSString * action = @"GET";
    NSString * resource = @"/example";
    IARoute * route = [IARoute routeWithAction:action resource:resource];

    NSString * other = @"name";
    STAssertFalse([route isEqual:other], @"Should not be equal");
    STAssertFalse(route.hash == other.hash, @"Hashes should not be equal");
}

- (void)testShortHandPut
{
    IARoute * request = [IARoute put:@""];
    STAssertEqualObjects(@"PUT", request.action, @"action should be PUT");
}

- (void)testShortHandGet
{
    IARoute * request = [IARoute get:@""];
    STAssertEqualObjects(@"GET", request.action, @"action should be GET");
}

- (void)testShortHandDelete
{
    IARoute * request = [IARoute delete:@""];
    STAssertEqualObjects(@"DELETE", request.action, @"action should be DELETE");
}

- (void)testShortHandPost
{
    IARoute * request = [IARoute post:@""];
    STAssertEqualObjects(@"POST", request.action, @"action should be POST");
}

- (void)testDescription
{
    IARoute * request = [IARoute routeWithAction:@"GET" resource:@"/example"];
    STAssertNotNil(request.description, @"Description should not be nil");
}

@end
