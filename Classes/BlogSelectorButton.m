//
//  BlogSelectorButton.m
//  WordPress
//
//  Created by Jorge Bernal on 4/6/11.
//  Copyright 2011 WordPress. All rights reserved.
//

#import "BlogSelectorButton.h"
#import "WordPressAppDelegate.h"
#import <QuartzCore/QuartzCore.h>
#import "UIImageView+Gravatar.h"

@interface BlogSelectorButton (PrivateMethods)
- (void)tap;
@end

@implementation BlogSelectorButton
@synthesize activeBlog;
@synthesize delegate;

- (void)dealloc
{
    self.activeBlog = nil;
     blavatarImageView = nil;
     postToLabel = nil;
     blogTitleLabel = nil;
     selectorImageView = nil;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    
    if (self) {
        active = NO;
        self.autoresizesSubviews = YES;

        CGRect blavatarFrame = self.bounds;
        blavatarFrame.size.width = 36.0f;
        blavatarFrame.size.height = 36.0f;
        blavatarFrame.origin.x += 8;
        blavatarFrame.origin.y += 6;
        blavatarImageView = [[UIImageView alloc] initWithFrame:blavatarFrame];
        [self addSubview:blavatarImageView];
        
        CGRect postToFrame = self.bounds;
        postToFrame.origin.x = blavatarFrame.size.width + 15;
        postToFrame.origin.y = postToFrame.origin.y + 6;
        postToFrame.size.width -= blavatarFrame.size.width + 10 + 50;
        postToFrame.size.height = 18.0f;
        postToLabel = [[UILabel alloc] initWithFrame:postToFrame];
        postToLabel.font = [UIFont systemFontOfSize:15];
        postToLabel.textColor = [UIColor grayColor];
        [postToLabel setText: NSLocalizedString(@"Post to:", @"")];
        [self addSubview:postToLabel];
        
        CGRect blogTitleFrame = self.bounds;
        blogTitleFrame.origin.x = blavatarFrame.size.width + 15;
        blogTitleFrame.origin.y = blogTitleFrame.origin.y + 21;
        blogTitleFrame.size.width -= blavatarFrame.size.width + 10 + 50;
        blogTitleFrame.size.height = 24.0f;
        blogTitleLabel = [[UILabel alloc] initWithFrame:blogTitleFrame];
        blogTitleLabel.font = [UIFont boldSystemFontOfSize:20];
        blogTitleLabel.numberOfLines = 1;
        blogTitleLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        [self addSubview:blogTitleLabel];
        
        CGRect selectorImageFrame = self.bounds;
        selectorImageFrame.origin.x = selectorImageFrame.size.width - 40;
        selectorImageFrame.size.width = 15;
        selectorImageView = [[UIImageView alloc] initWithFrame:selectorImageFrame];
        selectorImageView.contentMode = UIViewContentModeCenter;
        selectorImageView.image = [UIImage imageNamed:@"downArrow"];
        selectorImageView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
        [self addSubview:selectorImageView];
        
        [self addTarget:self action:@selector(tap) forControlEvents:UIControlEventTouchUpInside];        
    }
    
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
    [super drawRect:rect];
}
*/

#pragma mark -
#pragma mark Custom methods

- (NSString *)defaultsKey {
    switch (blogType) {
        case BlogSelectorButtonTypeQuickPhoto:
            return kBlogSelectorQuickPhoto;
            break;
            
        default:
            break;
    }
    
    return nil;
}

- (void)loadBlogsForType:(BlogSelectorButtonType)aType {
    blogType = aType;
    NSString *defaultsKey = [self defaultsKey];
    NSManagedObjectContext *moc = [[WordPressAppDelegate sharedWordPressApplicationDelegate] managedObjectContext];
    NSPersistentStoreCoordinator *psc = [[WordPressAppDelegate sharedWordPressApplicationDelegate] persistentStoreCoordinator];
    NSError *error = nil;

    if (defaultsKey != nil) {
        NSString *blogId = [[NSUserDefaults standardUserDefaults] objectForKey:defaultsKey];
        if (blogId != nil) {
            @try {
                self.activeBlog = (Blog *)[moc existingObjectWithID:[psc managedObjectIDForURIRepresentation:[NSURL URLWithString:blogId]] error:nil];
            }
            @catch (NSException *exception) {
                self.activeBlog = nil;
            }
            if (self.activeBlog == nil) {
                // The default blog was invalid, remove the stored default
                [[NSUserDefaults standardUserDefaults] removeObjectForKey:defaultsKey];
            }
        }
    }
    
    if (self.activeBlog == nil) {
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        [fetchRequest setEntity:[NSEntityDescription entityForName:@"Blog" inManagedObjectContext:moc]];
        NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"blogName" ascending:YES];
        [fetchRequest setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];
         sortDescriptor = nil;
        NSArray *results = [moc executeFetchRequest:fetchRequest error:&error];
        if (results && ([results count] > 0)) {
            self.activeBlog = [results objectAtIndex:0];
            //Disable selecting a blog if user has only one blog in the app.
            if ([results count] == 1) {
                [postToLabel setText: NSLocalizedString(@"Posting to:", @"")];
                self.enabled = NO;
                selectorImageView.alpha = 0.0f;
            }
        }
    }
}

