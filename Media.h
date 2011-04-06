//
//  Media.h
//  WordPress
//
//  Created by Chris Boyd on 6/23/10.
//  
//

#import <CoreData/CoreData.h>
#import "Blog.h"
#import "AbstractPost.h"
#import "WPMediaUploader.h"

typedef enum {
    MediaRemoteStatusPushing,    // Uploading post
    MediaRemoteStatusFailed,      // Upload failed
    MediaRemoteStatusLocal,       // Only local version
    MediaRemoteStatusSync,       // Post uploaded
} MediaRemoteStatus;

@class WPMediaUploader;

@interface Media :  NSManagedObject  
{
}

@property (nonatomic, retain) NSString * mediaType;
@property (nonatomic, readonly) NSString * mediaTypeName;
@property (nonatomic, retain) NSString * remoteURL;
@property (nonatomic, retain) NSString * localURL;
@property (nonatomic, retain) NSString * shortcode;
@property (nonatomic, retain) NSNumber * length;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSData * thumbnail;
@property (nonatomic, retain) NSString * filename;
@property (nonatomic, retain) NSNumber * filesize;
@property (nonatomic, retain) NSNumber * width;
@property (nonatomic, retain) NSNumber * height;
@property (nonatomic, retain) NSString * orientation;
@property (nonatomic, retain) NSDate * creationDate;
@property (nonatomic, readonly) NSString * html;
@property (nonatomic, retain) NSNumber * remoteStatusNumber;
@property (nonatomic) MediaRemoteStatus remoteStatus;
@property (nonatomic, retain) WPMediaUploader * uploader;
@property (nonatomic) float progress;

@property (nonatomic, retain) Blog * blog;
@property (nonatomic, retain) NSMutableSet * posts;

+ (Media *)newMediaForPost:(AbstractPost *)post;
- (void)cancelUpload;
- (void)upload;
- (void)remove;
- (void)save;
- (void)setImage:(UIImage *)image withSize:(MediaResize)size;

@end



