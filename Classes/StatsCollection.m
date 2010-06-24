//
//  StatsCollection.m
//  WordPress
//
//  Created by Chris Boyd on 6/18/10.
//  Copyright 2010 WordPress. All rights reserved.
//

#import "StatsCollection.h"


@implementation StatsCollection
@synthesize items, currentItem, category, total, currentViews, currentDate, currentProperty, updated, data;

#pragma mark -
#pragma mark Init

-(id)init {
    if (self = [super init])
    {
		self.items = [[NSMutableArray alloc] init];
    }
    return self;
}

- (id)initWithXml:(NSString *)xml {
    if (self = [super init]) {
		self.data = xml;
		self.items = [[NSMutableArray alloc] init];
    }
	
    return self;
}

- (int)count {
	return items.count;
}

- (void)setData:(NSString *)input {
    [data autorelease];
    data = [input retain];
	[self parseXML:[data dataUsingEncoding:NSUTF8StringEncoding] parseError:nil];
}

#pragma mark -
#pragma mark Custom Methods

- (void)addStatsItem:(StatsItem *)item {
	[items addObject:item];
	total += item.views;
}

#pragma mark -
#pragma mark NSXMLParser Methods

- (void)parseXML:(NSData *)xml parseError:(NSError **)err {
	NSXMLParser *parser = [[NSXMLParser alloc] initWithData:xml];
	
    self.items = [[NSMutableArray alloc] init];
	
    [parser setDelegate:self];
    [parser setShouldProcessNamespaces:NO];
    [parser setShouldReportNamespacePrefixes:NO];
    [parser setShouldResolveExternalEntities:NO];
	
    [parser parse];
	
    if (err && [parser parserError]) {
        *err = [parser parserError];
    }
	
    [parser release];
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string
{
    if ((self.currentProperty) && (string.length > 0)) {
        [currentProperty appendString:string];
		NSLog(@"currentProperty is now %@", currentProperty);
    }
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict {
    if (qName) {
        elementName = qName;
    }
	
    if ([elementName isEqualToString:@"day"]) {
		self.currentItem = [[StatsItem alloc] init];
		self.currentProperty = [NSMutableString string];
	}
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName {
    if (qName) {
        elementName = qName;
    }
	
    if (self.currentProperty) { // Are we in a
        // Check for standard nodes
        if (([elementName isEqualToString:@"day"]) && (currentProperty.length > 0)) {
            self.currentItem.views = [self.currentProperty intValue];
            [self addStatsItem:self.currentItem]; // Add to parent
            self.currentItem = nil; // Set nil
        }
    }
	
    // We reset the currentProperty, for the next textnodes..
    self.currentProperty = nil;
}

#pragma mark -
#pragma mark Dealloc

- (void)dealloc {
	[data release];
	[updated release];
	[currentDate release];
	[currentProperty release];
	[currentItem release];
	[items release];
    [super dealloc];
}

@end
