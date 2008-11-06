#import <Foundation/Foundation.h>
/*
 */
#import "XMLRPCResponse.h"
#import "XMLRPCRequest.h"
#import "XMLRPCConnection.h"
//#import "WPXMLValidator.h"

#define PictureObjectUploadedNotificationName @"PictureObjectUploadedNotificationName"
#define WPNewCategoryCreatedAndUpdatedInBlogNotificationName @"WPNewCategoryCreatedAndUpdatedInBlog"

#define kPostsDownloadCount @"postsDownloadCount"
#define kDraftsBlogIdStr @"localDrafts"
#define kDraftsHostName @"iPhone"

#define kUnsupportedWordpressVersionTag 900
#define kRSDErrorTag 901

@interface BlogDataManager : NSObject 
{
	
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
	
	NSMutableArray *blogsList;
	NSMutableArray *postTitlesList, *draftTitlesList,*pageDraftTitlesList,*commentTitlesList,*pageTitlesList;
	NSMutableArray *photosDB;

	
	NSMutableDictionary *currentBlog;
	BOOL isLocaDraftsCurrent;
	
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
	
	NSOperationQueue *asyncOperationsQueue;
	
	NSOperationQueue *asyncPostsOperationsQueue;
	NSMutableDictionary *currentUnsavedDraft;
}

+ (BlogDataManager *)sharedDataManager;

@property (nonatomic) NSInteger currentPostIndex,currentDraftIndex,currentPageDraftIndex,currentPageIndex;

@property (nonatomic, copy) NSString *currentDirectoryPath;

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

@property (nonatomic, copy, readonly) NSMutableDictionary *currentBlog;
@property (nonatomic, assign) BOOL isLocaDraftsCurrent;

@property (nonatomic, copy, readonly) NSMutableDictionary *currentPost;
@property (nonatomic, retain, readonly) NSArray *pageFieldNames;
@property (nonatomic, retain) NSMutableDictionary *currentPage;
@property (nonatomic, readonly) NSOperationQueue *asyncPostsOperationsQueue;
@property (nonatomic) int unsavedPostsCount;
@property (nonatomic, retain) NSMutableDictionary *currentUnsavedDraft;
#pragma mark Blog metadata
- (NSArray *)blogFieldNames;
- (NSDictionary *)blogFieldNamesByTag;
- (NSDictionary *)blogFieldTagsByName;

- (BOOL)removeAutoSavedCurrentPostFile;
- (BOOL)clearAutoSavedContext;

#pragma mark Blog 
- (NSInteger)countOfBlogs;
- (NSDictionary *)blogAtIndex:(NSUInteger)theIndex;
- (NSDictionary *)blogForId:(NSString *)blogid hostName:(NSString *)hostname;
- (NSInteger)indexForBlogid:(NSString *)blogid hostName:(NSString *)hostname; 
- (void)makeBlogAtIndexCurrent:(NSUInteger)theIndex;
- (void)copyBlogAtIndexCurrent:(NSUInteger)theIndex;
- (void)makeNewBlogCurrent;
- (void)makeLocalDraftsCurrent;
- (void)saveCurrentBlog;
- (void)resetCurrentBlog;
- (void) savePhotosDB;
- (void)removeCurrentBlog;
- (id) newDraftsBlog;
- (void) addSyncPostsForBlogToQueue:(id)aBlog;
- (void) syncPostsForAllBlogsToQueue:(id)sender;

- (void) saveBlogData;
- (NSString *)templateHTMLStringForBlog:(id)aBlog isDefaultTemplate:(BOOL *)flag;
- (NSString *)defaultTemplateHTMLString;

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
- (id)loadPostTitlesForBlog:(id)aBlog;
- (void)loadPostTitlesForCurrentBlog;

- (NSMutableArray *)commentTitlesForBlog:(id)aBlog;
- (NSMutableArray *)commentTitlesForCurrentBlog;

- (void)loadCommentTitlesForCurrentBlog;
- (id)loadCommentTitlesForBlog:(id)aBlog;
- (NSInteger)countOfCommentTitles ;
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
-(id)pageDraftTitleAtIndex:(NSInteger)anIndex;

- (BOOL)makeDraftAtIndexCurrent:(NSInteger)anIndex;
- (BOOL)makePageDraftAtIndexCurrent:(NSInteger)anIndex;
- (BOOL)deleteDraftAtIndex:(NSInteger)anIndex forBlog:(id)aBlog;
- (void)resetDrafts;
- (void)resetCurrentDraft;

- (void)resetCurrentPage;
- (void)resetCurrentPageDraft;



#pragma mark Post metadata
- (NSArray *)postFieldNames;
- (NSDictionary *)postFieldNamesByTag;
- (NSDictionary *)postFieldTagsByName;

#pragma mark Sync with Blog Host
- (BOOL) refreshCurrentBlog:(NSString *)url user:(NSString *)username password:(NSString*)pwd;
- (BOOL)validateCurrentBlog:(NSString *)url user:(NSString *)username password:(NSString*)pwd;
- (BOOL) syncPostsForBlog:(id)blog;
- (BOOL) syncPostsForCurrentBlog;

- (BOOL) syncCommentsForCurrentBlog;
// sync comments for a given blog
- (BOOL) syncCommentsForBlog:(id)blog;
	
- (void)generateTemplateForBlog:(id)aBlog;
- (BOOL)wrapperForSyncPostsAndGetTemplateForBlog:(id)aBlog;



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
- (BOOL)autoSaveCurrentPost;
- (BOOL)makeAutoSavedPostCurrentForCurrentBlog;
- (id)autoSavedPostForCurrentBlog;


- (BOOL)postDescriptionHasValidDescription:(id)aPost;

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
- (BOOL) syncCommentsForCurrentBlog ;
- (BOOL) syncCommentsForBlog:(id)blog;
- (BOOL) deleteComment:(NSArray *) aComment forBlog:(id)blog;
- (BOOL) approveComment:(NSMutableArray *) aComment forBlog:(id)blog;
- (BOOL) unApproveComment:(NSMutableArray *) aComment forBlog:(id)blog;
- (BOOL) spamComment:(NSMutableArray *) aComment forBlog:(id)blog;
- (NSString *)savePostsFileWithAsynPostFlag:(NSMutableDictionary *)postDict;
- (void)updatePostsTitlesFileAfterPostSaved:(NSMutableDictionary *)dict;
- (void)removeTempFileForUnSavedPost:(NSString *)postId;
- (void)saveCurrentPostAsDraftWithAsyncPostFlag;
- (void)restoreUnsavedDraft;

//pages
- (BOOL) syncPagesForBlog:(id)blog;
- (NSInteger)countOfPageTitles;
- (NSDictionary *)pageTitleAtIndex:(NSUInteger)theIndex;
- (void)loadPageTitlesForCurrentBlog;
- (void)makePageAtIndexCurrent:(NSUInteger)theIndex;
- (BOOL)savePage:(id)aPage;
- (void)makeNewPageCurrent;
@end
