//
// Copyright 2011 ODIN Working Group. All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#import "ODIN.h"
#import <CommonCrypto/CommonDigest.h>

#include <sys/socket.h>
#include <sys/sysctl.h>
#include <net/if.h>
#include <net/if_dl.h>



NSString * ODIN1(){
    
// Step 1: Get MAC address
    
    int                 mib[6];
    size_t              len;
    char                *buf;
    unsigned char       *ptr;
    struct if_msghdr    *ifm;
    struct sockaddr_dl  *sdl;
    
    mib[0] = CTL_NET;
    mib[1] = AF_ROUTE;
    mib[2] = 0;
    mib[3] = AF_LINK;
    mib[4] = NET_RT_IFLIST;
    
    if ((mib[5] = if_nametoindex("en0")) == 0) {
        //NSLog(@"ODIN-1.1: if_nametoindex error");
        return nil;
    }
    
    if (sysctl(mib, 6, NULL, &len, NULL, 0) < 0) {
        //NSLog(@"ODIN-1.1: sysctl 1 error");
        return nil;
    }
    
    if ((buf = malloc(len)) == NULL) {
        //NSLog(@"ODIN-1.1: malloc error");
        return nil;
    }
    
    if (sysctl(mib, 6, buf, &len, NULL, 0) < 0) {
        //NSLog(@"ODIN-1.1: sysctl 2 error");
        return nil;
    }
    
    ifm = (struct if_msghdr *)buf;
    sdl = (struct sockaddr_dl *)(ifm + 1);
    ptr = (unsigned char *)LLADDR(sdl);
    
    //NSLog(@"MAC Address: %02X:%02X:%02X:%02X:%02X:%02X", *ptr, *(ptr+1), *(ptr+2), *(ptr+3), *(ptr+4), *(ptr+5));
    
// Step 2: Take the SHA-1 of the MAC address
    
    CFDataRef data = CFDataCreate(NULL, (uint8_t*)ptr, 6);
    
    unsigned char messageDigest[CC_SHA1_DIGEST_LENGTH];
	
	CC_SHA1(CFDataGetBytePtr((CFDataRef)data), 
			CFDataGetLength((CFDataRef)data), 
			messageDigest);
	
	CFMutableStringRef string = CFStringCreateMutable(NULL, 40);
	for(int i = 0; i < CC_SHA1_DIGEST_LENGTH; i++) {
		CFStringAppendFormat(string,
							 NULL, 
							 (CFStringRef)@"%02X",
							 messageDigest[i]);
	}

    CFStringLowercase(string, CFLocaleGetSystem());
    
    //NSLog(@"ODIN-1: %@", string);
    
    free(buf);
    
    NSString *odinstring = [[[NSString alloc] initWithString:(NSString*)string] autorelease];
    CFRelease(data);
    CFRelease(string);

    return odinstring;
}

