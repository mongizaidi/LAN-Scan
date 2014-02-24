//
//  ScanLAN.m
//  LAN Scan
//
//  Created by Mongi Zaidi on 24 February 2014.
//  Copyright (c) 2014 Smart Touch. All rights reserved.
//

#import "ScanLAN.h"
#import <ifaddrs.h>
#import <arpa/inet.h>
#include <netdb.h>
#import "SimplePingHelper.h"

@interface ScanLAN ()

@property NSString *localAddress;
@property NSString *baseAddress;
@property NSInteger currentHostAddress;
@property NSTimer *timer;
@property NSString *netMask;
@property NSInteger baseAddressEnd;
@property NSInteger timerIterationNumber;

@end

@implementation ScanLAN

- (id)initWithDelegate:(id<ScanLANDelegate>)delegate {
    NSLog(@"init scanner");
    self = [super init];
    if(self)
    {
		self.delegate = delegate;
    }
    return self;
}

- (void)startScan {
    NSLog(@"start scan");
    self.localAddress = [self localIPAddress];
    //This is used to test on the simulator
    //self.localAddress = @"192.168.1.8";
    //self.netMask = @"255.255.255.0";
    NSArray *a = [self.localAddress componentsSeparatedByString:@"."];
    NSArray *b = [self.netMask componentsSeparatedByString:@"."];
    if ([self isIpAddressValid:self.localAddress] && (a.count == 4) && (b.count == 4)) {
        for (int i = 0; i<4; i++) {
            int and = [[a objectAtIndex:i] integerValue] & [[b objectAtIndex:i] integerValue];
            if (!self.baseAddress.length) {
                self.baseAddress = [NSString stringWithFormat:@"%d", and];
            }
            else {
                self.baseAddress = [NSString stringWithFormat:@"%@.%d", self.baseAddress, and];
                self.currentHostAddress = and;
                self.baseAddressEnd = and;
            }
        }
        self.timer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(pingAddress) userInfo:nil repeats:YES];
    }
}

- (void)stopScan {
    NSLog(@"stop scan");
    [self.timer invalidate];
}

- (void)pingAddress{
    self.currentHostAddress++;
    NSString *address = [NSString stringWithFormat:@"%@%d", self.baseAddress, self.currentHostAddress];
    [SimplePingHelper ping:address target:self sel:@selector(pingResult:)];
    if (self.currentHostAddress>=254) {
        [self.timer invalidate];
    }
}
/*
 - (void)pingAddress:(NSString *)address{
 [SimplePingHelper ping:address target:self sel:@selector(pingResult:)];
 }
 */
- (void)pingResult:(NSNumber*)success {
    self.timerIterationNumber++;
    if (success.boolValue) {
        NSLog(@"SUCCESS");
        NSString *deviceIPAddress = [[[[NSString stringWithFormat:@"%@%d", self.baseAddress, self.currentHostAddress] stringByReplacingOccurrencesOfString:@".0" withString:@"."] stringByReplacingOccurrencesOfString:@".00" withString:@"."] stringByReplacingOccurrencesOfString:@".." withString:@".0."];
        NSString *deviceName = [self getHostFromIPAddress:[[NSString stringWithFormat:@"%@%d", self.baseAddress, self.currentHostAddress] cStringUsingEncoding:NSASCIIStringEncoding]];
        [self.delegate scanLANDidFindNewAdrress:deviceIPAddress havingHostName:deviceName];
    }
    else {
        NSLog(@"FAILURE");
    }
    if (self.timerIterationNumber+self.baseAddressEnd>=254) {
        [self.delegate scanLANDidFinishScanning];
    }
}

- (NSString *)getHostFromIPAddress:(const char*)ipAddress {
    NSString *hostName = nil;
    int error;
    struct addrinfo *results = NULL;
    
    error = getaddrinfo(ipAddress, NULL, NULL, &results);
    if (error != 0)
    {
        NSLog (@"Could not get any info for the address");
        return nil; // or exit(1);
    }
    
    for (struct addrinfo *r = results; r; r = r->ai_next)
    {
        char hostname[NI_MAXHOST] = {0};
        error = getnameinfo(r->ai_addr, r->ai_addrlen, hostname, sizeof hostname, NULL, 0 , 0);
        if (error != 0)
        {
            continue; // try next one
        }
        else
        {
            NSLog (@"Found hostname: %s", hostname);
            hostName = [NSString stringWithFormat:@"%s", hostname];
            break;
        }
        freeaddrinfo(results);
    }
    return hostName;
}

// Get IP Address
- (NSString *)getIPAddress
{
    struct ifaddrs *interfaces = NULL;
    struct ifaddrs *temp_addr = NULL;
    NSString *wifiAddress = nil;
    NSString *cellAddress = nil;
    
    // retrieve the current interfaces - returns 0 on success
    if(!getifaddrs(&interfaces)) {
        // Loop through linked list of interfaces
        temp_addr = interfaces;
        while(temp_addr != NULL) {
            sa_family_t sa_type = temp_addr->ifa_addr->sa_family;
            if(sa_type == AF_INET || sa_type == AF_INET6) {
                NSString *name = [NSString stringWithUTF8String:temp_addr->ifa_name];
                NSString *addr = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr)]; // pdp_ip0
                //NSLog(@"NAME: \"%@\" addr: %@", name, addr); // see for yourself
                
                if([name isEqualToString:@"en0"]) {
                    // Interface is the wifi connection on the iPhone
                    wifiAddress = addr;
                } else
                    if([name isEqualToString:@"pdp_ip0"]) {
                        // Interface is the cell connection on the iPhone
                        cellAddress = addr;
                    }
            }
            temp_addr = temp_addr->ifa_next;
        }
        // Free memory
        freeifaddrs(interfaces);
    }
    NSString *addr = wifiAddress ? wifiAddress : cellAddress;
    return addr ? addr : @"0.0.0.0";
}

- (NSString *) localIPAddress
{
    NSString *address = @"error";
    struct ifaddrs *interfaces = NULL;
    struct ifaddrs *temp_addr = NULL;
    int success = 0;
    
    // retrieve the current interfaces - returns 0 on success
    success = getifaddrs(&interfaces);
    
    if (success == 0)
    {
        temp_addr = interfaces;
        
        while(temp_addr != NULL)
        {
            // check if interface is en0 which is the wifi connection on the iPhone
            if(temp_addr->ifa_addr->sa_family == AF_INET)
            {
                if([[NSString stringWithUTF8String:temp_addr->ifa_name] isEqualToString:@"en0"])
                {
                    address = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr)];
                    self.netMask = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_netmask)->sin_addr)];
                }
            }
            
            temp_addr = temp_addr->ifa_next;
        }
    }
    
    freeifaddrs(interfaces);
    
    return address;
}

- (BOOL) isIpAddressValid:(NSString *)ipAddress{
    struct in_addr pin;
    int success = inet_aton([ipAddress UTF8String],&pin);
    if (success == 1) return TRUE;
    return FALSE;
}

@end
