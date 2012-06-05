//
//  SidebarTableViewCell.m
//  WordPress
//
//  Created by Danilo Ercoli on 05/06/12.
//  Copyright (c) 2012 WordPress. All rights reserved.
//

#import "SidebarTableViewCell.h"

@interface SidebarTableViewCell ()

- (void)receivedCommentsChangedNotification:(NSNotification*)aNotification;
-(UIImage *)addText:(UIImage *)img text:(NSString *)text1;

@end;

@implementation SidebarTableViewCell

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
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
            UIImage *img = [self addText:[UIImage imageNamed:@"inner-shadow.png"] text:[NSString stringWithFormat:@"%d", numberOfPendingComments]];
            UIImageView *image = [[UIImageView alloc] initWithImage:img];
            self.accessoryView = image;
            [image release];
            
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(receivedCommentsChangedNotification:) 
                                                         name:kCommentsChangedNotificationName
                                                       object:blog];
        }
    } else {
        
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
            UIImage *img = [self addText:[UIImage imageNamed:@"inner-shadow.png"] text:[NSString stringWithFormat:@"%d", numberOfPendingComments]];
            UIImageView *image = [[UIImageView alloc] initWithImage:img];
            self.accessoryView = image;
            [image release];
        } else {
            self.accessoryView = nil;
        }
    }
}


//Add text to UIImage - ref: http://iphonesdksnippets.com/post/2009/05/05/Add-text-to-image-(UIImage).aspx
-(UIImage *)addText:(UIImage *)img text:(NSString *)text1{ 
    int w = img.size.width; 
    int h = img.size.height; 
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB(); 
    CGContextRef context = CGBitmapContextCreate(NULL, w, h, 8, 4 * w, colorSpace, kCGImageAlphaPremultipliedFirst); 
    CGContextDrawImage(context, CGRectMake(0, 0, w, h), img.CGImage); 
    
    char* text= (char *)[text1 cStringUsingEncoding:NSASCIIStringEncoding]; 
    CGContextSelectFont(context, "Arial", 17, kCGEncodingMacRoman); 
    CGContextSetTextDrawingMode(context, kCGTextFill); 
    CGContextSetRGBFillColor(context, 0, 0, 0, 1); 
    CGContextShowTextAtPoint(context,10,10,text, strlen(text)); 
    CGImageRef imgCombined = CGBitmapContextCreateImage(context); 
    
    CGContextRelease(context); 
    CGColorSpaceRelease(colorSpace); 
    
    UIImage *retImage = [UIImage imageWithCGImage:imgCombined]; 
    CGImageRelease(imgCombined); 
    
    return retImage; 
}

@end
