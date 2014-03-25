#import "IANSURLAdapterTests.h"

#import <CocoaLumberjack/DDLog.h>
#import <CocoaLumberjack/DDTTYLogger.h>
#import <IntAirAct/IntAirAct.h>

#import "NSURL+QueryParameters.h"

// Log levels : off, error, warn, info, verbose
//static const int ddLogLevel = LOG_LEVEL_VERBOSE;

@implementation IANSURLAdapterTests

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

-(void)testURLQueryParametersWithEmptyString
{
    NSURL * expected = [NSURL URLWithString:@"http://example.com/"];
    NSURL * actual = [expected URLByAppendingQueryString:@""];
    STAssertEqualObjects(actual, expected, nil);
}

@end
