//
//  FilteredWebCache.m
//  WordPress
//
//  Created by Danilo Ercoli on 28/09/11.
//  Copyright 2011 WordPress. All rights reserved.
//

#import "FilteredWebCache.h"

@implementation FilteredWebCache

- (NSCachedURLResponse*)cachedResponseForRequest:(NSURLRequest*)request
{
/*    NSURL *url = [request URL];
    BOOL blockURL = [[FilterMgr sharedFilterMgr] shouldBlockURL:url];
    if (blockURL) {
        NSURLResponse *response =
        [[NSURLResponse alloc] initWithURL:url
                                  MIMEType:@"text/plain"
                     expectedContentLength:1
                          textEncodingName:nil];
        
        NSCachedURLResponse *cachedResponse =
        [[NSCachedURLResponse alloc] initWithResponse:response
                                                 data:[NSData dataWithBytes:" " length:1]];
        
        [super storeCachedResponse:cachedResponse forRequest:request];
        
        [cachedResponse release];
        [response release];
    }*/
    
    NSURL *currentURL = [request URL];
    
    NSCachedURLResponse *resp = [super cachedResponseForRequest:request];
    
    if( resp == nil ) {
        NSLog(@"The Resource is MISSING FROM THE WEBCACHE - %@", currentURL.absoluteString);
    } else {
        NSLog(@"Loaded FROM THE WEBCACHE - %@", currentURL.absoluteString);
    }
    
    return resp;
}
@end