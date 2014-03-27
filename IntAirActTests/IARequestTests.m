#import "IARequestTests.h"

#import <CocoaLumberjack/DDLog.h>
#import <CocoaLumberjack/DDTTYLogger.h>
#import <IntAirAct/IntAirAct.h>

// Log levels : off, error, warn, info, verbose
//static const int ddLogLevel = LOG_LEVEL_VERBOSE;

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
    NSMutableDictionary * metadata = [NSMutableDictionary new];
    NSMutableDictionary * parameters = [NSMutableDictionary new];
    IADevice * origin = [IADevice deviceWithName:@"name" host:@"host" port:8080 supportedRoutes:[NSSet new]];
    NSData * body = [NSData new];
    IARequest * request = [IARequest requestWithRoute:route metadata:metadata parameters:parameters origin:origin body:body];
    XCTAssertEqual(route, request.route, @"route should be the same");
    XCTAssertEqual(metadata, request.metadata, @"metadata should be the same");
    XCTAssertEqual(parameters, request.parameters, @"parameters should be the same");
    XCTAssertEqual(origin, request.origin, @"origin should be the same");
    XCTAssertEqual(body, request.body, @"body should be the same");
}

- (void)testDescription
{
    IARoute * route = [IARoute routeWithAction:@"action" resource:@"resource"];
    NSMutableDictionary * metadata = [NSMutableDictionary new];
    NSMutableDictionary * parameters = [NSMutableDictionary new];
    IADevice * origin = [IADevice deviceWithName:@"name" host:@"host" port:8080 supportedRoutes:[NSSet new]];
    NSData * body = [NSData new];
    IARequest * request = [IARequest requestWithRoute:route metadata:metadata parameters:parameters origin:origin body:body];
    XCTAssertNotNil(request.description, @"Description should not be nil");
}

@end
