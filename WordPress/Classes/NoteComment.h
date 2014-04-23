#import <Foundation/Foundation.h>

@interface NoteComment : NSObject

@property (nonatomic, strong) NSString *commentID;
@property (nonatomic, strong) NSDictionary *commentData;
@property (readonly) BOOL needsData;
@property (readonly, getter=isLoaded) BOOL loaded;
@property BOOL loading;
@property BOOL isParentComment;

- (id)initWithCommentID:(NSDictionary *)commentID;

@end
