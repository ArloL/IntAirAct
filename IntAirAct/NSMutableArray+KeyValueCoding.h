//
//  NSMutableArray+KeyValueCoding.h
//  IntAirAct
//
//  Created by O'Keeffe Arlo Louis on 2012-05-05.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSMutableArray (KeyValueCoding)

-(void)setValue:(id)value forKey:(NSString *)key;
-(id)valueForKey:(NSString *)key;

@end
