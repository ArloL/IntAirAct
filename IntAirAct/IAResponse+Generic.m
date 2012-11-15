#import "IAResponse+Generic.h"

#import <UIKit/UIKit.h>

#import "IAResponse+Image.h"

@implementation IAResponse (Generic)

-(void)respondWith:(id)data
{
    if([data isKindOfClass:[UIImage class]]) {
        [self respondWithImage:data];
    } else if ([data isKindOfClass:[NSArray class]]) {
#warning serialization not implemented
        [self respondWithString:@"[]"];
    }
}

@end
