#import "IADeserializationTests.h"

#import <CocoaLumberjack/DDLog.h>
#import <CocoaLumberjack/DDTTYLogger.h>
#import <IntAirAct/IntAirAct.h>

#import "IANumber.h"
#import "IAModelWithInt.h"
#import "IAModelWithFloat.h"
#import "IAModelInheritance.h"
#import "IAModelReference.h"
#import "IAModelWithString.h"

// Log levels : off, error, warn, info, verbose
//static const int ddLogLevel = LOG_LEVEL_VERBOSE;

@implementation IADeserializationTests

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

- (void)testBodyAsNSString
{
    NSString * body = @"example string";
    IADeSerialization * deSerialization = [IADeSerialization new];
    [deSerialization setBodyWithString:body];
    NSString * value = [deSerialization bodyAs:[NSString class]];
    STAssertEqualObjects(value, body, nil);
}

- (void)testBodyAsNSNumber
{
    NSNumber * body = @50;
    IADeSerialization * deSerialization = [IADeSerialization new];
    [deSerialization setBodyWith:body];
    NSNumber * value = [deSerialization bodyAs:[NSNumber class]];
    STAssertEqualObjects(value, body, nil);
}

- (void)testBodyAsNSNumberDirectly
{
    NSNumber * body = @50;
    IADeSerialization * deSerialization = [IADeSerialization new];
    [deSerialization setBodyWith:body];
    NSNumber * value = [deSerialization bodyAsNumber];
    STAssertEqualObjects(value, body, nil);
}

- (void)testBodyAsAnNSArrayOfString
{
    NSArray * array = @[ @"example string" ];
    IADeSerialization * deSerialization = [IADeSerialization new];
    [deSerialization setBodyWith:array];
    NSArray * value = [deSerialization bodyAs:[NSArray class]];
    STAssertEqualObjects(value, array, nil);
}

- (void)testBodyAsAnNSArrayOfNSNumber
{
    NSArray * array = @[ @50 ];
    IADeSerialization * deSerialization = [IADeSerialization new];
    [deSerialization setBodyWith:array];
    NSArray * value = [deSerialization bodyAs:[NSArray class]];
    STAssertEqualObjects(value, array, nil);
}

- (void)testBodyAsAnNSDictionary
{
    NSDictionary * dictionary = @{ @"key" : @"value" };
    IADeSerialization * deSerialization = [IADeSerialization new];
    [deSerialization setBodyWith:dictionary];
    NSDictionary * value = [deSerialization bodyAs:[NSDictionary class]];
    STAssertEqualObjects(value, dictionary, nil);
}

- (void)testBodyAsAnIANumber
{
    IANumber * number = [IANumber new];
    number.number = @50;
    IADeSerialization * deSerialization = [IADeSerialization new];
    [deSerialization setBodyWith:number];
    IANumber * value = [deSerialization bodyAs:[IANumber class]];
    STAssertEqualObjects(value, number, nil);
}

- (void)testBodyAsAnIAModelWithInt
{
    IAModelWithInt * model = [IAModelWithInt new];
    model.intProperty = 50;
    IADeSerialization * deSerialization = [IADeSerialization new];
    [deSerialization setBodyWith:model];
    IAModelWithInt * value = [deSerialization bodyAs:[IAModelWithInt class]];
    STAssertEquals(value.intProperty, model.intProperty, nil);
}

- (void)testBodyAsAnIAModelWithFloat
{
    IAModelWithFloat * model = [IAModelWithFloat new];
    model.floatProperty = 5.434;
    IADeSerialization * deSerialization = [IADeSerialization new];
    [deSerialization setBodyWith:model];
    IAModelWithFloat * value = [deSerialization bodyAs:[IAModelWithFloat class]];
    STAssertEquals(value.floatProperty, model.floatProperty, nil);
}

- (void)testBodyAsAnIAModelInheritance
{
    IAModelInheritance * model = [IAModelInheritance new];
    model.number = @50;
    model.numberTwo = @60;
    IADeSerialization * deSerialization = [IADeSerialization new];
    [deSerialization setBodyWith:model];
    IAModelInheritance * value = [deSerialization bodyAs:[IAModelInheritance class]];
    STAssertEqualObjects(value, model, nil);
}

- (void)testBodyAsAnIAModelReference
{
    IANumber * number = [IANumber new];
    number.number = @50;
    IAModelReference * model = [IAModelReference new];
    model.number = number;
    IADeSerialization * deSerialization = [IADeSerialization new];
    [deSerialization setBodyWith:model];
    IAModelReference * value = [deSerialization bodyAs:[IAModelReference class]];
    STAssertEqualObjects(value, model, nil);
}

- (void)testBodyAsReturnsNil
{
    IADeSerialization * deSerialization = [IADeSerialization new];
    [deSerialization setBodyWithString:@"-"];
    IANumber * value = [deSerialization bodyAs:[IANumber class]];
    STAssertNil(value, nil);
}

- (void)testStringBodyAsNumber
{
    IADeSerialization * deSerialization = [IADeSerialization new];
    [deSerialization setBodyWithString:@"{\"number\":50.6}"];
    IANumber * value = [deSerialization bodyAs:[IANumber class]];
    IANumber * expected = [IANumber new];
    expected.number = @50.6;
    STAssertEqualObjects(value, expected, nil);
}

- (void)testStringBodyAsString
{
    IADeSerialization * deSerialization = [IADeSerialization new];
    [deSerialization setBodyWithString:@"{\"stringProperty\":\"50.6\"}"];
    IAModelWithString * value = [deSerialization bodyAs:[IAModelWithString class]];
    IAModelWithString * expected = [IAModelWithString new];
    expected.stringProperty = @"50.6";
    STAssertEqualObjects(value, expected, nil);
}

@end
