//
//  SimplePingHelper.h
//  LAN Scan
//
//  Created by Mongi Zaidi on 24 February 2014.
//  Copyright (c) 2014 Smart Touch. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SimplePing.h"

@interface SimplePingHelper : NSObject <SimplePingDelegate>

+ (void)ping:(NSString*)address target:(id)target sel:(SEL)sel;

@end
