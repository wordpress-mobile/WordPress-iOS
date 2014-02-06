/*
 * Copyright 2012 Quantcast Corp.
 *
 * This software is licensed under the Quantcast Mobile App Measurement Terms of Service
 * https://www.quantcast.com/learning-center/quantcast-terms/mobile-app-measurement-tos
 * (the “License”). You may not use this file unless (1) you sign up for an account at
 * https://www.quantcast.com and click your agreement to the License and (2) are in
 * compliance with the License. See the License for the specific language governing
 * permissions and limitations under the License.
 *
 */

#import "QuantcastMeasurement.h"

/*!
 @class QuantcastMeasurement+Periodicals
 @abstract An extension to the Quantcast SDK to allow detailed measurement of periodicals, such as magazines and newspaper apps.
 @discussion This extension to the Quantcast Measure SDK enables you to measure the user egagement and composition of periodicals, such as magazines and newspaper apps, particularly Newsstand apps on iOS. To measure a periodical app properly, you should at a minimum log the opening and closing of each issue, plus log each page view in each issue. You may optionally log the viewing of each article by name and log the downloading of content. 
 
 Each of the methods below ask for a periodical name, which is used for three purposes. First, it will be used to identify the periodical being reported on, most notably to allow cross platform reports of a given periodical issue. For example, if you have an iOS and Andoid app for the same digital magazine but named the the apps slightly different (e.g., "Cool Magazine iOS" and "Cool Magazine Android"), the periodical name parameter would allow you to name them identically so that Quantcast can provide consolidated reporting on the periodical and its issues regardless of platform (e.g. "Cool Magazine"). Secondly, if your app actually contains multiple periodicals, the periodical name parameter would let you differentiate amongst them. Thirdly, the periodical name as provided will be the display name of your periodical in reports.
 
 Each issue should be named with an unique, human-readable name, which will be used for display purposes in reporting. The issue name needs to be unique for the provided periodical name. That is, the combination of periodical name and issue name will be used to uniquely identify an issue (within you Quantcast account). Each issue should additionly have a publication date ascociated with it. The publication date is primarily used for sorting purposes. If the chief identifier for an issue is the month in which it was published, your should name the issue something like "August 2013" and set the publication date to 2013/08/01. When the issues are displayed in reports, the publication date will determine the ordering, not the issue name. If multiple issue dates end up being provided to Quantcast for a given periodical name and issue name combination, the earliest date will be used.
 
 Note that if you localize any of the human readable paramters (periodical name, issue name, article name, author name), each variation will be treated as a seperate value. For example, if in English you name your digital magazine "Magazine" and in Spanish you name it "Revista", Quantcast will treat those as two seperate periodicals and report on them independently. 
 */

@interface QuantcastMeasurement (Periodicals)

#pragma mark - Measurement and Analytics
/*!
 @method logOpenIssueWithPeriodicalNamed:issueNamed:issuePublicationDate:withLabels:
 @abstract Call this method to log when the user has caused a particular issue to be opened for reading. Required for proper periodical measurement.
 @discussion Call this method to log when the user has caused a particular issue to be opened for reading, meaning the user has selected this issue for viewing from a list of available issues. 
 @param inPeriodicalName A human-readable name for the periodical being reported on. This, combined with the inIssueName will uniquely identify an issue. 
 @param inIssueName A human-readable name for this issue. If the chief identifier for an issue is the month in which it was published, your should name the issue something like "August 2013".
 @param inPublicationDate The publication date of the issue.
 @param inLabelsOrNil  Either an NSString object or NSArray object containing one or more NSString objects, each of which are a distinct label to be applied to this event. A label is any arbitrary string that you want to be ascociated with this event, and will create a second dimension in Quantcast Measurement reporting. Nominally, this is a "user class" indicator. For example, you might use one of two labels in your app: one for user who ave not purchased an app upgrade, and one for users who have purchased an upgrade.
 */
-(void)logOpenIssueWithPeriodicalNamed:(NSString*)inPeriodicalName issueNamed:(NSString*)inIssueName issuePublicationDate:(NSDate*)inPublicationDate withLabels:(id<NSObject>)inLabelsOrNil;

