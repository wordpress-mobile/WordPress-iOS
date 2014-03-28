//
//  Note.m
//  WordPress
//
//  Created by Beau Collins on 11/18/12.
//  Copyright (c) 2012 WordPress. All rights reserved.
//

#import "Note.h"
#import "NSString+Helpers.h"
#import "NSString+XMLExtensions.h"
#import "WordPressComApi.h"
#import "ContextManager.h"
#import "XMLParserCollecter.h"



const NSUInteger WPNoteKeepCount = 20;



@implementation Note

@dynamic noteID;
@dynamic timestamp;
@dynamic type;
@dynamic unread;
@dynamic subject;
@dynamic body;


#pragma mark - Derived Properties from subject / body dictionaries

- (NSString *)subjectText {
	NSString *subject = [self.subject stringForKey:@"text"] ?: [self.subject stringForKey:@"html"];
	return [subject trim];
}

- (NSString *)subjectIcon {
	return [self.subject stringForKey:@"icon"];
}

- (NSArray *)bodyItems {
	return [self.body arrayForKey:@"items"];
}

- (NSArray *)bodyActions {
	return [self.body arrayForKey:@"actions"];
}

- (NSString *)bodyTemplate {
	return [self.body stringForKey:@"template"];	
}

- (NSString *)bodyHeaderText {
	return [self.body stringForKey:@"header_text"];
}

- (NSString *)bodyHeaderLink {
	return [self.body stringForKey:@"header_link"];
}

- (NSString *)bodyFooterText {
	return [self.body stringForKey:@"footer_text"];
}

- (NSString *)bodyFooterLink {
	return [self.body stringForKey:@"footer_link"];
}

- (NSString *)bodyCommentText {
	return [self parseBodyComments];
}

- (NSString *)parseBodyComments {
    
    if (self.isComment == NO) {
		return nil;
	}
	
	NSDictionary *bodyItem	= [self.bodyItems lastObject];
	NSString *comment		= [bodyItem stringForKey:@"html"];
	if (comment == (id)[NSNull null] || comment.length == 0 ) {
		return nil;
	}
	
	// Sanitize the string: strips HTML Tags and converts html entites
	comment = [comment stringByReplacingHTMLEmoticonsWithEmoji];
	comment = [comment stringByStrippingHTML];
	
	NSString *xmlString				= [NSString stringWithFormat:@"<d>%@</d>", comment];
	NSData *xml						= [xmlString dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];
	
	// Parse please!
	NSXMLParser *parser				= [[NSXMLParser alloc] initWithData:xml];
	XMLParserCollecter *collector	= [XMLParserCollecter new];
	parser.delegate					= collector;
	[parser parse];
	
	return collector.result;
}


#pragma mark - Public Methods

- (BOOL)isComment {
    return [self.type isEqualToString:@"comment"];
}

- (BOOL)isFollow {
    return [self.type isEqualToString:@"follow"];
}

- (BOOL)isLike {
    return [self.type isEqualToString:@"like"];
}

- (BOOL)isRead {
    return ![self.unread boolValue];
}

- (BOOL)isStatsEvent {
    return [self.type isEqualToString:@"traffic_surge"];
}

- (Blog *)blogForStatsEvent {
    NSScanner *scanner = [NSScanner scannerWithString:self.subjectText];
    NSString *blogName;
    
    while ([scanner isAtEnd] == NO) {
        [scanner scanUpToString:@"\"" intoString:NULL];
        [scanner scanString:@"\"" intoString:NULL];
        [scanner scanUpToString:@"\"" intoString:&blogName];
        [scanner scanString:@"\"" intoString:NULL];
    }
    
    if (blogName.length == 0) {
        return nil;
    }

    NSPredicate *subjectPredicate = [NSPredicate predicateWithFormat:@"self.blogName CONTAINS[cd] %@", blogName];
    NSPredicate *wpcomPredicate = [NSPredicate predicateWithFormat:@"self.account.isWpcom == YES"];
    NSPredicate *jetpackPredicate = [NSPredicate predicateWithFormat:@"self.jetpackAccount != nil"];
    NSPredicate *statsBlogsPredicate = [NSCompoundPredicate orPredicateWithSubpredicates:@[wpcomPredicate, jetpackPredicate]];
    NSPredicate *combinedPredicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[subjectPredicate, statsBlogsPredicate]];

    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Blog"];
    fetchRequest.predicate = combinedPredicate;
    
    NSError *error = nil;
    NSArray *blogs = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    
    if (error) {
        DDLogError(@"Error while retrieving blogs with stats: %@", error);
        return nil;
    }

    if (blogs.count > 0) {
        return [blogs firstObject];
    }
    
    return nil;
}


