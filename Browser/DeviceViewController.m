//
//  DeviceViewController.m
//  Browser
//
//  Created by Dmitry Ponomarev on 6/28/13.
//  Copyright (c) 2013 adonweb. All rights reserved.
//

#import "DeviceViewController.h"

#import "ODIN.h"
#import "OpenUDID.h"

#include <sys/socket.h>
#include <sys/sysctl.h>
#include <net/if.h>
#include <net/if_dl.h>
#include <mach/mach_host.h>

@interface DeviceViewController ()

- (NSString *)getMacAddress;
- (NSNumber *)countCores;
- (NSNumber *)activeMemory;
- (NSNumber *)freeMemory;
- (NSNumber *)commonMemory;

@end

@implementation DeviceViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSMutableDictionary *info = [NSMutableDictionary dictionary];
    
    // Device info
    UIDevice *currentDevice = [UIDevice currentDevice];
    [info setValue:[currentDevice model] forKey:@"Model"];
    [info setValue:[currentDevice systemVersion] forKey:@"System Version"];
    float version = [[currentDevice systemVersion] floatValue];
    if (version>=2.0 && version<6.0) {
        [info setValue:currentDevice.uniqueIdentifier forKey:@"UUID uniqueIdentifier"];
    } else if (version>=6.0) {
        [info setValue:currentDevice.identifierForVendor forKey:@"UUID identifierForVendor"];
    }
    
    [info setValue:ODIN1() forKey:@"UUID ODIN1"];
    [info setValue:[OpenUDID value] forKey:@"UUID OpenUUID"];
    
    [info setValue:[self getMacAddress] forKey:@"Mac Address"];
    [info setValue:[self countCores] forKey:@"CPU core count"];

    [info setValue:[self activeMemory] forKey:@"Memory active"];
    [info setValue:[self freeMemory] forKey:@"Memory free"];
    [info setValue:[self commonMemory] forKey:@"Memory common"];
    
    // Make info string
    NSMutableString *sinfo = [NSMutableString string];
    NSArray *keys = [[info allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
    for (NSString *k in keys) {
        [sinfo appendFormat:@"%@: %@\n", k, info[k]];
    }
    
    [self.info setText:sinfo];
    //[info release];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc {
    [_info release];
    [super dealloc];
}

- (void)viewDidUnload {
    [self setInfo:nil];
    [super viewDidUnload];
}

#pragma mark - Events

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

#pragma mark - Info

- (NSString *)getMacAddress
{
    int                 mgmtInfoBase[6];
    char                *msgBuffer = NULL;
    size_t              length;
    unsigned char       macAddress[6];
    struct if_msghdr    *interfaceMsgStruct;
    struct sockaddr_dl  *socketStruct;
    NSString            *errorFlag = NULL;
    
    // Setup the management Information Base (mib)
    mgmtInfoBase[0] = CTL_NET;        // Request network subsystem
    mgmtInfoBase[1] = AF_ROUTE;       // Routing table info
    mgmtInfoBase[2] = 0;
    mgmtInfoBase[3] = AF_LINK;        // Request link layer information
    mgmtInfoBase[4] = NET_RT_IFLIST;  // Request all configured interfaces
    
    // With all configured interfaces requested, get handle index
    if ((mgmtInfoBase[5] = if_nametoindex("en0")) == 0)
        errorFlag = @"if_nametoindex failure";
    else
    {
        // Get the size of the data available (store in len)
        if (sysctl(mgmtInfoBase, 6, NULL, &length, NULL, 0) < 0)
            errorFlag = @"sysctl mgmtInfoBase failure";
        else
        {
            // Alloc memory based on above call
            if ((msgBuffer = malloc(length)) == NULL)
                errorFlag = @"buffer allocation failure";
            else
            {
                // Get system information, store in buffer
                if (sysctl(mgmtInfoBase, 6, msgBuffer, &length, NULL, 0) < 0)
                    errorFlag = @"sysctl msgBuffer failure";
            }
        }
    }
    
    // Befor going any further...
    if (errorFlag != NULL)
    {
        NSLog(@"Error: %@", errorFlag);
        return errorFlag;
    }
    
    // Map msgbuffer to interface message structure
    interfaceMsgStruct = (struct if_msghdr *) msgBuffer;
    
    // Map to link-level socket structure
    socketStruct = (struct sockaddr_dl *) (interfaceMsgStruct + 1);
    
    // Copy link layer address data in socket structure to an array
    memcpy(&macAddress, socketStruct->sdl_data + socketStruct->sdl_nlen, 6);
    
    // Read from char array into a string object, into traditional Mac address format
    NSString *macAddressString = [NSString stringWithFormat:@"%02X:%02X:%02X:%02X:%02X:%02X",
                                  macAddress[0], macAddress[1], macAddress[2],
                                  macAddress[3], macAddress[4], macAddress[5]];
    
    // Release the buffer memory
    free(msgBuffer);
    
    return macAddressString;
}


- (NSNumber *)countCores
{
    host_basic_info_data_t hostInfo;
    mach_msg_type_number_t infoCount;

    infoCount = HOST_BASIC_INFO_COUNT;
    host_info(mach_host_self(), HOST_BASIC_INFO, 
              (host_info_t)&hostInfo, &infoCount);

    return [NSNumber numberWithInt:hostInfo.max_cpus];
}

- (NSNumber *)activeMemory
{
    mach_port_t host_port = mach_host_self();
    mach_msg_type_number_t host_size = sizeof(vm_statistics_data_t) / sizeof(integer_t);
    vm_size_t pagesize;
    vm_statistics_data_t vm_stat;

    host_page_size(host_port, &pagesize);
    (void) host_statistics(host_port, HOST_VM_INFO, (host_info_t)&vm_stat, &host_size);
    return [NSNumber numberWithLong:vm_stat.active_count * pagesize];
}

- (NSNumber *)freeMemory
{
    mach_port_t host_port = mach_host_self();
    mach_msg_type_number_t host_size = sizeof(vm_statistics_data_t) / sizeof(integer_t);
    vm_size_t pagesize;
    vm_statistics_data_t vm_stat;

    host_page_size(host_port, &pagesize);
    (void) host_statistics(host_port, HOST_VM_INFO, (host_info_t)&vm_stat, &host_size);
    return [NSNumber numberWithLong:vm_stat.free_count * pagesize];
}

- (NSNumber *)commonMemory
{
    mach_port_t host_port = mach_host_self();
    mach_msg_type_number_t host_size = sizeof(vm_statistics_data_t) / sizeof(integer_t);
    vm_size_t pagesize;
    vm_statistics_data_t vm_stat;

    host_page_size(host_port, &pagesize);
    (void) host_statistics(host_port, HOST_VM_INFO, (host_info_t)&vm_stat, &host_size);
    return [NSNumber numberWithLong:(vm_stat.active_count+vm_stat.free_count+vm_stat.inactive_count) * pagesize];
}

@end
