//
//  Post.h
//  WordPress
//
//  Created by Chris Boyd on 8/9/10.
//

#import <CoreData/CoreData.h>


@interface Post :  NSManagedObject  
{
}

@property (nonatomic, retain) NSString * content;
@property (nonatomic, retain) NSString * geolocation;
@property (nonatomic, retain) NSNumber * shouldResizePhotos;
@property (nonatomic, retain) NSString * status;
@property (nonatomic, retain) NSString * tags;
@property (nonatomic, retain) NSString * shortlink;
@property (nonatomic, retain) NSNumber * isLocalDraft;
@property (nonatomic, retain) NSNumber * isPublished;
@property (nonatomic, retain) NSString * permalink;
@property (nonatomic, retain) NSString * postID;
@property (nonatomic, retain) NSDate * dateCreated;
@property (nonatomic, retain) NSDate * dateAutosaved;
@property (nonatomic, retain) NSDate * dateDeleted;
@property (nonatomic, retain) NSString * blogID;
@property (nonatomic, retain) NSDate * dateModified;
@property (nonatomic, retain) NSString * postTitle;
@property (nonatomic, retain) NSString * postType;
@property (nonatomic, retain) NSNumber * isAutosave;
@property (nonatomic, retain) NSNumber * wasLocalDraft;
@property (nonatomic, retain) NSString * excerpt;
@property (nonatomic, retain) NSString * password;
@property (nonatomic, retain) NSDate * datePublished;
@property (nonatomic, retain) NSString * categories;
@property (nonatomic, retain) NSString * author;
@property (nonatomic, retain) NSString * uniqueID;
@property (nonatomic, retain) NSNumber * wasDeleted;
@property (nonatomic, retain) NSNumber * isHidden;
@property (nonatomic, retain) NSString * note;

- (NSDictionary *)legacyPost;

@end



