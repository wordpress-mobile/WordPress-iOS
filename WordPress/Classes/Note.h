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

@property (nonatomic, retain) NSNumber *timestamp;
@property (nonatomic, retain) NSString *type;
@property (nonatomic, retain) NSString *subject;
@property (nonatomic, retain) NSData *payload;
@property (nonatomic, retain) NSNumber *unread;
@property (nonatomic, retain) NSString *icon;
@property (nonatomic, retain) NSString *noteID;
@property (nonatomic, strong, readonly) NSString *commentText;
@property (nonatomic, strong, readonly) NSDictionary *noteData;

- (BOOL)isComment;
- (BOOL)isLike;
- (BOOL)isFollow;
- (BOOL)isRead;
- (BOOL)isUnread;

- (void)syncAttributes:(NSDictionary *)data;

/**
 Remove old notes from Core Data storage

 It will keep at least the 40 latest notes
 @param timestamp if not nil, it well keep all notes newer this timestamp.
 @param context The context which contains the notes to delete.
 */
+ (void)pruneOldNotesBefore:(NSNumber *)timestamp withContext:(NSManagedObjectContext *)context;

@end

@interface Note (WordPressComApi)

+ (void)refreshUnreadNotesWithContext:(NSManagedObjectContext *)context;
- (void)refreshNoteDataWithSuccess:(void (^)())success failure:(void (^)(NSError *error))failure;

@end
