//
//  Note.h
//  WordPress
//
//  Created by Beau Collins on 11/18/12.
//  Copyright (c) 2012 WordPress. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import <Simperium/SPManagedObject.h>
#import "WPAccount.h"
#import "WPContentViewProvider.h"

@interface Note : SPManagedObject<WPContentViewProvider>

@property (nonatomic, strong,  readonly) NSString		*noteID;
@property (nonatomic, strong,  readonly) NSNumber		*timestamp;
@property (nonatomic, strong,  readonly) NSString		*type;
@property (nonatomic, strong, readwrite) NSNumber		*unread;
@property (nonatomic, retain,  readonly) NSDictionary	*subject;
@property (nonatomic, retain,  readonly) NSDictionary	*body;

// Derived attributes from the Subject and Body collections.
// Ref: http://developer.wordpress.com/docs/api/1/get/notifications/
//
@property (nonatomic, strong,  readonly) NSString		*subjectText;
@property (nonatomic, strong,  readonly) NSString		*subjectIcon;
@property (nonatomic, strong,  readonly) NSArray		*bodyItems;
@property (nonatomic, strong,  readonly) NSArray		*bodyActions;
@property (nonatomic, strong,  readonly) NSString		*bodyTemplate;
@property (nonatomic, strong,  readonly) NSString		*bodyHeaderText;
@property (nonatomic, strong,  readonly) NSString		*bodyHeaderLink;
@property (nonatomic, strong,  readonly) NSString		*bodyFooterText;
@property (nonatomic, strong,  readonly) NSString		*bodyFooterLink;
@property (nonatomic, strong,  readonly) NSString		*bodyCommentText;


- (BOOL)isComment;
- (BOOL)isLike;
- (BOOL)isFollow;
- (BOOL)isRead;
- (BOOL)isUnread;

// Attempt to get the right blog for the note's stats event
- (Blog *)blogForStatsEvent;
- (BOOL)isStatsEvent;

/**
 Remove old notes from Core Data storage

 It will keep at least the 40 latest notes
 @param timestamp if not nil, it well keep all notes newer this timestamp.
 @param context The context which contains the notes to delete.
 */
+ (void)pruneOldNotesBefore:(NSNumber *)timestamp withContext:(NSManagedObjectContext *)context;

@end
