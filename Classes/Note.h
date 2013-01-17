//
//  Note.h
//  WordPress
//
//

#import <Foundation/Foundation.h>

@interface Note : NSObject

@property (nonatomic, strong) NSDictionary *noteData;
@property (nonatomic, strong) UIImage *noteIconImage;
@property (readonly) NSString *subject;
@property (readonly) NSString *type;
@property (readonly, nonatomic, strong) NSString *commentText;

- (id)initWithNoteData:(NSDictionary *)noteData;
- (BOOL)isComment;
- (BOOL)isLike;
- (BOOL)isFollow;
- (BOOL)isUnread;
- (BOOL)isRead;

@end
