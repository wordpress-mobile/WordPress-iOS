//
//  SidebarTableViewCell.m
//  WordPress
//
//  Created by Danilo Ercoli on 05/06/12.
//  Copyright (c) 2012 WordPress. All rights reserved.
//

#import "SidebarTableViewCell.h"

@interface SidebarTableViewCell (Private)

- (void)receivedCommentsChangedNotification:(NSNotification*)aNotification;
- (UIImage *)badgeImage:(UIImage *)img withText:(NSString *)text1;

@end;

@implementation SidebarTableViewCell

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.textLabel.shadowOffset = CGSizeMake(0, 1.1f);
        self.textLabel.shadowColor = [UIColor blackColor];
        self.textLabel.textColor = [UIColor colorWithRed:221.0f/255.0f green:221.0f/255.0f blue:221.0f/255.0f alpha:1.0f];
        self.textLabel.font = [UIFont systemFontOfSize:17.0];
        self.backgroundView = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"sidebar_cell_bg"]] autorelease];
        self.selectedBackgroundView = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"sidebar_cell_bg_selected"]] autorelease];
    }
    return self;
}

- (Blog *)blog {
    return blog;
}

- (void)setBlog:(Blog *)value {
    blog = value;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    if ( blog ) { 
        //do other stuff here
        int numberOfPendingComments = [blog numberOfPendingComments];
        if( numberOfPendingComments > 0 ) {
            UIImage *img = [self badgeImage:[UIImage imageNamed:@"sidebar_comment_bubble"] withText:[NSString stringWithFormat:@"%d", numberOfPendingComments]];
            UIImageView *image = [[UIImageView alloc] initWithImage:img];
            self.accessoryView = image;
            [image release];
            
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(receivedCommentsChangedNotification:) 
                                                         name:kCommentsChangedNotificationName
                                                       object:blog];
        }
    }
}

- (void)prepareForReuse{
	[super prepareForReuse];
    self.blog = nil;
    self.accessoryView = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (void)receivedCommentsChangedNotification:(NSNotification*)aNotification {
    if ( blog ) { 
        //do other stuff here
        int numberOfPendingComments = [blog numberOfPendingComments];
        if( numberOfPendingComments > 0 ) {
            UIImage *img = [self badgeImage:[UIImage imageNamed:@"sidebar_comment_bubble"] withText:[NSString stringWithFormat:@"%d", numberOfPendingComments]];
            UIImageView *image = [[UIImageView alloc] initWithImage:img];
            self.accessoryView = image;
            [image release];
        } else {
            self.accessoryView = nil;
        }
    }
}


//Add text to UIImage - ref: http://iphonesdksnippets.com/post/2009/05/05/Add-text-to-image-(UIImage).aspx
-(UIImage *)badgeImage:(UIImage *)img withText:(NSString *)text1{ 
    int w = img.size.width; 
    int h = img.size.height; 
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB(); 
    CGContextRef context = CGBitmapContextCreate(NULL, w, h, 8, 4 * w, colorSpace, kCGImageAlphaPremultipliedFirst); 
    CGContextDrawImage(context, CGRectMake(0, 0, w, h), img.CGImage); 
    
    //draw the text invisible so we can calculate the center position later
    char* text= (char *)[text1 cStringUsingEncoding:NSASCIIStringEncoding]; 
    CGContextSetTextDrawingMode(context, kCGTextInvisible);
    CGContextSelectFont(context, "Helvetica", 16, kCGEncodingMacRoman);
    CGContextShowTextAtPoint(context, 0, 0, text, strlen(text));
    CGPoint pt = CGContextGetTextPosition(context);
    
    CGContextSetTextDrawingMode(context, kCGTextFill); 
    CGContextSetShadow(context, CGSizeMake(0.0f, 1.0f), 1.0f);
    CGContextSetRGBFillColor(context, 255, 255, 255, 1); 
    CGContextShowTextAtPoint(context,(w / 2) - pt.x / 2, 7,text, strlen(text)); 
    CGImageRef imgCombined = CGBitmapContextCreateImage(context); 
    
    CGContextRelease(context); 
    CGColorSpaceRelease(colorSpace); 
    
    UIImage *retImage = [UIImage imageWithCGImage:imgCombined]; 
    CGImageRelease(imgCombined); 
    
    return retImage; 
}

@end
