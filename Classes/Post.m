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
	
	[convertedPost setValue:self.postID forKey:@"postid"];
	[convertedPost setValue:self.postTitle forKey:@"title"];
	[convertedPost setValue:self.author forKey:@"author"];
	if([self.postType isEqualToString:@"page"])
		[convertedPost setValue:[self.status lowercaseString] forKey:@"page_status"];
	else
		[convertedPost setValue:[self.status lowercaseString] forKey:@"post_status"];
	[convertedPost setValue:self.tags forKey:@"mt_keywords"];
 	[convertedPost setValue:self.categories forKey:@"categories"];
	[convertedPost setValue:self.content forKey:@"description"];
	[convertedPost setValue:self.dateCreated forKey:@"dateCreated"];
	
	NSInteger secs = [[NSTimeZone localTimeZone] secondsFromGMTForDate:self.dateCreated];
	NSDate *gmtDate = [self.dateCreated addTimeInterval:(secs * -1)];
	[convertedPost setValue:gmtDate forKey:@"date_created_gmt"];
	
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

- (NSString *)categoriesText {
    NSMutableArray *categoryLabels = [NSMutableArray arrayWithCapacity:[self.categories count]];
    NSMutableSet *categories = self.categories;
    for (Category *category in categories) {
        [categoryLabels addObject:category.categoryName];
    }
    return [categoryLabels componentsJoinedByString:@", "];
}

- (NSArray *)categoriesDict {
    NSMutableArray *result = [NSMutableArray array];
    for (Category *category in self.categories) {
        NSDictionary *categoryDict = [NSDictionary dictionaryWithObjectsAndKeys:
                                      category.categoryId,
                                      @"categoryId",
                                      category.categoryName,
                                      @"categoryName",
                                      category.parentId,
                                      @"parentId",
                                      category.desc,
                                      @"description",
                                      category.htmlUrl,
                                      @"htmlUrl",
                                      category.rssUrl,
                                      @"rssUrl", nil];
        [result addObject:categoryDict];
    }

    return result;
}

- (void)setCategoriesDict:(NSArray *)categoriesDict {
    [self setValue:[NSMutableSet new] forKey:@"categories"];
    WordPressAppDelegate *appDelegate = (WordPressAppDelegate *)[[UIApplication sharedApplication] delegate];
    for (NSDictionary *categoryDict in categoriesDict) {
        Category *category;
        NSArray *items;
        @try {
            NSFetchRequest *request = [[NSFetchRequest alloc] init];
            NSEntityDescription *entity = [NSEntityDescription entityForName:@"Category"
                                                      inManagedObjectContext:appDelegate.managedObjectContext];
            [request setEntity:entity];

            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(categoryId like %@) AND (blogId like %@)",
                                      [categoryDict objectForKey:@"categoryId"],
                                      self.blogID];
            [request setPredicate:predicate];

            NSError *error;
            items = [appDelegate.managedObjectContext executeFetchRequest:request error:&error];
            [request release];
        }
        @catch (NSException *e) {
            NSLog(@"error checking existence of category: %@", e);
            items = nil;
        }

        if ((items != nil) && (items.count > 0)) {
            // Already exists
            category = [items objectAtIndex:0];
        } else {
            category = [NSEntityDescription insertNewObjectForEntityForName:@"Category" inManagedObjectContext:appDelegate.managedObjectContext];;
            [category setCategoryId:[categoryDict objectForKey:@"categoryId"]];
            [category setCategoryName:[categoryDict objectForKey:@"categoryName"]];
            [category setDesc:[categoryDict objectForKey:@"description"]];
            [category setHtmlUrl:[categoryDict objectForKey:@"htmlUrl"]];
            [category setRssUrl:[categoryDict objectForKey:@"rssUrl"]];
            [category setParentId:[categoryDict objectForKey:@"parentId"]];
            [category setBlogId:self.blogID];
        }

        NSMutableSet *categories = [self mutableSetValueForKey:@"categories"];
        [categories addObject:category];
        [self setValue:categories forKey:@"categories"];
    }
}

@end