- (void)setActiveBlog:(Blog *)aBlog {
    if (aBlog != activeBlog) {
        activeBlog = aBlog;
        [blavatarImageView setImageWithBlavatarUrl:activeBlog.blavatarUrl isWPcom:activeBlog.isWPcom];
        blogTitleLabel.text = activeBlog.blogName;
        if ([blogTitleLabel.text isEqualToString:@""]) {
            blogTitleLabel.text = activeBlog.hostURL;
        }
    }
}

- (void)animationDidStop:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context {
    if (!active) {
        [selectorViewController.tableView removeFromSuperview];
    }
}

- (void)tap {
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
    active = ! active;
    
    if (self.delegate) {
        if (active) {
            if ([self.delegate respondsToSelector:@selector(blogSelectorButtonWillBecomeActive:)]) {
                [self.delegate blogSelectorButtonWillBecomeActive:self];
            }
        } else {
            if ([self.delegate respondsToSelector:@selector(blogSelectorButtonWillBecomeInactive:)]) {
                [self.delegate blogSelectorButtonWillBecomeInactive:self];
            }            
        }
    }
    
    if (active) {
        normalFrame = self.frame;
        // Setup selection view
        CGRect selectionViewFrame = self.superview.bounds;
        selectionViewFrame.origin.y += self.frame.size.height;
        selectionViewFrame.size.height = 0; // setting the height to 0 will make iOS auto calculate the right height
        if (selectorViewController == nil) {
            selectorViewController = [[BlogSelectorViewController alloc] initWithStyle:UITableViewStylePlain];
            selectorViewController.selectedBlog = self.activeBlog;
            selectorViewController.delegate = self;
        }
        [selectorViewController.view setFrame:selectionViewFrame];
        [self addSubview:selectorViewController.view];
    }
    
    [UIView beginAnimations:@"activation" context:nil];
    [UIView setAnimationDidStopSelector:@selector(animationDidStop:finished:context:)];
    [UIView setAnimationDuration:0.15];
    if (active) {
        self.frame = self.superview.bounds;
        selectorImageView.transform = CGAffineTransformMakeRotation(M_PI);
    } else {
        self.frame = normalFrame;
        selectorImageView.transform = CGAffineTransformMakeRotation(0);
    }
    [UIView commitAnimations];
    
    if (self.delegate) {
        if (active) {
            if ([self.delegate respondsToSelector:@selector(blogSelectorButtonDidBecomeActive:)]) {
                [self.delegate blogSelectorButtonDidBecomeActive:self];
            }
        } else {
            if ([self.delegate respondsToSelector:@selector(blogSelectorButtonDidBecomeInactive:)]) {
                [self.delegate blogSelectorButtonDidBecomeInactive:self];
            }            
        }
    }
}

#pragma mark - Blog Selector delegate
- (void)blogSelectorViewController:(BlogSelectorViewController *)blogSelector didSelectBlog:(Blog *)blog {
    if (self.delegate && [self.delegate respondsToSelector:@selector(blogSelectorViewController:didSelectBlog:)]) {
        [self.delegate blogSelectorButton:self didSelectBlog:blog];
    }
    self.activeBlog = blog;
    NSString *defaultsKey = [self defaultsKey];
    if (defaultsKey != nil) {
        NSString *objectID = [[[self.activeBlog objectID] URIRepresentation] absoluteString];
        [[NSUserDefaults standardUserDefaults] setObject:objectID forKey:defaultsKey];
    }
    [self tap];
}

@end
