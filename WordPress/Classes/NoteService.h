#import <Foundation/Foundation.h>
#import "LocalService.h"

@class Note, Blog;

@interface NoteService : NSObject <LocalService>

// Attempt to get the right blog for the note's stats event
- (Blog *)blogForStatsEventNote:(Note *)note;


@end
