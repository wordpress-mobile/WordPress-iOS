#import "NoteComment.h"

@implementation NoteComment

- (id)initWithCommentID:(NSString *)commentID {
    self = [super init];
    if (self != nil) {
        self.commentID = commentID;
        self.commentData = nil;
        self.loading = NO;
    }
    return self;
}

- (BOOL)needsData{
    return self.commentData == nil && self.loading == NO;
}

- (BOOL)isLoaded {
    return self.commentData != nil;
}

@end
