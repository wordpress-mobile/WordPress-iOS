/*
 * NoteService.h
 *
 * Copyright (c) 2014 WordPress. All rights reserved.
 *
 * Licensed under GNU General Public License 2.0.
 * Some rights reserved. See license.txt
 */

#import <Foundation/Foundation.h>
#import "BaseLocalService.h"

@class Note, Blog;

@interface NoteService : NSObject <BaseLocalService>

- (void)mergeNewNotes:(NSArray *)notesData;

/**
 Remove old notes from Core Data storage
 
 It will keep at least the 40 latest notes
 @param timestamp if not nil, it well keep all notes newer this timestamp.
 @param context The context which contains the notes to delete.
 */
- (void)pruneOldNotesBefore:(NSNumber *)timestamp;

- (void)fetchNewNotificationsWithSuccess:(void (^)(BOOL hasNewNotes))success failure:(void (^)(NSError *error))failure;

- (void)refreshUnreadNotes;

- (void)fetchNotificationsSince:(NSNumber *)timestamp success:(void (^)())success failure:(void (^)(NSError *error))failure;

- (void)fetchNotificationsBefore:(NSNumber *)timestamp success:(void (^)())success failure:(void (^)(NSError *error))failure;

- (void)refreshNote:(Note *)note success:(void (^)())success failure:(void (^)(NSError *))failure;

- (void)markNoteAsRead:(Note *)note success:(void (^)())success failure:(void (^)(NSError *))failure;

// Attempt to get the right blog for the note's stats event
- (Blog *)blogForStatsEventNote:(Note *)note;


@end
