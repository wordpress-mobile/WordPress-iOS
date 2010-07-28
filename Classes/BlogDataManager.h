#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "XMLRPCResponse.h"
#import "XMLRPCRequest.h"
#import "XMLRPCConnection.h"
#import "RegExProcessor.h"
#import "SFHFKeychainUtils.h"
#import "Reachability.h"
#import "Blog.h"

#define PictureObjectUploadedNotificationName @"PictureObjectUploadedNotificationName"
#define WPNewCategoryCreatedAndUpdatedInBlogNotificationName @"WPNewCategoryCreatedAndUpdatedInBlog"

#define kPostsDownloadCount @"postsDownloadCount"
//#define kPagesDownloadCount @"pagesDownloadCount"
#define kDraftsBlogIdStr @"localDrafts"
#define kDraftsHostName @"iPhone"

#define kUnsupportedWordpressVersionTag 900
#define kRSDErrorTag 901

@interface BlogDataManager : NSObject {
    NSMutableArray *blogsList;
@private
    NSArray *blogFieldNames;
    NSDictionary *blogFieldNamesByTag;
    NSDictionary *blogFieldTagsByName;
	
    NSArray *postTitleFieldNames;
    NSDictionary *postTitleFieldNamesByTag;
    NSDictionary *postTitleFieldTagsByName;
	
    NSArray *postFieldNames;
    NSDictionary *postFieldNamesByTag;
    NSDictionary *postFieldTagsByName;
	
    NSArray *pictureFieldNames;
    NSMutableArray *postTitlesList, *draftTitlesList, *pageDraftTitlesList, *commentTitlesList, *pageTitlesList;
    NSMutableArray *photosDB;
	
    NSMutableDictionary *currentBlog;
    BOOL isLocaDraftsCurrent;
    BOOL isPageLocalDraftsCurrent;
	BOOL shouldStopSyncingBlogs;
	BOOL isSyncingCommentsAndStatuses;
	BOOL shouldDisplayErrors;
	
    NSMutableDictionary *currentPost;
    NSArray *pageFieldNames;
	
    NSMutableDictionary *currentPage;
	
    NSMutableDictionary *currentPicture;
	
    NSInteger currentPostIndex;
    NSInteger currentDraftIndex;
    NSInteger currentPageDraftIndex;
	
    NSInteger currentBlogIndex;
    NSInteger currentPageIndex;
    int currentPictureIndex;
    int unsavedPostsCount;
	
    NSString *currentDirectoryPath;
	NSString *selectedBlogID;
	
    NSOperationQueue *asyncOperationsQueue;
	
    NSOperationQueue *asyncPostsOperationsQueue;
    NSMutableDictionary *currentUnsavedDraft;
	
	BOOL isProblemWithXMLRPC;
	CLLocation *currentLocation;
}

+ (BlogDataManager *)sharedDataManager;

@property (nonatomic) NSInteger currentPostIndex, currentDraftIndex, currentPageDraftIndex, currentPageIndex;

@property (nonatomic, copy) NSString *currentDirectoryPath, *selectedBlogID;

// readonly - can be retained rather than copied
@property (nonatomic, retain, readonly) NSArray *blogFieldNames;
@property (nonatomic, retain, readonly) NSDictionary *blogFieldNamesByTag;
@property (nonatomic, retain, readonly) NSDictionary *blogFieldTagsByName;

@property (nonatomic, retain, readonly) NSArray *postTitleFieldNames;
@property (nonatomic, retain, readonly) NSDictionary *postTitleFieldNamesByTag;
@property (nonatomic, retain, readonly) NSDictionary *postTitleFieldTagsByName;

@property (nonatomic, retain, readonly) NSArray *postFieldNames;
@property (nonatomic, retain, readonly) NSDictionary *postFieldNamesByTag;
@property (nonatomic, retain, readonly) NSDictionary *postFieldTagsByName;

@property (nonatomic, retain, readonly) NSArray *pictureFieldNames;
@property (nonatomic, retain) NSMutableArray *photosDB;
@property (nonatomic, retain) NSMutableDictionary *currentPicture;
@property (nonatomic, retain) NSMutableArray *blogsList;

@property (nonatomic, copy, readonly) NSMutableDictionary *currentBlog;
@property (nonatomic, assign) BOOL shouldStopSyncingBlogs, isSyncingCommentsAndStatuses, isLocaDraftsCurrent;
@property (nonatomic, assign) BOOL isPageLocalDraftsCurrent, shouldDisplayErrors;

