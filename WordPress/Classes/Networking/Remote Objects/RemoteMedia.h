@interface RemoteMedia : NSObject

@property (nonatomic, strong) NSNumber *mediaID;
@property (nonatomic, strong) NSURL *url;
@property (nonatomic, strong) NSString *localURL;
@property (nonatomic, strong) NSURL *guid;
@property (nonatomic, strong) NSDate *date;
@property (nonatomic, strong) NSNumber *postID;
@property (nonatomic, strong) NSString *file;
@property (nonatomic, strong) NSString *mimeType;
@property (nonatomic, strong) NSString *extension;
@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *caption;
@property (nonatomic, strong) NSString *descriptionText;
@property (nonatomic, strong) NSNumber *height;
@property (nonatomic, strong) NSNumber *width;
@property (nonatomic, strong) NSString *shortcode;
@property (nonatomic, strong) NSDictionary *exif;
@property (nonatomic, strong) NSString *videopressGUID;
@property (nonatomic, strong) NSNumber *length;
@property (nonatomic, strong) NSString *remoteThumbnailURL;

@end