//
//  NoteCommentCell.h
//  WordPress
//
//  Created by Beau Collins on 12/6/12.
//  Copyright (c) 2012 WordPress. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <FollowButton.h>
#import "DTCoreText.h"

@interface NoteCommentCell : UITableViewCell
@property BOOL parentComment;
@property (nonatomic, strong) FollowButton *followButton;
@property (nonatomic, strong) DTAttributedTextContentView *textContentView;

- (void)setAvatarURL:(NSURL *)avatarURL;
- (void)showLoadingIndicator;
- (void)displayAsParentComment;

+ (CGFloat)heightForCellWithTextContent:(NSAttributedString *)textContent constrainedToWidth:(CGFloat)width;

@end
