//
//  StatsItem.h
//  WordPress
//
//  Created by Chris Boyd on 6/18/10.
//  Copyright 2010 WordPress. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface StatsItem : NSObject {
	int views;
	NSString *title, *url, *description, *note;
	NSDate *date;
}

@property (nonatomic, assign) int views;
@property (nonatomic, retain) NSString *title, *url, *description, *note;
@property (nonatomic, retain) NSDate *date;

@end
