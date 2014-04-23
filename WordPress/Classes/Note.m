#import "Note.h"
#import "NoteBodyItem.h"
#import "NSString+Helpers.h"
#import "NSString+XMLExtensions.h"
#import "WordPressComApi.h"
#import "WPAccount.h"
#import "ContextManager.h"
#import "XMLParserCollecter.h"


@interface Note ()
@property (nonatomic, strong) NSArray *bodyItems;
@property (nonatomic, strong) NSDictionary *noteData;
@property (nonatomic, strong) NSString *commentText;
@property (nonatomic, strong) NSDate *date;
@end


@implementation Note

@dynamic noteID;
@dynamic timestamp;
@dynamic type;
@dynamic subject;
@dynamic body;
@dynamic unread;
@synthesize bodyItems	= _bodyItems;
@synthesize commentText = _commentText;
@synthesize noteData	= _noteData;
@synthesize date		= _date;


#pragma mark - Derived Properties from subject / body dictionaries

- (NSString *)subjectText {
	NSString *subject = [self.subject stringForKey:@"text"] ?: [self.subject stringForKey:@"html"];
	return [subject trim];
}

- (NSString *)subjectIcon {
	return [self.subject stringForKey:@"icon"];
}

- (NSArray *)bodyActions {
	return [self.body arrayForKey:@"actions"];
}

- (NSString *)bodyTemplate {
	return [self.body stringForKey:@"template"];	
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

- (BOOL)isMatcher {
    return [self.type isEqualToString:@"automattcher"];
}

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

- (BOOL)statsEvent {
    BOOL statsEvent = [self.type rangeOfString:@"_milestone_"].length > 0 || [self.type hasPrefix:@"traffic_"] || [self.type hasPrefix:@"best_"] || [self.type hasPrefix:@"most_"] ;
    
    return statsEvent;
}


#pragma mark - CoreData Helpers

- (NSDictionary *)meta {
    return [self.noteData dictionaryForKey:@"meta"];
}

- (NSNumber *)metaPostID {
    return [[self.meta dictionaryForKey:@"ids"] numberForKey:@"post"];
}

- (NSNumber *)metaSiteID {
    return [[self.meta dictionaryForKey:@"ids"] numberForKey:@"site"];
}

- (NSArray *)bodyItems {
	if (_bodyItems) {
		return _bodyItems;
	}
	
	NSArray *rawItems = [self.noteData[@"body"] arrayForKey:@"items"];
	if (rawItems.count) {
		_bodyItems = [NoteBodyItem parseItems:rawItems];
	}
	return _bodyItems;
}

- (NSString *)bodyHeaderText {
	return self.noteData[@"body"][@"header_text"];
}

- (NSString *)bodyHeaderLink {
	return self.noteData[@"body"][@"header_link"];
}

- (NSString *)bodyFooterText {
	return self.noteData[@"body"][@"footer_text"];
}

- (NSString *)bodyFooterLink {
	return self.noteData[@"body"][@"footer_link"];
}

- (NSString *)bodyHtml {
	return self.noteData[@"body"][@"html"];
}

- (WPNoteTemplateType)templateType {
    NSDictionary *noteBody = self.noteData[@"body"];
    if (noteBody) {
        NSString *noteTypeName = noteBody[@"template"];
        
        if ([noteTypeName isEqualToString:@"single-line-list"])
            return WPNoteTemplateSingleLineList;
        else if ([noteTypeName isEqualToString:@"multi-line-list"])
            return WPNoteTemplateMultiLineList;
        else if ([noteTypeName isEqualToString:@"big-badge"])
            return WPNoteTemplateBigBadge;
    }
    
    return WPNoteTemplateUnknown;
}

#pragma mark - NSManagedObject methods
/*
 * Strips HTML Tags and converts html entites
 */
//- (void)parseComment {
//    if ([self isComment]) {
//        NSDictionary *bodyItem = [[[self.noteData objectForKey:@"body"] objectForKey:@"items"] lastObject];
//        NSString *comment = [bodyItem objectForKey:@"html"];
//        if (comment == (id)[NSNull null] || comment.length == 0)
//            return;
//        comment = [comment stringByReplacingHTMLEmoticonsWithEmoji];
//        comment = [comment stringByStrippingHTML];
//        comment = [comment stringByDecodingXMLCharacters];
//        
//        self.commentText = comment;
//    }
//}

- (NSString *)commentHtml {
    if (self.bodyItems) {
        NoteBodyItem *noteBodyItem = [self.bodyItems lastObject];
        NSString *commentHtml = noteBodyItem.bodyHtml;
        return [commentHtml stringByReplacingHTMLEmoticonsWithEmoji];
    }
    
    return nil;
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
