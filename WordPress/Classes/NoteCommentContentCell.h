//
//  NoteCommentContentCell.h
//  WordPress
//
//  Created by Beau Collins on 1/7/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <DTCoreText/DTCoreText.h>

@protocol NoteCommentContentCellDelegate <NSObject>


@optional

- (void)commentCell:(UITableViewCell *)cell didTapURL:(NSURL *)url;


@end

@interface NoteCommentContentCell : DTAttributedTextCell

@property (assign) id <NoteCommentContentCellDelegate> delegate;
@property (nonatomic, strong) NSAttributedString *attributedString;
@property (nonatomic, assign) BOOL isParentComment;

- (void)displayAsParentComment;

@end
