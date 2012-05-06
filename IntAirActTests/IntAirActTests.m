#import "IntAirActTests.h"

#import <IntAirAct/IntAirAct.h>

@interface IntAirActTests ()

@property (nonatomic, strong) IAIntAirAct * intAirAct;

@end

@implementation IntAirActTests

@synthesize intAirAct;

-(void)setUp
{
    [super setUp];
    self.intAirAct = [IAIntAirAct new];
}

-(void)tearDown
{
    [super tearDown];
}

-(void)testStart
{
    NSError * error = nil;
	if (![self.intAirAct start:&error]) {
		STFail(@"HTTP server failed to start: %@", error);
	}
}

@end
