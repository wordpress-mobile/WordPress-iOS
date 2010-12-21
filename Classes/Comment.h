//
//  Comment.h
//  WordPress
//
//  Created by Chris Boyd on 6/17/10.
//  Copyright 2010 WordPress. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
	CommentStatusPending,
	CommentStatusApproved,
	CommentStatusDisapproved,
	CommentStatusSpam
} CommentStatus;

@interface Comment : NSManagedObject {

}

@end
