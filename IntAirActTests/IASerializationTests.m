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

- (void)testSetBodyWithAString
{
    NSString * body = @"example string";
    IADeSerialization * deSerialization = [[IADeSerialization alloc] init];
    [deSerialization setBodyWith:body];
    XCTAssertEqualObjects(deSerialization.bodyAsString, body);
}

- (void)testSetBodyWithAnArrayOfString
{
    NSArray * array = @[ @"example string" ];
    IADeSerialization * deSerialization = [[IADeSerialization alloc] init];
    [deSerialization setBodyWith:array];
    XCTAssertEqualObjects(deSerialization.bodyAsString, @"[\"example string\"]");
}

- (void)testSetBodyWithANumber
{
    IADeSerialization * deSerialization = [[IADeSerialization alloc] init];
    [deSerialization setBodyWith:@50];
    XCTAssertEqualObjects(deSerialization.bodyAsString, @"50");
}

- (void)testSetBodyWithAnArrayOfNumbers
{
    NSArray * array = @[ @50 ];
    IADeSerialization * deSerialization = [[IADeSerialization alloc] init];
    [deSerialization setBodyWith:array];
    XCTAssertEqualObjects(deSerialization.bodyAsString, @"[50]");
}

- (void)testSetBodyWithAnNSDictionary
{
    NSDictionary * dictionary = @{ @"key" : @"value" };
    IADeSerialization * deSerialization = [[IADeSerialization alloc] init];
    [deSerialization setBodyWith:dictionary];
    XCTAssertEqualObjects(deSerialization.bodyAsString, @"{\"key\":\"value\"}");
}

- (void)testSetBodyWithAnNSDictionaryUsingNSNumberKeys
{
    NSDictionary * dictionary = @{ @50 : @"value" };
    IADeSerialization * deSerialization = [[IADeSerialization alloc] init];
    [deSerialization setBodyWith:dictionary];
    XCTAssertEqualObjects(deSerialization.bodyAsString, @"{\"50\":\"value\"}");
}

- (void)testSetBodyWithAnIANumber
{
    IANumber * number = [IANumber new];
    number.number = @50;
    IADeSerialization * deSerialization = [[IADeSerialization alloc] init];
    [deSerialization setBodyWith:number];
    NSString * expected = @"{\"number\":50}";
    XCTAssertEqualObjects(deSerialization.bodyAsString, expected);
}

- (void)testSetBodyWithAnIAModelWithInt
{
    IAModelWithInt * model = [IAModelWithInt new];
    model.intProperty = 50;
    IADeSerialization * deSerialization = [[IADeSerialization alloc] init];
    [deSerialization setBodyWith:model];
    NSString * expected = @"{\"intProperty\":50}";
    XCTAssertEqualObjects(deSerialization.bodyAsString, expected);
}

- (void)testSetBodyWithAnIAModelWithFloat
{
    IAModelWithFloat * model = [IAModelWithFloat new];
    model.floatProperty = 5.434f;
    IADeSerialization * deSerialization = [[IADeSerialization alloc] init];
    [deSerialization setBodyWith:model];
    NSString * expected = [NSString stringWithFormat:@"{\"floatProperty\":%.4g}", 5.434f];
    XCTAssertEqualObjects(deSerialization.bodyAsString, expected);
}

- (void)testSetBodyWithAnIAModelInheritance
{
    IAModelInheritance * model = [IAModelInheritance new];
    model.number = @50;
    model.numberTwo = @60;
    IADeSerialization * deSerialization = [[IADeSerialization alloc] init];
    [deSerialization setBodyWith:model];
    NSString * expected = [NSString stringWithFormat:@"{\"number\":50,\"numberTwo\":60}"];
    XCTAssertEqualObjects(deSerialization.bodyAsString, expected);
}

- (void)testSetBodyWithAnIAModelReference
{
    IAModelReference * model = [IAModelReference new];
    model.number = [IANumber new];
    model.number.number = @2;
    IADeSerialization * deSerialization = [[IADeSerialization alloc] init];
    [deSerialization setBodyWith:model];
    NSString * expected = [NSString stringWithFormat:@"{\"number\":{\"number\":2}}"];
    XCTAssertEqualObjects(deSerialization.bodyAsString, expected);
}


- (void)testSetBodyWithNil
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
