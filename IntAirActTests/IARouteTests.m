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

- (void)testEquals
{
    NSString * action = @"GET";
    NSString * resource = @"/example";
    IARoute * route = [IARoute routeWithAction:action resource:resource];
    IARoute * other = [IARoute routeWithAction:action resource:resource];
    STAssertEqualObjects(route, other, @"Should be equal");
    STAssertEquals(route.hash, other.hash, @"Hashes should be equal");
}

- (void)testEqualsWithSelf
{
    NSString * action = @"GET";
    NSString * resource = @"/example";
    IARoute * route = [IARoute routeWithAction:action resource:resource];
    STAssertTrue([route isEqual:route], @"Should be equal");
    STAssertEquals(route.hash, route.hash, @"Hashes should be equal");
}

- (void)testEqualsFails
{
    NSString * action = @"GET";
    NSString * differentAction = @"PUT";

    NSString * resource = @"/example";
    
    IARoute * route = [IARoute routeWithAction:action resource:resource];
    IARoute * other = [IARoute routeWithAction:differentAction resource:resource];
    STAssertFalse([route isEqual:other], @"Should not be equal");
    STAssertFalse(route.hash == other.hash, @"Hashes should not be equal");
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

- (void)testDescription
{
    IARoute * request = [IARoute routeWithAction:@"GET" resource:@"/example"];
    STAssertNotNil(request.description, @"Description should not be nil");
}

- (void)testShortHandPut
{
    IARoute * request = [IARoute put:@""];
    STAssertEquals(@"PUT", request.action, @"action should be PUT");
}

- (void)testShortHandGet
{
    IARoute * request = [IARoute get:@""];
    STAssertEquals(@"GET", request.action, @"action should be GET");
}

- (void)testShortHandDelete
{
    IARoute * request = [IARoute delete:@""];
    STAssertEquals(@"DELETE", request.action, @"action should be DELETE");
}

- (void)testShortHandPost
{
    IARoute * request = [IARoute post:@""];
    STAssertEquals(@"POST", request.action, @"action should be POST");
}

@end
