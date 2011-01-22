//
//  PostReaderViewController.h
//  WordPress
//
//  Created by Jorge Bernal on 12/30/10.
//  Copyright 2010 WordPress. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EditPostViewController.h"
#import "Post.h"

@interface PostReaderViewController : UIViewController<UITextFieldDelegate, UITextViewDelegate> {

}

@property (nonatomic, retain) IBOutlet UITextField *categoriesTextField, *statusTextField, *titleTextField, *tagsTextField;
@property (nonatomic, retain) IBOutlet UITextView *contentView;
@property (nonatomic, retain) IBOutlet AbstractPost *apost;
@property (nonatomic, assign) Post *post;

- (id)initWithPost:(AbstractPost *)aPost;
- (void)showModalEditor;
- (void)refreshUI;
@end
