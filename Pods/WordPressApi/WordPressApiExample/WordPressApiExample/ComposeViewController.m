//
//  ComposeViewController.m
//  WordPressApiExample
//
//  Created by Jorge Bernal on 1/17/12.
//  Copyright (c) 2012 Automattic. All rights reserved.
//

#import "ComposeViewController.h"
#import "PostsViewController.h"

@interface ComposeViewController () <UINavigationControllerDelegate,UIImagePickerControllerDelegate>

@end

@implementation ComposeViewController
@synthesize titleField, content;

- (IBAction)cancel:(id)sender {
    [self dismissModalViewControllerAnimated:YES];
}

- (IBAction)save:(id)sender {
    PostsViewController *postsVC = (PostsViewController *)[(UINavigationController *)[self presentingViewController] topViewController];
    [postsVC publishPostWithTitle:titleField.text content:content.text image:self.image];
    [self dismissModalViewControllerAnimated:YES];
}

- (IBAction)addPicture:(id)sender {
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    [self presentViewController:picker animated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    self.image = info[UIImagePickerControllerOriginalImage];
    self.imageView.image = self.image;
    [self dismissModalViewControllerAnimated:YES];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [self dismissModalViewControllerAnimated:YES];
}

@end
