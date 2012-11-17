#import "IARequestTests.h"

#import <CocoaLumberjack/DDLog.h>
#import <CocoaLumberjack/DDTTYLogger.h>
#import <IntAirAct/IntAirAct.h>

// Log levels : off, error, warn, info, verbose
static const int ddLogLevel = LOG_LEVEL_VERBOSE;

@implementation IARequestTests

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
    IARoute * route = [IARoute routeWithAction:@"action" resource:@"resource"];
    NSDictionary * metadata = @{};
    NSDictionary * parameters = @{};
    IADevice * origin = [IADevice deviceWithName:@"name" host:@"host" port:8080 supportedRoutes:[NSSet new]];
    NSData * body = [NSData new];
    IARequest * request = [IARequest requestWithRoute:route metadata:metadata parameters:parameters origin:origin body:body];
    STAssertEquals(route, request.route, @"route should be the same");
    STAssertEquals(metadata, request.metadata, @"metadata should be the same");
    STAssertEquals(parameters, request.parameters, @"parameters should be the same");
    STAssertEquals(origin, request.origin, @"origin should be the same");
    STAssertEquals(body, request.body, @"body should be the same");
}

- (void)testDescription
{
    IARoute * route = [IARoute routeWithAction:@"action" resource:@"resource"];
    NSDictionary * metadata = @{};
    NSDictionary * parameters = @{};
    IADevice * origin = [IADevice deviceWithName:@"name" host:@"host" port:8080 supportedRoutes:[NSSet new]];
    NSData * body = [NSData new];
    IARequest * request = [IARequest requestWithRoute:route metadata:metadata parameters:parameters origin:origin body:body];
    STAssertNotNil(request.description, @"Description should not be nil");
}

@end
