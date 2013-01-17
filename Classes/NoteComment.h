//
//  NoteComment.h
//  WordPress
//
//  Copyright (c) 2012 WordPress. All rights reserved.
//
//  Currently just a container for note comment data
//  so we can check it's loading status and ask it
//  what state it's in loaded/loading etc
//
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