@property (nonatomic, assign) NSInteger currentBlogIndex;
@property (nonatomic, copy, readonly) NSMutableDictionary *currentPost;
@property (nonatomic, retain, readonly) NSArray *pageFieldNames;
@property (nonatomic, retain) NSMutableDictionary *currentPage;
@property (nonatomic, readonly) NSOperationQueue *asyncPostsOperationsQueue;
@property (nonatomic) int unsavedPostsCount;
@property (nonatomic, retain) NSMutableDictionary *currentUnsavedDraft;
@property (nonatomic, retain) CLLocation *currentLocation;
//BOOLs for handling XMLRPC issues...  See LocateXMLRPCViewController
@property BOOL isProblemWithXMLRPC; 



#pragma mark Blog metadata

- (NSArray *)blogFieldNames;
- (NSDictionary *)blogFieldNamesByTag;
- (NSDictionary *)blogFieldTagsByName;

- (BOOL)removeAutoSavedCurrentPostFile;
- (BOOL)clearAutoSavedContext;

#pragma mark Blog

- (NSInteger)countOfBlogs;
- (NSMutableDictionary *)blogAtIndex:(NSUInteger)theIndex;
- (NSDictionary *)blogForId:(NSString *)blogid hostName:(NSString *)hostname;
- (NSInteger)indexForBlogid:(NSString *)blogid url:(NSString *)url;
- (void)makeBlogAtIndexCurrent:(NSUInteger)theIndex;
- (void)copyBlogAtIndexCurrent:(NSUInteger)theIndex;
- (void)makeNewBlogCurrent;
- (void)makeLocalDraftsCurrent;
- (void)saveCurrentBlog;
- (void)resetCurrentBlog;
- (void)setCurrentBlog:(NSMutableDictionary *)aBlog;
- (void)savePhotosDB;
- (void)removeCurrentBlog;
//- (id)newDraftsBlog;
- (void)addSyncPostsForBlogToQueue:(id)aBlog;
- (void)syncPostsForAllBlogsToQueue:(id)sender;
- (NSString *)blogDir:(id)aBlog;
- (void)saveBlogData;
- (NSString *)templateHTMLStringForBlog:(id)aBlog isDefaultTemplate:(BOOL *)flag;
- (NSString *)defaultTemplateHTMLString;
- (void)newAccountPostsAndTemplateSync:(id)aBlog;

#pragma mark Post Title metadata

- (NSArray *)postTitleFieldNames;
- (NSDictionary *)postTitleFieldNamesByTag;
- (NSDictionary *)postTitleFieldTagsByName;

#pragma mark PostTitles

- (NSInteger)countOfPostTitles;
- (NSDictionary *)postTitleAtIndex:(NSUInteger)theIndex;
- (NSDictionary *)postTitleForId:(NSString *)postTitleid;
- (NSUInteger)indexForPostTitleId:(NSString *)postTitleid;
- (void)resetPostTitlesList;

#pragma mark Post Titles List

- (NSMutableArray *)postTitlesForBlog:(id)aBlog;
- (NSMutableArray *)pageTitlesForBlog:(id)aBlog;
- (id)loadPostTitlesForBlog:(id)aBlog;
- (void)loadPostTitlesForCurrentBlog;

- (NSMutableArray *)commentTitlesForBlog:(id)aBlog;
- (NSMutableArray *)commentTitlesForCurrentBlog;
- (NSMutableArray *)commentTitlesForBlog:(id)aBlog scopedToPostWithIndex:(int)indexForPost;

- (void)loadCommentTitlesForCurrentBlog;
- (id)loadCommentTitlesForBlog:(id)aBlog;
- (NSInteger)countOfCommentTitles;
- (int)countOfAwaitingComments;
- (NSArray *)commentTitles;
- (NSDictionary *)commentTitleAtIndex:(NSUInteger)theIndex;

- (NSInteger)numberOfDrafts;
- (NSInteger)numberOfPageDrafts;
- (NSMutableArray *)draftTitlesForBlog:(id)aBlog;
- (void)loadDraftTitlesForBlog:(id)aBlog;
- (void)loadDraftTitlesForCurrentBlog;
- (void)loadPageDraftTitlesForBlog:(id)aBlog;
- (void)loadPageDraftTitlesForCurrentBlog;
- (id)draftTitleAtIndex:(NSInteger)anIndex;
- (id)pageDraftTitleAtIndex:(NSInteger)anIndex;

