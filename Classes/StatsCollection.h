//
//  StatsCollection.h
//  WordPress
//
//  Created by Chris Boyd on 6/18/10.
//  Copyright 2010 WordPress. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "StatsItem.h"

typedef enum {
	StatsCategoryReferrers = 1,
	StatsCategoryTopPosts = 2,
	StatsCategoryClicks = 3,
	StatsCategorySearchTerms = 4
} StatsCategory;

@interface StatsCollection : NSObject <NSXMLParserDelegate> {
	int total, count;
	int *currentViews;
	NSDate *currentDate, *updated;
	NSMutableString *currentProperty;
	NSMutableArray *items;
	NSString *data;
	StatsItem *currentItem;
	StatsCategory *category;
}

@property (nonatomic, assign) int total;
@property (readonly, assign) int count;
@property (nonatomic, assign) int *currentViews;
@property (nonatomic, retain) NSDate *currentDate, *updated;
@property (nonatomic, retain) NSMutableString *currentProperty;
@property (nonatomic, retain) NSMutableArray *items;
@property (nonatomic, retain) NSString *data;
@property (nonatomic, retain) StatsItem *currentItem;
@property (nonatomic, assign) StatsCategory *category;

- (id)initWithXml:(NSString *)xml;
- (void)addStatsItem:(StatsItem *)item;
- (void)parseXML:(NSData *)xml parseError:(NSError **)err;

@end
