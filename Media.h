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

typedef NS_ENUM(NSUInteger, MediaRemoteStatus) {
    MediaRemoteStatusPushing,    // Uploading post
    MediaRemoteStatusFailed,      // Upload failed
    MediaRemoteStatusLocal,       // Only local version
    MediaRemoteStatusSync,       // Post uploaded
    MediaRemoteStatusProcessing, // Intermediate status before uploading
};

@interface Media :  NSManagedObject  
{
}

@property (nonatomic, strong) NSNumber * mediaID;
@property (nonatomic, strong) NSString * mediaType;
@property (weak, nonatomic, readonly) NSString * mediaTypeName;
@property (nonatomic, strong) NSString * remoteURL;
@property (nonatomic, strong) NSString * localURL;
@property (nonatomic, strong) NSString * shortcode;
@property (nonatomic, strong) NSNumber * length;
@property (nonatomic, strong) NSString * title;
@property (nonatomic, strong) NSData * thumbnail;
@property (nonatomic, strong) NSString * filename;
@property (nonatomic, strong) NSNumber * filesize;
@property (nonatomic, strong) NSNumber * width;
@property (nonatomic, strong) NSNumber * height;
@property (nonatomic, strong) NSString * orientation;
@property (nonatomic, strong) NSDate * creationDate;
@property (weak, nonatomic, readonly) NSString * html;
@property (nonatomic, strong) NSNumber * remoteStatusNumber;
@property (nonatomic) MediaRemoteStatus remoteStatus;
@property (nonatomic) float progress;

@property (nonatomic, strong) Blog * blog;
@property (nonatomic, strong) NSMutableSet * posts;

+ (Media *)newMediaForPost:(AbstractPost *)post;
- (void)cancelUpload;
- (void)uploadWithSuccess:(void (^)())success failure:(void (^)(NSError *error))failure;
- (void)remove;
- (void)save;
- (void)setImage:(UIImage *)image withSize:(MediaResize)size;

@end



