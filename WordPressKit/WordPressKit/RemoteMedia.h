#import <Foundation/Foundation.h>

@interface RemoteMedia : NSObject

@property (nonatomic, strong, nullable) NSNumber *mediaID;
@property (nonatomic, strong, nullable) NSURL *url;
@property (nonatomic, strong, nullable) NSURL *localURL;
@property (nonatomic, strong, nullable) NSURL *guid;
@property (nonatomic, strong, nullable) NSDate *date;
@property (nonatomic, strong, nullable) NSNumber *postID;
@property (nonatomic, strong, nullable) NSString *file;
@property (nonatomic, strong, nullable) NSString *mimeType;
@property (nonatomic, strong, nullable) NSString *extension;
@property (nonatomic, strong, nullable) NSString *title;
@property (nonatomic, strong, nullable) NSString *caption;
@property (nonatomic, strong, nullable) NSString *descriptionText;
@property (nonatomic, strong, nullable) NSString *alt;
@property (nonatomic, strong, nullable) NSNumber *height;
@property (nonatomic, strong, nullable) NSNumber *width;
@property (nonatomic, strong, nullable) NSString *shortcode;
@property (nonatomic, strong, nullable) NSDictionary *exif;
@property (nonatomic, strong, nullable) NSString *videopressGUID;
@property (nonatomic, strong, nullable) NSNumber *length;
@property (nonatomic, strong, nullable) NSString *remoteThumbnailURL;

@end
