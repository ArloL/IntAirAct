#import "IADeserializationTests.h"

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
    STAssertEqualObjects(deSerialization.bodyAsString, @"[\"example string\"]", nil);
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

@end
