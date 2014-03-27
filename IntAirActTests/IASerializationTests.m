#import "IASerializationTests.h"

#import <CocoaLumberjack/DDLog.h>
#import <CocoaLumberjack/DDTTYLogger.h>
#import <IntAirAct/IntAirAct.h>

#import "IANumber.h"
#import "IAModelWithInt.h"
#import "IAModelWithFloat.h"
#import "IAModelInheritance.h"
#import "IAModelReference.h"

// Log levels : off, error, warn, info, verbose
//static const int ddLogLevel = LOG_LEVEL_VERBOSE;

@implementation IASerializationTests

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
    NSData * body = [NSData new];
    IADeSerialization * deSerialization = [[IADeSerialization alloc] initWithBody:body];
    XCTAssertEqual(deSerialization.body, body);
}

- (void)testSetBodyWithString
{
    NSString * body = @"example string";
    IADeSerialization * deSerialization = [[IADeSerialization alloc] init];
    [deSerialization setBodyWithString:body];
    XCTAssertEqualObjects(deSerialization.bodyAsString, body);
}

- (void)testSetBodyWithWithAString
{
    NSString * body = @"example string";
    IADeSerialization * deSerialization = [[IADeSerialization alloc] init];
    [deSerialization setBodyWith:body];
    XCTAssertEqualObjects(deSerialization.bodyAsString, body);
}

- (void)testSetBodyWithWithAnArrayOfString
{
    NSArray * array = @[ @"example string" ];
    IADeSerialization * deSerialization = [[IADeSerialization alloc] init];
    [deSerialization setBodyWith:array];
    XCTAssertEqualObjects(deSerialization.bodyAsString, @"[\"example string\"]");
}

- (void)testSetBodyWithWithANumber
{
    IADeSerialization * deSerialization = [[IADeSerialization alloc] init];
    [deSerialization setBodyWith:@50];
    XCTAssertEqualObjects(deSerialization.bodyAsString, @"50");
}

- (void)testSetBodyWithWithAnArrayOfNumbers
{
    NSArray * array = @[ @50 ];
    IADeSerialization * deSerialization = [[IADeSerialization alloc] init];
    [deSerialization setBodyWith:array];
    XCTAssertEqualObjects(deSerialization.bodyAsString, @"[50]");
}

- (void)testSetBodyWithWithAnNSDictionary
{
    NSDictionary * dictionary = @{ @"key" : @"value" };
    IADeSerialization * deSerialization = [[IADeSerialization alloc] init];
    [deSerialization setBodyWith:dictionary];
    XCTAssertEqualObjects(deSerialization.bodyAsString, @"{\"key\":\"value\"}");
}

- (void)testSetBodyWithWithAnNSDictionaryUsingNSNumberKeys
{
    NSDictionary * dictionary = @{ @50 : @"value" };
    IADeSerialization * deSerialization = [[IADeSerialization alloc] init];
    [deSerialization setBodyWith:dictionary];
    XCTAssertEqualObjects(deSerialization.bodyAsString, @"{\"50\":\"value\"}");
}

- (void)testSetBodyWithWithAnIANumber
{
    IANumber * number = [IANumber new];
    number.number = @50;
    IADeSerialization * deSerialization = [[IADeSerialization alloc] init];
    [deSerialization setBodyWith:number];
    NSString * expected = @"{\"number\":50}";
    XCTAssertEqualObjects(deSerialization.bodyAsString, expected);
}

- (void)testSetBodyWithWithAnIAModelWithInt
{
    IAModelWithInt * model = [IAModelWithInt new];
    model.intProperty = 50;
    IADeSerialization * deSerialization = [[IADeSerialization alloc] init];
    [deSerialization setBodyWith:model];
    NSString * expected = @"{\"intProperty\":50}";
    XCTAssertEqualObjects(deSerialization.bodyAsString, expected);
}

- (void)testSetBodyWithWithAnIAModelWithFloat
{
    IAModelWithFloat * model = [IAModelWithFloat new];
    model.floatProperty = 5.434f;
    IADeSerialization * deSerialization = [[IADeSerialization alloc] init];
    [deSerialization setBodyWith:model];
    NSString * expected = [NSString stringWithFormat:@"{\"floatProperty\":%.4g}", 5.434f];
    XCTAssertEqualObjects(deSerialization.bodyAsString, expected);
}

- (void)testSetBodyWithWithAnIAModelInheritance
{
    IAModelInheritance * model = [IAModelInheritance new];
    model.number = @50;
    model.numberTwo = @60;
    IADeSerialization * deSerialization = [[IADeSerialization alloc] init];
    [deSerialization setBodyWith:model];
    NSString * expected = [NSString stringWithFormat:@"{\"number\":50,\"numberTwo\":60}"];
    XCTAssertEqualObjects(deSerialization.bodyAsString, expected);
}

- (void)testSetBodyWithWithAnIAModelReference
{
    IAModelReference * model = [IAModelReference new];
    model.number = [IANumber new];
    model.number.number = @2;
    IADeSerialization * deSerialization = [[IADeSerialization alloc] init];
    [deSerialization setBodyWith:model];
    NSString * expected = [NSString stringWithFormat:@"{\"number\":{\"number\":2}}"];
    XCTAssertEqualObjects(deSerialization.bodyAsString, expected);
}


- (void)testSetBodyWithWithNil
{
    IADeSerialization * deSerialization = [[IADeSerialization alloc] init];
    [deSerialization setBodyWith:nil];
    NSString * expected = @"";
    XCTAssertEqualObjects(deSerialization.bodyAsString, expected);
}

- (void)testDescription
{
    IADeSerialization * deSerialization = [IADeSerialization new];
    XCTAssertNotNil(deSerialization.description);
}

@end
