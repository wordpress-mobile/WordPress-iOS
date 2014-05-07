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

@property (nonatomic,  readonly) NSNumber           *timestamp;
@property (nonatomic,  readonly) NSString           *type;
@property (nonatomic, readwrite) NSNumber           *unread;
@property (nonatomic,  readonly) NSDictionary       *subject;
@property (nonatomic,  readonly) NSDictionary       *body;

// Derived attributes from Subject + Body collections.
// Ref: http://developer.wordpress.com/docs/api/1/get/notifications/
//
@property (nonatomic,  readonly) NSString           *subjectText;
@property (nonatomic,  readonly) NSString           *subjectIcon;

@property (nonatomic,  readonly) NSString           *bodyHtml;
@property (nonatomic,  readonly) NSArray            *bodyItems;         // Array of NoteBodyItem Objects
@property (nonatomic,  readonly) NSArray            *bodyActions;       // Array of NSDictionary Objects
@property (nonatomic,  readonly) NSString           *bodyTemplate;
@property (nonatomic,  readonly) NSString           *bodyHeaderText;
@property (nonatomic,  readonly) NSString           *bodyHeaderLink;
@property (nonatomic,  readonly) NSString           *bodyFooterText;
@property (nonatomic,  readonly) NSString           *bodyFooterLink;
@property (nonatomic,  readonly) NSString           *bodyCommentText;
@property (nonatomic,  readonly) NSString           *bodyCommentHtml;

@property (nonatomic,  readonly) NSDictionary       *meta;
@property (nonatomic,  readonly) NSNumber           *metaPostID;
@property (nonatomic,  readonly) NSNumber           *metaSiteID;

@property (nonatomic,  readonly) WPNoteTemplateType templateType;

- (BOOL)isMatcher;
- (BOOL)isComment;
- (BOOL)isLike;
- (BOOL)isFollow;
- (BOOL)isRead;
- (BOOL)statsEvent;

@end
