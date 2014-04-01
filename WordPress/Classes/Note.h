//
//  Note.h
//  WordPress
//
//  Created by Beau Collins on 11/18/12.
//  Copyright (c) 2012 WordPress. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WPAccount.h"
#import "WPContentViewProvider.h"

typedef enum {
    WPNoteTemplateUnknown,
    WPNoteTemplateSingleLineList,
    WPNoteTemplateMultiLineList,
    WPNoteTemplateBigBadge,
} WPNoteTemplateType;

@interface Note : NSManagedObject<WPContentViewProvider>

@property (nonatomic, retain) NSNumber *timestamp;
@property (nonatomic, retain) NSString *type;
@property (nonatomic, retain) NSString *subject;
@property (nonatomic, retain) NSData *payload;
@property (nonatomic, retain) NSNumber *unread;
@property (nonatomic, retain) NSString *icon;
@property (nonatomic, retain) NSString *noteID;
@property (nonatomic, retain) WPAccount *account;
@property (nonatomic, strong, readonly) NSString *commentText;
@property (nonatomic, strong, readonly) NSDictionary *noteData;
@property (nonatomic, strong, readonly) NSArray *bodyItems;		// Array of NoteBodyItem Objects
@property (nonatomic, strong, readonly) NSString *bodyHeaderText;
@property (nonatomic, strong, readonly) NSString *bodyHeaderLink;
@property (nonatomic, strong, readonly) NSString *bodyFooterText;
@property (nonatomic, strong, readonly) NSString *bodyFooterLink;
@property (nonatomic, strong, readonly) NSString *bodyHtml;
@property (nonatomic, strong, readonly) NSNumber *metaBlogId;
@property (nonatomic, strong, readonly) NSString *metaSiteId;
@property (nonatomic, strong, readonly) NSString *metaPostId;
@property (nonatomic, readonly) WPNoteTemplateType templateType;

- (BOOL)isComment;
- (BOOL)isLike;
- (BOOL)isFollow;
- (BOOL)isRead;
- (BOOL)isUnread;
- (BOOL)statsEvent;

- (void)syncAttributes:(NSDictionary *)data;

@end