/*!
 @method logCloseIssueWithPeriodicalNamed:issueNamed:issuePublicationDate:withLabels:
 @abstract Call this method to log when the user has caused a particular issue to be closed and the user returns to an issue list. Required for proper periodical measurement.
 @discussion Call this method to log when the user has caused a particular issue to be closed for and the user returns to an issue list. This method is not intended to be called when the app has simply gone out of view altogether, the pauseSessionWithLabels: method is used for that. IF an issue list and the issue itself are simultaneously viewable, such as with a split screen view controller, call this method when the user has select an issue to be viewed other than the currently visible issue.
 @param inPeriodicalName A human-readable name for the periodical being reported on. This, combined with the inIssueName will uniquely identify an issue.
 @param inIssueName A human-readable name for this issue. If the chief identifier for an issue is the month in which it was published, your should name the issue something like "August 2013".
 @param inPublicationDate The publication date of the issue.
 @param inLabelsOrNil  Either an NSString object or NSArray object containing one or more NSString objects, each of which are a distinct label to be applied to this event. A label is any arbitrary string that you want to be ascociated with this event, and will create a second dimension in Quantcast Measurement reporting. Nominally, this is a "user class" indicator. For example, you might use one of two labels in your app: one for user who ave not purchased an app upgrade, and one for users who have purchased an upgrade.
 */
-(void)logCloseIssueWithPeriodicalNamed:(NSString*)inPeriodicalName issueNamed:(NSString*)inIssueName issuePublicationDate:(NSDate*)inPublicationDate withLabels:(id<NSObject>)inLabelsOrNil;

/*!
 @method logPeriodicalPageView:withPeriodicalNamed:issueNamed:issuePublicationDate:withLabels:
 @abstract Call this method to log when a particular page of a particular issue has come into view. Required for proper periodical measurement.
 @discussion This method logs each time a "page view" occurs. Call this method each time a page comes into view for the user. This method should not be called if the content of a page has been loaded into an offscreen view. The intent here is to log what the user sees. 
 @param inPeriodicalName A human-readable name for the periodical being reported on. This, combined with the inIssueName will uniquely identify an issue.
 @param inIssueName A human-readable name for this issue. If the chief identifier for an issue is the month in which it was published, your should name the issue something like "August 2013".
 @param inPublicationDate The publication date of the issue.
 @param inPageNumber The page number of the page that has been brought into view. This should be a unsigned integer value. The value passed here will be used as the page identifier for page-specific engagement reporting. Pages will be sorted in numerical order.
 @param inLabelsOrNil  Either an NSString object or NSArray object containing one or more NSString objects, each of which are a distinct label to be applied to this event. A label is any arbitrary string that you want to be ascociated with this event, and will create a second dimension in Quantcast Measurement reporting. Nominally, this is a "user class" indicator. For example, you might use one of two labels in your app: one for user who ave not purchased an app upgrade, and one for users who have purchased an upgrade.
 */
-(void)logPeriodicalPageView:(NSUInteger)inPageNumber withPeriodicalNamed:(NSString*)inPeriodicalName issueNamed:(NSString*)inIssueName issuePublicationDate:(NSDate*)inPublicationDate withLabels:(id<NSObject>)inLabelsOrNil;

/*!
 @method logPeriodicalArticleView:withPeriodicalNamed:issueNamed:issuePublicationDate:articleAuthors:withLabels:
 @abstract Call this method to log when a particular article of a particular issue has come into view.
 @discussion This method is similar to  logPeriodicalPageViewWithIssueNamed:issuePublicationDate:pageNumber:withLabels:, except that it lets you to  log information about an article that has come into view. Call This fuction when the start of a particular article has come into view after not being in view. That is, if an article spans three pages, call this method when it's first page comes into view. This method should be called in addition to logPeriodicalPageViewWithIssueNamed:issuePublicationDate:pageNumber:withLabels:, not instead of.
 @param inPeriodicalName A human-readable name for the periodical being reported on. This, combined with the inIssueName will uniquely identify an issue.
 @param inIssueName A human-readable name for this issue. If the chief identifier for an issue is the month in which it was published, your should name the issue something like "August 2013".
 @param inPublicationDate The publication date of the issue.
 @param inArticleName A human-reable string that uniquely identifies this an article within the scope of the identified issue. This text will be used to identify the article in reports.
 @param inAuthorListOrNil An NSArray of one or more human readable NSString objects indicating the authors of the article. This allow reporting of engagement against an authgor's articles across all issues. If more than one author is reported, credit will given to each author identically.  
 @param inLabelsOrNil  Either an NSString object or NSArray object containing one or more NSString objects, each of which are a distinct label to be applied to this event. A label is any arbitrary string that you want to be ascociated with this event, and will create a second dimension in Quantcast Measurement reporting. Nominally, this is a "user class" indicator. For example, you might use one of two labels in your app: one for user who ave not purchased an app upgrade, and one for users who have purchased an upgrade.
 */