#pragma mark - CoreData Helpers

+ (void)pruneOldNotesBefore:(NSNumber *)timestamp withContext:(NSManagedObjectContext *)context {
    NSError *error;

    // For some strange reason, core data objects with changes are ignored when using fetchOffset
    // Even if you have 20 notes and fetchOffset is 20, any object with uncommitted changes would show up as a result
    // To avoid that we make sure to commit all changes before doing our request
    [context save:&error];
    NSUInteger keepCount = WPNoteKeepCount;
    if (timestamp) {
        NSFetchRequest *countRequest	= [NSFetchRequest fetchRequestWithEntityName:@"Note"];
        countRequest.predicate			= [NSPredicate predicateWithFormat:@"timestamp >= %@", timestamp];
        countRequest.sortDescriptors	= @[ [NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:NO] ];
		
        NSError *error;
        NSUInteger notesCount = [context countForFetchRequest:countRequest error:&error];
        if (notesCount != NSNotFound) {
            keepCount = MAX(keepCount, notesCount);
        }
    }

    NSFetchRequest *request		= [NSFetchRequest fetchRequestWithEntityName:@"Note"];
    request.fetchOffset			= keepCount;
    request.sortDescriptors		= @[ [NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:NO] ];
    NSArray *notes				= [context executeFetchRequest:request error:&error];
    if (error) {
        DDLogError(@"Error pruning old notes: %@", error);
        return;
    }
    for (Note *note in notes) {
        [context deleteObject:note];
    }
    if(![context save:&error]){
        DDLogError(@"Failed to save after pruning notes: %@", error);
    }
}

+ (NSNumber *)lastNoteTimestampWithContext:(NSManagedObjectContext *)context {
    NSFetchRequest *request		= [NSFetchRequest fetchRequestWithEntityName:@"Note"];
    request.resultType			= NSDictionaryResultType;
    request.propertiesToFetch	= @[@"timestamp"];
    request.fetchLimit			= 1;
    request.sortDescriptors		= @[[NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:NO]];
    NSArray *results			= [context executeFetchRequest:request error:nil];
    NSNumber *timestamp			= nil;
    if (results.count) {
        NSDictionary *note = [results firstObject];
        timestamp = note[@"timestamp"];
    }
    return timestamp;
}


#pragma mark - WPContentViewProvider protocol

- (NSString *)titleForDisplay {
    NSString *title = [self.subjectText trim];
    if (title.length > 0 && [title hasPrefix:@"["]) {
        // Find location of trailing bracket
        NSRange statusRange = [title rangeOfString:@"]"];
        if (statusRange.location != NSNotFound) {
            title = [title substringFromIndex:statusRange.location + 1];
            title = [title trim];
        }
    }
	return [title stringByDecodingXMLCharacters] ?: @"";
}

- (NSString *)authorForDisplay {
    // Annoyingly, not directly available; could try to parse from self.subject
    return nil;
}

- (NSString *)blogNameForDisplay {
    return nil;
}

- (NSString *)statusForDisplay {
    
    // This is clearly an error prone method of isolating the status,
    // but is necessary due to the current API. This should be changed
    // if/when the API is improved.
    
    NSString *status = [self.subjectText trim];
    if (status.length > 0 && [status hasPrefix:@"["]) {
        // Find location of trailing bracket
        NSRange statusRange = [status rangeOfString:@"]"];
        if (statusRange.location != NSNotFound) {
            status = [status substringWithRange:NSMakeRange(1, statusRange.location - 1)];
        }
    } else {
        status = nil;
    }
    return status;
}

- (NSString *)contentForDisplay {
    // Contains a lot of cruft
    return self.bodyCommentText;
}

- (NSString *)contentPreviewForDisplay {
    return self.bodyCommentText;
}

- (NSString *)gravatarEmailForDisplay {
    return nil;
}

- (NSURL *)avatarURLForDisplay {
    return [NSURL URLWithString:self.subjectIcon];
}

- (NSDate *)dateForDisplay {
	NSTimeInterval timeInterval = [self.timestamp doubleValue];
	return [NSDate dateWithTimeIntervalSince1970:timeInterval];
}

- (BOOL)unreadStatusForDisplay {
    return !self.isRead;
}

@end

