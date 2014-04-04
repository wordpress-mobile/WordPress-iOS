#import <Foundation/Foundation.h>

extern NSString *const CategoryServiceRemoteKeyID;
extern NSString *const CategoryServiceRemoteKeyName;
extern NSString *const CategoryServiceRemoteKeyParent;

@class WordPressComApi;

@protocol CategoryServiceRemoteAPI <NSObject>

/**
 Creates a category remotely
 
 success will be called with the newly created category ID as an argument
 */
- (void)createCategoryWithName:(NSString *)name
              parentCategoryID:(NSNumber *)parentCategoryID
                        siteID:(NSNumber *)siteID
                       success:(void (^)(NSNumber *categoryID))success
                       failure:(void (^)(NSError *error))failure;

/**
 Get the list of categories from the server
 
 success will be called with an array of dictionaries with the following keys:
 - id: NSNumber
 - name: NSString
 - parent: NSNumber. ID of parent category, or 0 if there's no parent
 */
- (void)getCategoriesForSiteWithID:(NSNumber *)siteID
                           success:(void (^)(NSArray *categories))success
                           failure:(void (^)(NSError *error))failure;

@end

@interface CategoryServiceRemote : NSObject<CategoryServiceRemoteAPI>

- (id)initWithApi:(WordPressComApi *)api;

@end