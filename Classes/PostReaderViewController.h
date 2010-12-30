//
//  PostReaderViewController.h
//  WordPress
//
//  Created by Jorge Bernal on 12/30/10.
//  Copyright 2010 WordPress. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PostViewController.h"
#import "Post.h"

@interface PostReaderViewController : UIViewController<UITextFieldDelegate, UITextViewDelegate> {

}

@property (nonatomic, retain) IBOutlet UITextField *categoriesTextField, *statusTextField, *titleTextField, *tagsTextField;
@property (nonatomic, retain) IBOutlet UITextView *contentView;
@property (nonatomic, retain) IBOutlet Post *post;

- (id)initWithPost:(Post *)aPost;
- (void)showModalEditor;
- (void)refreshUI;
@end
