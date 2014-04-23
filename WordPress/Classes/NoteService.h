#import <Foundation/Foundation.h>
#import "LocalService.h"

@class Note, Blog;

@interface NoteService : NSObject <LocalService>

/**
 Remove old notes from Core Data storage
 
 It will keep at least the 40 latest notes
 @param timestamp if not nil, it well keep all notes newer this timestamp.
 @param context The context which contains the notes to delete.
 */
- (void)pruneOldNotesBefore:(NSNumber *)timestamp;

- (void)refreshUnreadNotes;

- (void)markNoteAsRead:(Note *)note success:(void (^)())success failure:(void (^)(NSError *error))failure;

// Attempt to get the right blog for the note's stats event
- (Blog *)blogForStatsEventNote:(Note *)note;


@end
