//
//  ScanLAN.h
//  LAN Scan
//
//  Created by Mongi Zaidi on 24 February 2014.
//  Copyright (c) 2014 Smart Touch. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol ScanLANDelegate <NSObject>

@optional
- (void)scanLANDidFindNewAdrress:(NSString *)address havingHostName:(NSString *)hostName;
- (void)scanLANDidFinishScanning;
@end

@interface ScanLAN : NSObject

@property(nonatomic,weak) id<ScanLANDelegate> delegate;

- (id)initWithDelegate:(id<ScanLANDelegate>)delegate;
- (void)startScan;
- (void)stopScan;

@end