- (BOOL)makeDraftAtIndexCurrent:(NSInteger)anIndex;
- (BOOL)makePageDraftAtIndexCurrent:(NSInteger)anIndex;
- (BOOL)deleteDraftAtIndex:(NSInteger)anIndex forBlog:(id)aBlog;
- (BOOL)deletePageDraftAtIndex:(NSInteger)anIndex forBlog:(id)aBlog;
- (void)resetDrafts;
- (void)resetCurrentDraft;

- (void)resetCurrentPage;
- (void)resetCurrentPageDraft;
- (NSString *)pathToPageTitles:(id)aBlog;
- (NSString *)pageFilePath:(id)aPage forBlog:(id)aBlog;
- (void)setPageTitlesList:(NSMutableArray *)newArray;

#pragma mark Post metadata

- (NSArray *)postFieldNames;
- (NSDictionary *)postFieldNamesByTag;
- (NSDictionary *)postFieldTagsByName;

#pragma mark Sync with Blog Host

- (BOOL)refreshCurrentBlog:(NSString *)url user:(NSString *)username;
- (BOOL)refreshCurrentBlogQuickly:(NSString *)url user:(NSString *)username;
- (BOOL)validateCurrentBlog:(NSString *)url user:(NSString *)username password:(NSString *)pwd;
- (void)syncBlogs;
- (void)syncBlogCategoriesAndStatuses;
- (void)stopSyncingBlogs;
- (BOOL)syncPostsForBlog:(id)blog;
- (BOOL)syncPostsForCurrentBlog;
- (void)syncCategoriesForBlog:(NSMutableDictionary *)aBlog;
- (void)syncStatusesForBlog:(NSMutableDictionary *)aBlog;
- (BOOL)syncIncrementallyLoadedPostsForCurrentBlog:(NSArray *)recentPostsList;
- (BOOL)organizePostsForBlog:(id)blog withPostsArray:(NSArray *) recentPostsList;

- (void)generateTemplateForBlog:(id)aBlog;
- (void)wrapperForSyncPostsAndGetTemplateForBlog:(id)aBlog;

#pragma mark Post

- (NSInteger)countOfPosts;
- (NSDictionary *)postAtIndex:(NSUInteger)theIndex;
- (NSDictionary *)postForId:(NSString *)postid;
- (NSUInteger)indexForPostid:(NSString *)postid;
- (void)makePostAtIndexCurrent:(NSUInteger)theIndex;
- (void)makeNewPostCurrent;
- (void)saveCurrentPostAsDraft;
- (void)saveCurrentPageAsDraft;
- (void)resetCurrentPost;
//- (BOOL)publishCurrentPost;
- (BOOL)savePost:(id)aPost;
- (BOOL)deletePost;
- (BOOL)autoSaveCurrentPost;
- (BOOL)makeAutoSavedPostCurrentForCurrentBlog;
- (BOOL)hasAutosavedPost;
- (id)autoSavedPostForCurrentBlog;
- (NSString *)blogDir:(id)aBlog;
- (BOOL)makePostWithPostIDCurrent:(NSString *)postID;
- (BOOL)postDescriptionHasValidDescription:(id)aPost;
- (NSMutableDictionary *)postTitleForPost:(NSDictionary *)aPost;
- (NSMutableDictionary *)pageTitleForPage:(NSDictionary *)aPage;

#pragma mark CategoriesCreation

- (BOOL)createCategory:(NSString *)catTitle parentCategory:(NSString *)parentTitle forBlog:(id)aBlog;
- (void)downloadAllCategoriesForBlog:(id)aBlog;

#pragma mark Pictures

- (int)countOfPictures;
- (NSDictionary *)pictureAtIndex:(NSUInteger)theIndex;
- (void)makePictureAtIndexCurrent:(NSUInteger)theIndex;
- (void)makeNewPictureCurrent;
- (void)saveCurrentPicture;
- (void)resetCurrentPicture;
- (void)addValueToCurrentPicture:(id)anObject forKey:(NSString *)aKey;
- (void)savePhotosDB;
- (NSString *)statusStringForPicture:(id)aPictObj;
- (NSString *)pictureURLBySendingToServer:(UIImage *)pict;

#pragma mark Pictures List

- (void)loadPictures;

#pragma mark Image

- (NSString *)saveImage:(UIImage *)aImage;
- (UIImage *)imageNamed:(NSString *)name forBlog:(id)blog;
- (BOOL)deleteImageNamed:(NSString *)name forBlog:(id)blog;
- (UIImage *)thumbnailImageNamed:(NSString *)name forBlog:(id)blog;
- (UIImage *)scaleAndRotateImage:(UIImage *)image;

- (void)addSendPictureMsgToQueue:(id)aPicture;
- (int)currentPictureIndex;
- (void)setCurrentPictureIndex:(int)anIndex;

