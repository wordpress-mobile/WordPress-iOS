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

@dynamic timestamp;
@dynamic type;
@dynamic subject;
@dynamic payload;
@dynamic unread;
@dynamic icon;
@dynamic noteID;
@dynamic account;
@synthesize bodyItems	= _bodyItems;
@synthesize commentText = _commentText;
@synthesize noteData	= _noteData;
@synthesize date		= _date;


- (void)syncAttributes:(NSDictionary *)noteData {
    self.payload = [NSJSONSerialization dataWithJSONObject:noteData options:0 error:nil];
    self.noteData = [NSJSONSerialization JSONObjectWithData:self.payload options:NSJSONReadingMutableContainers error:nil];
    if ([noteData objectForKey:@"type"]) {
        self.type = [noteData objectForKey:@"type"];
    }
    if ([noteData objectForKey:@"subject"]) {
        NSString *subject = [[noteData objectForKey:@"subject"] objectForKey:@"text"];
        if (!subject)
            subject = [[noteData objectForKey:@"subject"] objectForKey:@"html"];
        self.subject = [subject trim];
        self.icon = [[noteData objectForKey:@"subject"] objectForKey:@"icon"];
    }
    if ([noteData objectForKey:@"timestamp"]) {
        NSInteger timestamp = [[noteData objectForKey:@"timestamp"] integerValue];
        self.timestamp = [NSNumber numberWithInteger:timestamp];
    }
    if ([noteData objectForKey:@"unread"]) {
        NSInteger unread = [[noteData objectForKey:@"unread"] integerValue];
        self.unread = [NSNumber numberWithInteger:unread];
    }
    if ([self isComment] && [noteData objectForKey:@"body"]) {
        [self parseComment];
    }
}

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

- (BOOL)isUnread {
    return [self.unread boolValue];
}

- (BOOL)isRead {
    return ![self isUnread];
}

- (BOOL)statsEvent {
    return [self.type isEqualToString:@"traffic_surge"];
}

- (NSString *)commentText {
    if (_commentText == nil) {
        [self parseComment];
    }
    return _commentText;
}

- (id)noteData {
    if (_noteData == nil) {
        _noteData = [NSJSONSerialization JSONObjectWithData:self.payload options:NSJSONReadingMutableContainers error:nil];
    }
    return _noteData;
}

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

- (void)didTurnIntoFault {
    [super didTurnIntoFault];
    
    self.noteData = nil;
    self.date = nil;
    self.commentText = nil;
}

#pragma mark - Comment HTML parsing

/*
 * Strips HTML Tags and converts html entites
 */
- (void)parseComment {
    
    if ([self isComment]) {
        NSDictionary *bodyItem = [[[self.noteData objectForKey:@"body"] objectForKey:@"items"] lastObject];
        NSString *comment = [bodyItem objectForKey:@"html"];
        if (comment == (id)[NSNull null] || comment.length == 0)
            return;
        comment = [comment stringByReplacingHTMLEmoticonsWithEmoji];
        comment = [comment stringByStrippingHTML];
        comment = [comment stringByDecodingXMLCharacters];
        
        self.commentText = comment;
    }
}

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
    NSString *title = [self.subject trim];
    if (title.length > 0 && [title hasPrefix:@"["]) {
        // Find location of trailing bracket
        NSRange statusRange = [title rangeOfString:@"]"];
        if (statusRange.location != NSNotFound) {
            title = [title substringFromIndex:statusRange.location + 1];
            title = [title trim];
        }
    }
    title = [title stringByDecodingXMLCharacters];
    return title;
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
    
    NSString *status = [self.subject trim];
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
    return self.commentHtml;
}

- (NSString *)contentPreviewForDisplay {
    return self.commentText;
}

- (NSString *)gravatarEmailForDisplay {
    return nil;
}

- (NSURL *)avatarURLForDisplay {
    return [NSURL URLWithString:self.icon];
}

- (NSURL *)featuredImageURLForDisplay {
    return nil;
}

- (NSDate *)dateForDisplay {
    if (self.date == nil) {
        NSTimeInterval timeInterval = [self.timestamp doubleValue];
        self.date = [NSDate dateWithTimeIntervalSince1970:timeInterval];
    }
    
    return self.date;
}

- (BOOL)unreadStatusForDisplay {
    return !self.isRead;
}

@end
