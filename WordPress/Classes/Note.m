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
#import "WPAccount.h"
#import "ContextManager.h"

@interface XMLParserCollecter : NSObject <NSXMLParserDelegate>
@property (nonatomic, strong) NSMutableString *result;
@end
@implementation XMLParserCollecter

- (id)init {
    if (self = [super init]) {
        self.result = [[NSMutableString alloc] init];
    }
    return self;
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
    [self.result appendString:string];
}

@end

@interface Note ()

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
@synthesize commentText = _commentText;
@synthesize noteData = _noteData;
@synthesize date = _date;


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
        if (comment == (id)[NSNull null] || comment.length == 0 )
            return;
        comment = [comment stringByReplacingHTMLEmoticonsWithEmoji];
        comment = [comment stringByStrippingHTML];
        
        NSString *xmlString = [NSString stringWithFormat:@"<d>%@</d>", comment];
        NSData *xml = [xmlString dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];
        NSXMLParser *parser = [[NSXMLParser alloc] initWithData:xml];
        XMLParserCollecter *collector = [[XMLParserCollecter alloc] init];
        parser.delegate = collector;
        [parser parse];
        
        self.commentText = collector.result;
        
    }
    
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
    return self.commentText;
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
