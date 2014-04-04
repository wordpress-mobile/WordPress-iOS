#import <Foundation/Foundation.h>


@interface NoteAction : NSObject

@property (nonatomic, readonly) NSString		*type;
@property (nonatomic, readonly) NSDictionary	*parameters;

// Helpers!
@property (nonatomic, readonly) NSString		*blogDomain;
@property (nonatomic, readonly) NSNumber		*blogID;
@property (nonatomic, readonly) NSString		*blogTitle;
@property (nonatomic, readonly) NSURL			*blogURL;
@property (nonatomic, readonly) NSNumber		*siteID;
@property (nonatomic,   assign) BOOL			following;
@property (nonatomic, readonly) NSString		*statsSource;

+ (NoteAction *)parseAction:(NSDictionary *)dict;

@end
