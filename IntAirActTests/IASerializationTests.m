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
static const int ddLogLevel = LOG_LEVEL_VERBOSE;

@implementation IASerializationTests

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
    STAssertEquals(deSerialization.body, body, nil);
}

- (void)testSetBodyWithString
{
    NSString * body = @"example string";
    IADeSerialization * deSerialization = [[IADeSerialization alloc] init];
    [deSerialization setBodyWithString:body];
    STAssertEqualObjects(deSerialization.bodyAsString, body, nil);
}

- (void)testSetBodyWithWithAString
{
    NSString * body = @"example string";
    IADeSerialization * deSerialization = [[IADeSerialization alloc] init];
    [deSerialization setBodyWith:body];
    STAssertEqualObjects(deSerialization.bodyAsString, body, nil);
}

- (void)testSetBodyWithWithAnNSArrayOfString
{
    NSArray * array = @[ @"example string" ];
    IADeSerialization * deSerialization = [[IADeSerialization alloc] init];
    [deSerialization setBodyWith:array];
    STAssertEqualObjects(deSerialization.bodyAsString, @"[\"example string\"]", nil);
}

- (void)testSetBodyWithWithAnNSNumber
{
    IADeSerialization * deSerialization = [[IADeSerialization alloc] init];
    [deSerialization setBodyWith:@50];
    STAssertEqualObjects(deSerialization.bodyAsString, @"50", nil);
}

- (void)testSetBodyWithWithAnNSArrayOfNSNumber
{
    NSArray * array = @[ @50 ];
    IADeSerialization * deSerialization = [[IADeSerialization alloc] init];
    [deSerialization setBodyWith:array];
    STAssertEqualObjects(deSerialization.bodyAsString, @"[50]", nil);
}

- (void)testSetBodyWithWithAnNSDictionary
{
    NSDictionary * dictionary = @{ @"key" : @"value" };
    IADeSerialization * deSerialization = [[IADeSerialization alloc] init];
    [deSerialization setBodyWith:dictionary];
    STAssertEqualObjects(deSerialization.bodyAsString, @"{\"key\":\"value\"}", nil);
}

- (void)testSetBodyWithWithAnNSDictionaryUsingNSNumberKeys
{
    NSDictionary * dictionary = @{ @50 : @"value" };
    IADeSerialization * deSerialization = [[IADeSerialization alloc] init];
    [deSerialization setBodyWith:dictionary];
    STAssertEqualObjects(deSerialization.bodyAsString, @"{}", nil);
}

- (void)testSetBodyWithWithAnIANumber
{
    IANumber * number = [IANumber new];
    number.number = @50;
    IADeSerialization * deSerialization = [[IADeSerialization alloc] init];
    [deSerialization setBodyWith:number];
    NSString * expected = @"{\"number\":50}";
    STAssertEqualObjects(deSerialization.bodyAsString, expected, nil);
}

- (void)testSetBodyWithWithAnIAModelWithInt
{
    IAModelWithInt * model = [IAModelWithInt new];
    model.intProperty = 50;
    IADeSerialization * deSerialization = [[IADeSerialization alloc] init];
    [deSerialization setBodyWith:model];
    NSString * expected = @"{\"intProperty\":50}";
    STAssertEqualObjects(deSerialization.bodyAsString, expected, nil);
}

- (void)testSetBodyWithWithAnIAModelWithFloat
{
    IAModelWithFloat * model = [IAModelWithFloat new];
    model.floatProperty = 5.434;
    IADeSerialization * deSerialization = [[IADeSerialization alloc] init];
    [deSerialization setBodyWith:model];
    NSString * expected = [NSString stringWithFormat:@"{\"floatProperty\":%.17g}", 5.434f];
    STAssertEqualObjects(deSerialization.bodyAsString, expected, nil);
}

- (void)testSetBodyWithWithAnIAModelInheritance
{
    IAModelInheritance * model = [IAModelInheritance new];
    model.number = @50;
    model.numberTwo = @60;
    IADeSerialization * deSerialization = [[IADeSerialization alloc] init];
    [deSerialization setBodyWith:model];
    NSString * expected = [NSString stringWithFormat:@"{\"number\":50,\"numberTwo\":60}"];
    STAssertEqualObjects(deSerialization.bodyAsString, expected, nil);
}

- (void)testSetBodyWithWithAnIAModelReference
{
    IAModelReference * model = [IAModelReference new];
    model.number = [IANumber new];
    model.number.number = @2;
    IADeSerialization * deSerialization = [[IADeSerialization alloc] init];
    [deSerialization setBodyWith:model];
    NSString * expected = [NSString stringWithFormat:@"{\"number\":{\"number\":2}}"];
    STAssertEqualObjects(deSerialization.bodyAsString, expected, nil);
}


- (void)testSetBodyWithWithNil
{
    IADeSerialization * deSerialization = [[IADeSerialization alloc] init];
    [deSerialization setBodyWith:nil];
    NSString * expected = @"";
    STAssertEqualObjects(deSerialization.bodyAsString, expected, nil);
}

- (void)testDescription
{
    IADeSerialization * deSerialization = [IADeSerialization new];
    STAssertNotNil(deSerialization.description, nil);
}

@end
