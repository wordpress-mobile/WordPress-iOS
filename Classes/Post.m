// 
//  Post.m
//  WordPress
//
//  Created by Chris Boyd on 8/9/10.
//

#import "Post.h"


@implementation Post 

@dynamic content;
@dynamic geolocation;
@dynamic shouldResizePhotos;
@dynamic status;
@dynamic tags;
@dynamic shortlink;
@dynamic isLocalDraft;
@dynamic isPublished;
@dynamic permalink;
@dynamic postID;
@dynamic dateCreated;
@dynamic dateAutosaved;
@dynamic dateDeleted;
@dynamic blogID;
@dynamic dateModified;
@dynamic postTitle;
@dynamic postType;
@dynamic isAutosave;
@dynamic excerpt;
@dynamic password;
@dynamic datePublished;
@dynamic categories;
@dynamic author;
@dynamic uniqueID;
@dynamic wasLocalDraft;
@dynamic wasDeleted;
@dynamic isHidden;
@dynamic note;

- (NSDictionary *)legacyPost {
	NSMutableDictionary *convertedPost = [[[NSMutableDictionary alloc] init] autorelease];
	
	[convertedPost setValue:self.postTitle forKey:@"title"];
	[convertedPost setValue:self.author forKey:@"author"];
	if([self.postType isEqualToString:@"page"])
		[convertedPost setValue:[self.status lowercaseString] forKey:@"page_status"];
	else
		[convertedPost setValue:[self.status lowercaseString] forKey:@"post_status"];
	[convertedPost setValue:self.tags forKey:@"mt_keywords"];
	[convertedPost setValue:[self.categories componentsSeparatedByString:@", "] forKey:@"categories"];
	[convertedPost setValue:self.dateCreated forKey:@"dateCreated"];
	[convertedPost setValue:self.content forKey:@"description"];
	
	NSMutableArray *customFields = [[NSMutableArray alloc] init];
	NSMutableDictionary *localDraftUniqueID = [[NSMutableDictionary alloc] init];
	[localDraftUniqueID setValue:@"localDraftUniqueID" forKey:@"key"];
	[localDraftUniqueID setValue:self.uniqueID forKey:@"value"];
	[customFields addObject:localDraftUniqueID];
	[localDraftUniqueID release];
	[convertedPost setValue:customFields forKey:@"custom_fields"];
	[customFields release];
	
	return convertedPost;
}

@end