#pragma mark util methods

- (NSArray *)uniqueArray:(NSArray *)array;

//these methods will take currentBlog
- (NSString *)statusForStatusDescription:(NSString *)statusDescription fromBlog:(id)aBlog;
- (NSString *)statusDescriptionForStatus:(NSString *)curStatus fromBlog:(id)aBlog;
- (NSString *)pageStatusDescriptionForStatus:(NSString *)curStatus fromBlog:(id)aBlog;

// sync comments for a given blog
- (BOOL)syncCommentsForCurrentBlog;
- (BOOL)syncCommentsForBlog:(id)blog;
- (BOOL)deleteComment:(NSArray *)aComment forBlog:(id)blog;
- (BOOL)approveComment:(NSMutableArray *)aComment forBlog:(id)blog;
- (BOOL)unApproveComment:(NSMutableArray *)aComment forBlog:(id)blog;
- (BOOL)spamComment:(NSMutableArray *)aComment forBlog:(id)blog;
- (BOOL)replyToComment:(NSMutableDictionary *)aComment forBlog:(id)blog;
- (BOOL)editComment:(NSMutableDictionary *)aComment forBlog:(id)blog;
- (NSString *)savePostsFileWithAsynPostFlag:(NSMutableDictionary *)postDict;
- (void)updatePostsTitlesFileAfterPostSaved:(NSMutableDictionary *)dict;
- (void)removeTempFileForUnSavedPost:(NSString *)postId;
- (void)saveCurrentPostAsDraftWithAsyncPostFlag;
- (void)restoreUnsavedDraft;
- (NSString *)pathToPostTitles:(id)forBlog;

//pages
- (BOOL)syncPagesForBlog:(id)blog;
- (NSInteger)countOfPageTitles;
- (NSDictionary *)pageTitleAtIndex:(NSUInteger)theIndex;
- (void)loadPageTitlesForCurrentBlog;
- (void)makePageAtIndexCurrent:(NSUInteger)theIndex;
- (BOOL)savePage:(id)aPage;
- (BOOL)deletePage;
- (void)makeNewPageCurrent;

- (NSString *)pageStatusForStatusDescription:(NSString *)statusDescription fromBlog:(id)aBlog;

- (BOOL)doesBlogExist:(NSDictionary *)aBlog;

//utils
- (void)printArrayToLog:(NSArray *)theArray andArrayName:(NSString *)theArrayName;
- (void)printDictToLog:(NSDictionary *)theDict andDictName:(NSString *)theDictName;

//exposing XMLRPC call to use as test in LocateXMLRPCViewController
- (id)executeXMLRPCRequest:(XMLRPCRequest *)req byHandlingError:(BOOL)shouldHandleFalg;

#pragma mark -
#pragma mark CRUD for keychain Passwords
//Note: we use other data elements here, but password is the only data element persisted here...
//all other persistence is as it was before this change (I.E. inside blogsList and written to filesystem
//from blogsList

-(NSString*) getPasswordFromKeychainInContextOfCurrentBlog:(NSDictionary *)theCurrentBlog;
-(NSString *) getHTTPPasswordFromKeychainInContextOfCurrentBlog:(NSDictionary *)theCurrentBlog;
-(NSString*) getBlogPasswordFromKeychainWithUsername:(NSString *)userName andBlogName:(NSString *)blogName;
-(void) saveBlogPasswordToKeychain:(NSString *)password andUserName:(NSString *)userName andBlogURL:(NSString *)blogURL;
-(void) updatePasswordInKeychain:(NSString *)password andUserName:(NSString *)userName andBlogURL:(NSString *)blogURL;
-(void) deleteBlogFromKeychain:(NSString *)userName andBlogURL:(NSString *)blogURL;

#pragma mark -
#pragma mark upgrade Password into Keychain Upgrade Helper
//See comments above method in BlogDataManager.m file (end)
- (void) replaceBlogWithBlog:(NSMutableDictionary *)aBlog atIndex:(int)anIndex;

#pragma mark -
#pragma mark Misc.

-(void) printArrayToLog:(NSArray *) theArray andArrayName:(NSString *)theArrayName;
-(void) printDictToLog:(NSDictionary *)theDict andDictName:(NSString *)theDictName;

#pragma mark -
#pragma mark exposing some private methods for IncrementPost

- (NSString *)getPathToPost:(id)aPost forBlog:(id)aBlog;
- (void) updateBlogsListByIndex:(NSInteger )blogIndex withDict:(NSDictionary *) aBlog;

@end