-(void)logPeriodicalArticleView:(NSString*)inArticleName withPeriodicalNamed:(NSString*)inPeriodicalName issueNamed:(NSString*)inIssueName issuePublicationDate:(NSDate*)inPublicationDate articleAuthors:(NSArray*)inAuthorListOrNil withLabels:(id<NSObject>)inLabelsOrNil;


/*!
 @method logAssetDownloadCompletedWithPeriodicalNamed:issueNamed:issuePublicationDate:withLabels:
 @abstract Call this method to log the successful download of contect for  particular issue. (Optional)
 @param inPeriodicalName A human-readable name for the periodical being reported on. This, combined with the inIssueName will uniquely identify an issue.
 @param inIssueName A human-readable name for this issue. If the chief identifier for an issue is the month in which it was published, your should name the issue something like "August 2013".
 @param inPublicationDate The publication date of the issue.
 @param inLabelsOrNil  Either an NSString object or NSArray object containing one or more NSString objects, each of which are a distinct label to be applied to this event. A label is any arbitrary string that you want to be ascociated with this event, and will create a second dimension in Quantcast Measurement reporting. Nominally, this is a "user class" indicator. For example, you might use one of two labels in your app: one for user who ave not purchased an app upgrade, and one for users who have purchased an upgrade.
 */
-(void)logAssetDownloadCompletedWithPeriodicalNamed:(NSString*)inPeriodicalName issueNamed:(NSString*)inIssueName issuePublicationDate:(NSDate*)inPublicationDate withLabels:(id<NSObject>)inLabelsOrNil;


#pragma mark - Network & Platform Integrations

/*
 * These methods are intended to be used in conjunction with a network or platform SDK integration which has already set up Quantcast Measure using the Network category (QuantcastMeasurement+Network.h).
 * Please see the Network category documentation for more information on how and when to use a Network integration.
 *
 */

-(void)logOpenIssueWithPeriodicalNamed:(NSString*)inPeriodicalName issueNamed:(NSString*)inIssueName issuePublicationDate:(NSDate*)inPublicationDate withAppLabels:(id<NSObject>)inAppLabelsOrNil networkLabels:(id<NSObject>)inNetworkLabelsOrNil;

-(void)logCloseIssueWithPeriodicalNamed:(NSString*)inPeriodicalName issueNamed:(NSString*)inIssueName issuePublicationDate:(NSDate*)inPublicationDate withAppLabels:(id<NSObject>)inAppLabelsOrNil networkLabels:(id<NSObject>)inNetworkLabelsOrNil;

-(void)logPeriodicalPageView:(NSUInteger)inPageNumber withPeriodicalNamed:(NSString*)inPeriodicalName issueNamed:(NSString*)inIssueName issuePublicationDate:(NSDate*)inPublicationDate withAppLabels:(id<NSObject>)inAppLabelsOrNil networkLabels:(id<NSObject>)inNetworkLabelsOrNil;

-(void)logPeriodicalArticleView:(NSString*)inArticleName withPeriodicalNamed:(NSString*)inPeriodicalName issueNamed:(NSString*)inIssueName issuePublicationDate:(NSDate*)inPublicationDate articleAuthors:(NSArray*)inAuthorListOrNil withAppLabels:(id<NSObject>)inAppLabelsOrNil networkLabels:(id<NSObject>)inNetworkLabelsOrNil;

-(void)logAssetDownloadCompletedWithPeriodicalNamed:(NSString*)inPeriodicalName issueNamed:(NSString*)inIssueName issuePublicationDate:(NSDate*)inPublicationDate withAppLabels:(id<NSObject>)inAppLabelsOrNil networkLabels:(id<NSObject>)inNetworkLabelsOrNil;

@end
