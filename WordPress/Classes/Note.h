#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import <Simperium/SPManagedObject.h>
#import "WPAccount.h"
#import "WPContentViewProvider.h"


typedef NS_ENUM(NSInteger, WPNoteTemplateType) {
    WPNoteTemplateUnknown,
    WPNoteTemplateSingleLineList,
    WPNoteTemplateMultiLineList,
    WPNoteTemplateBigBadge,
};

@interface Note : SPManagedObject<WPContentViewProvider>

@property (nonatomic, readonly) NSString            *noteID;
@property (nonatomic, readonly) NSNumber            *timestamp;
@property (nonatomic, readonly) NSString            *type;
@property (nonatomic, readwrite) NSString           *unread;            // Yes. This should be a number instead.
@property (nonatomic, readonly) NSDictionary        *subject;
@property (nonatomic, readonly) NSDictionary        *body;

// Derived attributes from the Subject and Body collections.
// Ref: http://developer.wordpress.com/docs/api/1/get/notifications/
//
@property (nonatomic, readonly) NSString            *subjectText;
@property (nonatomic, readonly) NSString            *subjectIcon;
@property (nonatomic, readonly) NSArray             *bodyItems;         // Array of NoteBodyItem Objects
@property (nonatomic, readonly) NSArray             *bodyActions;
@property (nonatomic, readonly) NSString            *bodyTemplate;
@property (nonatomic, readonly) NSString            *bodyHeaderText;
@property (nonatomic, readonly) NSString            *bodyHeaderLink;
@property (nonatomic, readonly) NSString            *bodyFooterText;
@property (nonatomic, readonly) NSString            *bodyFooterLink;
@property (nonatomic, readonly) NSString            *bodyCommentText;

@property (nonatomic, readonly) NSString            *commentText;
@property (nonatomic, readonly) NSString            *commentHtml;

@property (nonatomic, readonly) NSDictionary        *meta;
@property (nonatomic, readonly) NSNumber            *metaPostID;
@property (nonatomic, readonly) NSNumber            *metaSiteID;

@property (nonatomic, readonly) WPNoteTemplateType  templateType;

- (BOOL)isMatcher;
- (BOOL)isComment;
- (BOOL)isLike;
- (BOOL)isFollow;
- (BOOL)isRead;
- (BOOL)isUnread;
- (BOOL)statsEvent;

@end
