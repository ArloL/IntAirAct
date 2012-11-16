#import "IAResponseTests.h"

#import <CocoaLumberjack/DDLog.h>
#import <CocoaLumberjack/DDTTYLogger.h>
#import <IntAirAct/IntAirAct.h>

// Log levels : off, error, warn, info, verbose
static const int ddLogLevel = LOG_LEVEL_VERBOSE;

@implementation IAResponseTests

-(void)logging
{
    static dispatch_once_t once;
    dispatch_once(&once, ^ {
        [DDLog addLogger:[DDTTYLogger sharedInstance]];
        [[DDTTYLogger sharedInstance] setColorsEnabled:YES];
    });
}

-(void)setUp
{
    [super setUp];

    // Set-up code here.
    [self logging];
}

-(void)tearDown
{
    // Tear-down code here.

    [super tearDown];
}

- (void)testDescription
{
    IAResponse * request = [IAResponse new];
    STAssertNotNil(request.description, @"Description should not be nil");
}

@end
