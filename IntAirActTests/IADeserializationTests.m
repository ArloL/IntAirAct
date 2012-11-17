#import "IADeserializationTests.h"

#import <CocoaLumberjack/DDLog.h>
#import <CocoaLumberjack/DDTTYLogger.h>
#import <IntAirAct/IntAirAct.h>

#import "IANumber.h"

// Log levels : off, error, warn, info, verbose
static const int ddLogLevel = LOG_LEVEL_VERBOSE;

@implementation IADeserializationTests

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

- (void)testConstructor
{
    NSData * body = [NSData new];
    IADeSerialization * deSerialization = [[IADeSerialization alloc] initWithBody:body];
    STAssertEquals(body, deSerialization.body, @"Body should be the same");
}

- (void)testSetBodyWithString
{
    NSString * body = @"example string";
    IADeSerialization * deSerialization = [[IADeSerialization alloc] init];
    [deSerialization setBodyWithString:body];
    STAssertEqualObjects(body, deSerialization.bodyAsString, @"Should be 'example string'");
}

- (void)testSetBodyWithWithAString
{
    NSString * body = @"example string";
    IADeSerialization * deSerialization = [[IADeSerialization alloc] init];
    [deSerialization setBodyWith:body];
    STAssertEqualObjects(body, deSerialization.bodyAsString, @"Should be 'example string'");
}

- (void)testSetBodyWithWithAnNSArrayOfString
{
    NSArray * array = @[ @"example string" ];
    IADeSerialization * deSerialization = [[IADeSerialization alloc] init];
    [deSerialization setBodyWith:array];
    STAssertEqualObjects(@"[\"example string\"]", deSerialization.bodyAsString, @"Should be 'example string'");
}

- (void)testSetBodyWithWithAnNSArrayOfNSNumber
{
    NSArray * array = @[ @50 ];
    IADeSerialization * deSerialization = [[IADeSerialization alloc] init];
    [deSerialization setBodyWith:array];
    STAssertEqualObjects(@"[50]", deSerialization.bodyAsString, @"Should be 'example string'");
}

- (void)testSetBodyWithWithAnNSNumber
{
    IADeSerialization * deSerialization = [[IADeSerialization alloc] init];
    [deSerialization setBodyWith:@50];
    STAssertEqualObjects(@"50", deSerialization.bodyAsString, @"Should be 'example string'");
}

- (void)testSetBodyWithWithAnIANumber
{
    IANumber * number = [IANumber new];
    number.number = @50;
    IADeSerialization * deSerialization = [[IADeSerialization alloc] init];
    [deSerialization setBodyWith:number];
    NSString * expected = @"{\"number\":50}";
    STAssertEqualObjects(expected, deSerialization.bodyAsString, @"Should be the same");
}

- (void)testDescription
{
    IADeSerialization * deSerialization = [IADeSerialization new];
    STAssertNotNil(deSerialization.description, @"Description should not be nil");
}

@end
