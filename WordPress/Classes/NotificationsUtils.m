//
//  NotificationsUtils.m
//  WordPress
//
//  Created by Danilo Ercoli on 21/01/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import "NotificationsUtils.h"
#import "WordPressAppDelegate.h"
#import "NSString+Helpers.h"

@implementation NotificationsUtils


+ (void)pingStats:(NSString*)statsGroup statsName:(NSString *)statsName {
    int x = arc4random();
    NSString *statsURL = [NSString stringWithFormat:@"%@%@=%@%@%d" , @"http://stats.wordpress.com/g.gif?v=wpcom-no-pv&x_", statsGroup, [statsName stringByUrlEncoding], @"&rnd=", x];
    NSMutableURLRequest* request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:statsURL  ]];
    
    WordPressAppDelegate *appDelegate = (WordPressAppDelegate *)[[UIApplication sharedApplication] delegate];
    [request setValue:[appDelegate applicationUserAgent] forHTTPHeaderField:@"User-Agent"];

    
    //TODO: remove the comment when we're ready with stats
    /*   @autoreleasepool {
        NSURLConnection *conn = [[NSURLConnection alloc] initWithRequest:request delegate:nil];
        [conn start];
    }
  */
}

+ (void)pingStats:(NSString*)statsGroup statsNames:(NSArray *)statsNames {
    NSString *joinedStatsNames = [statsNames componentsJoinedByString:@","];
    [self pingStats:statsGroup statsName:joinedStatsNames];
}

@end
