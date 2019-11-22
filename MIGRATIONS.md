# Core Data migrations

This file documents changes in the data model. Please explain any changes to the
data model as well as any custom migrations.

## WordPress 93

@guarani 2019-10-27

- `AbstractPost` added `autosaveTitle` (`nullable` `String`), `autosaveExcerpt` (`nullable` `String`), `autosaveContent` (`nullable` `String`), and `autosaveModifiedDate` (`nullable` `Date`) properties.

## WordPress 92

@jklausa 2019-08-19

- `AbstractPost`: Addded a  `confirmedChangesHash` (`nullable` `String`)  and  `confirmedChangesTimestamp` (`nullable` `Date`)  properties. 

@leandroalonso 2019-09-27

- `AbstractPost`: Added `autoUploadAttemptsCount` (`Int 16`, default `0`) property.

@shiki 2019-10-04

-`AbstractPost`: Added `statusAfterSync` property (`nullable`, `String`).
- Adds a custom migration for both `Post` and `Page` entities. The migration copies the values of `status` to `statusAfterSync`. This is done via the `WordPress-91-92.xcmappingmodel`.

## WordPress 91

@aerych 2019-10-15
- `WPAccount` added `primaryBlogID` property. 

## WordPress 90

@diegoreymendez 2019-08-28
- `Media` added `autoUploadFailureCount` property.

## WordPress 89

@scoutharris 2019-08-xx
- Added `FileDownloadsStatsRecordValue` entity.

## WordPress 88

@danielebogo 2019-07-24
- `AccountSettings` added `usernameCanBeChanged` property to store a bool value.

@etoledo 2019-07-19

- `Blog`: Added `mobileEditor` and `webEditor` properties

## WordPress 87
@klausa 2019-02-15

- Added following entities:

* `StatsRecordValue`
* `StatsRecord`

* `AllTimeStatsRecordValue` 
* `AnnualAndMostPopularTimeStatsRecordValue` 
* `ClicksStatsRecordValue`
* `CountryStatsRecordValue`
* `FollowersStatsRecordValue`
* `LastPostStatsRecordValue`
* `PublicizeConnectionStatsRecordValue`
* `ReferrerStatsRecordValue`
* `SearchResultsStatsRecordValue`
* `StreakInsightStatsRecordValue`
* `StreakStatsRecordValue`
* `TagsCategoriesStatsRecordValue`
* `TopCommentedPostStatsRecordValue`
* `TopCommentsAuthorStatsRecordValue`
* `TopViewedAuthorStatsRecordValue`
* `TopViewedPostStatsRecordValue`
* `TopViewedVideoStatsRecordValue`
* `VisitsSummaryStatsRecordValue`

## WordPress 86
@aerych 2018-12-08
- Added `Plan`, `PlanGroup`, and `PlanFeature` entities and properties.

## WordPress 85
@danielebogo 2018-11-12
- Added `BlogAuthor` to store the data of a *blog author*.
- `Blog` added `authors` property to store a set of `BlogAuthor`.

## WordPress 84
@jklausa / @pinarol 2018-11-01
- `Blog` added a `hasDomainCredit` property to see whether user can redeem their credit for a free domain.

## WordPress 83
@danielebogo 2018-10-30
- Renamed `RevisionDiffAbstractValue`, `RevisionDiffContentValue`, `RevisionDiffTitleValue` to `DiffAbstractValue`, `DiffContentValue`, `DiffTitleValue`.
- Set `DiffAbstractValue` as abstract entity which was omitted from model 82.
- Replaced relationship property name on `DiffContentValue` and `DiffTitleValue` from *relationship* to *revisionDiff*.
- Set `DiffAbstractValue` as parent entity of `DiffContentValue` which was omitted from model 82.
- Replaced properties name on `DiffAbstractValue` from *operation* to *diffOperation* and *type* to *diffType*.
- Added property *index* on `DiffAbstractValue` to store the right index position within the set.

## WordPress 82
@danielebogo 2018-10-26
- `AbstractPost` added `revisions` property to store the revisions IDs.
- Added `Revision`,  to store the data of a *post* revision, like title, content, date.
- Added `RevisionDiff` to store the data for a *revision diff*, like the amount of additions or deletions and the revision id it refers to.
- Added `RevisionDiffAbstractValue`, `RevisionDiffContentValue`, `RevisionDiffTitleValue`: these will store the type of change and the operation type.

## WordPress 81
@nheagy 2018-09-26
- Replaced `QuickStartCompletedTour` with `QuickStartTourState` with `completed` and `skipped` attributes

## WordPress 80
- @danielebogo 2018-08-31
- `Post` added `isStickyPost` property to mark posts as sticky.

## WordPress 79
- @frosty 2018-08-15
- Re-added `PublicizeService.externalUsersOnly` property from model 77, which was omitted from model 78.

## WordPress 78
- @nheagy 2018-07-25
- Added `QuickStartCompletedTour` for tracking completed Quick Start tours

## WordPress 77
- @aerych 2018-07-27
- `PublicizeService` added `externalUsersOnly` (bool) property. A new field returned by the API.

## WordPress 76

- @frosty 2018-05-16
- `ReaderPost` added `isSavedForLater` property to mark posts as saved to read later.

## WordPress 75

- @astralbodies 2018-05-15
- `Media` corrected `featuredOnPosts` relationship to reference `AbstractPost` instead of `Post`.

- @frosty 2018-04-25
- `AccountSettings` added `tracksOptOut` property, used to store the user's current preference for opting out of analytics tracking.

- @danielebogo 2018-04-23
- `ReaderSiteInfoSubscriptionPost` and `ReaderSiteInfoSubscriptionEmail` added to store site notifications subscription data.
- `ReaderSiteTopic` added `postSubscription` and `emailSubscription` properties as relationships to `ReaderSiteInfoSubscriptionPost` and `ReaderSiteInfoSubscriptionEmail`.

## WordPress 74

- @sergioestevao 2018-04-18
- `AbstractPost` added `featuredImage` a relationship to Media for the media featured in a post  and removed 'post_thumbnail' that used to store a Int with the mediaID information.

## WordPress 73

- @sergioestevao 2018-03-05
- ``Blog` added `quotaSpaceAllowed` and 'quotaSpaceUsed' that stores a Int64, long number with quota information for the site.

## WordPress 72

- @sergioestevao 2018-02-07
- ``Media` added `error` Transformable property that stores a NSError object that resulted from a failed import or upload.

## WordPress 71

- @elibud 2018-02-02
- `BlogSettings` added `jetpackLazyLoadImages` and `jetpackServeImagesFromOurServers` Bool properties.

## WordPress 70

- @koke 2018-01-16
- `BlogSettings` added `gmtOffset` Decimal property, and `timeZoneString` String property. Store the timezone settings.

## WordPress 69
- @ctarda 2017-11-27
- `PostTag` added `tagDescription`  string property and `postCount` integer property. Store an optional description and the number of posts a tag has been used in.

## WordPress 68
- @elibud 2017-12-12
- `BlogSettings` added the following string properties: `dateFormat`, `timeFormat`, `startOfWeek`, the following boolean properties `ampSupported`, `ampEnabled` and an int_32 `postsPerPage` property.

## WordPress 67
- @3vangelos 2017-09-26
- `Media` added `alt` string property. Stores the information for an html alt tag for images.

## WordPress 66
- @elibud 2017-08-17
- `BlogSettings` added the following Jetpack security settings properties:
    `jetpackMonitorEnabled`, `jetpackMonitorEmailNotifications`, `jetpackMonitorPushNotifications`,
    `jetpackBlockMaliciousLoginAttempts`, `jetpackSSOEnabled`, `jetpackSSOMatchAccountsByEmail`,
    `jetpackSSORequireTwoStepAuthentication` boolean, default `NO` and
    `jetpackLoginWhiteListedIPAddresses` string set property.

## WordPress 65
- @elibud 2017-08-02
- `Theme` added `themeUrl` string property.

## WordPress 64
- @elibud 2017-08-02
- `Theme` added `custom` boolean property. Default `NO`.

## WordPress 63
- @koke 2017-07-31
- `Role` added with `slug`, `name`, `blog`.
- `Blog` added `roles` relationship.

## WordPress 62
- @koke 2017-07-21
- `Blog` removed `jetpackAccount`
- `WPAccount` removed `jetpackBlogs`
- @koke 2017-07-19
- `Blog` added `userID` Int64 property. Stores the current user ID.

## WordPress 61
- @kurzee 2017-06-16
- `Media` added `localThumbnailIdentifier` string property. Stores the locally generated thumbnail identifier.

## WordPress 60
- @elibud 2017-05-31
- `BlogSettings` added `iconMediaID` int_32 property. Stores the mediaID of the site's icon.

## WordPress 59
- @kurzee 2017-05-04
- `MenuItem` added `classes` property.
- @elibud 2017-04-26
- `BasePost` added `suggested_slug` property.

## WordPress 58
- @elibud 2017-04-06
- `Blog` added `hasPaidPlan` boolean property. Default `NO`. Not optional.

## WordPress 57
- @kurzee 2017-03-16
- `Media` removed `orientation` property.
- `Media` removed `progress` property.

## WordPress 56
- @jleandroperez 2017-02-22
- `BasePost` removed `mt_text_more` property
- @koke 2017-02-10
- `Account` added `emailVerified` property.
- @elibud 2017-02-02
- `Post` added optional `disabledPublicizeConnections` transformable property.
- `Post` added optional `publicizeMessage` and `publicizeMessageID` string properties.

## WordPress 55
- @aerych 2016-12-21
- `ReaderPost` renamed `preserveForRestoration` to "inUse"
- `ReaderAbstractTopic` renamed `preserveForRestoration` to "inUse"

## WordPress 54
- @aerych 2016-12-08
- `ReaderPost` added `preserveForRestoration` boolean. Indexed. Default `NO`. Not optional.

## WordPress 53
- @jleandroperez 2016-10-27
- `Notification` added `notificationHash` property.
- @jleandroperez 2016-10-19
- `Notification` removed `simperiumKey` property.
- `Notification` removed `ghostData` property.
- `Notification` added `notificationId` property.
- Removed `Meta` entity.

## WordPress 52

- @koke 2016-09-28
- Added `ReaderTeamTopic` entity.

## WordPress 51
- @aerych 2016-08-12
- Added `algorithm` optional string field to `ReaderAbstractTopic`.
- Added `railcar` optional NSData field to `ReaderPost`.
- @aerych 2016-08-05
- Removed `ReaderSite` entity.
- @aerych 2016-07-19
- `ReaderAbstractTopic` added `preserveForRestoration` boolean. Indexed. Default `NO`. Not optional.

## WordPress 50

- @aerych 2016-06-24
- `ReaderSiteTopic` added `feedURL` string property
- @jleandroperez 2016-06-20
- `Person` added `creationDate` attribute.
- @jleandroperez 2016-06-21
- `Person` removed `isFollower` property.
- `Person` added `kind` Int16 attribute.
- @aerych 2016-06-09
- Moved `dateModified` property from `BasePost` to `AbstractPost`
- @aerych 2016-05-26
- Added `ReaderSearchSuggestion` entity. Represents a search in the reader.
- @aerych 2016-05-31
- Added `dateModified` property to `BasePost` model.
- @aerych 2016-05-23
- `ReaderPost` added `score`.
- `ReaderPost` added `sortRank`. It is not optional so the default of 0 is enforced.

## WordPress 49

- @frosty 2016-05-17
- Added `Domain` entity. Represents a domain belonging to a site.
- `Blog` added new relationship `domains`. An unordered set of `Domain`s for the blog.
- @jleandroperez 2016-05-13
- `Person` updated `siteID` to Int64.
- `Person` updated `userID` to Int64.
- `Person` added Boolean `isFollower`.
- @frosty 2016-05-12
- `Blog` added String `planTitle`.
- @aerych 2016-05-12
- Added `ReaderSearchTopic` entity. Represents a search in the reader.
- @jleandroperez 2016-05-04
 - `Person` added Int64 `linkedUserID`.
- @jleandroperez 2016-04-22
 - `Blog` added transformable `capabilities`.

## WordPress 48

- @sergioestevao 2016-04-05
 - `Media` added new integer attribute `postID` to store the post to where the media is attached to.
- @kurzee 2016-04-08
 - `Menu` changing `menuId` attribute to `menuID` as a int_32 number instead of string.
 - `MenuItem` changing `itemId` attribute to `itemID` as an int_32 number instead of string.
 - `MenuItem` changing `contentId` attribute to `contentID` as an int_64 number instead of string.
- @jleandroperez 2016-04-11
 - `AccountSettings` added new string `emailPendingAddress`. Whenever it's not nil, contains the new User's Email Address.
 - `AccountSettings` added new bool `emailPendingChange`. Indicates whether there's a pending Email change, or not.

## WordPress 47 (@kurzee 2016-03-07)

- `Post` added new string attribute `postType` to store the associated string type of a `Post` entity.
- Added `PostType` entity. Represents a post type and its info.
- `Blog` added new relationship `postTypes` to store `PostType` entities for a site.

## WordPress 46 (@aerych 2016-01-29)

- `BlogSettings` added string `sharingButtonStyle`. Stores style to use for sharing buttons.
- `BlogSettings` added string `sharingLabel`. Stores the text to show in the sharing label.
- `BlogSettings` added string `sharingTwitterName`. Stores the username used when sharing to Twitter.
- `BlogSettings` added bool `sharingCommentLikesEnabled`. Whether comments display a like button.
- `BlogSettings` added bool `sharingDisabledLikes`.  Whether posts display a like button.
- `BlogSettings` added bool `sharingDisabledReblogs`. Whether posts display a reblog button.
- `BlogSettings` added integer `languageID`. Stores the Blog's Language ID.
- Added `SharingButton` entity. Represents a buton for sharing content to a third-party service.
- `Blog` added new relationship `sharingButtons`. An unordered set of `ShareButton`s for the blog.

## WordPress 45 (@kurzee 2016-01-15)

- Added `Menu` entity. Encapsulates the data and relationships for customizing a site menu.
- Added `MenuItem` entity. Encapsulates the navigation item data belonging to a Menu.
- Added `MenuLocation` entity. Encapsulates a site/theme location that a Menu can occupy.
- Added `PostTag` entity. Encapsulates a site's tag taxonomy.
- `Blog` added new relationship called `menus`. Persisting associated Menus for a site.
- `Blog` added new relationship called `menuLocations`. Persists associated MenuLocations available for a site.
- `Blog` added new relationship called `tags`. Persisting associated PostTags for a site.
- `Blog` added new integer64 attribute `planID` to store a blog's current plan's product ID.

## WordPress 44 (@aerych 2016-01-11)

- Added `PublicizeService` entity. Represents third-party services available to Publicize
- Added `PublicizeConnection` entity. Represents a connection between a blog and a third-party Publicize service.
- `Blog` added a new relationship called `connections`. These are the PublicizeConnections for the blog.

## WordPress 43 (@aerych 2015-12-07)

- `ReaderPost` added new integer64 called `feedID` to store a post's feed ID if it exists.
- `ReaderPost` added new integer64 called `feedItemID` to store a post's feed item ID if it exists.

## (@koke 2015-11-23)

- Added new entity `AccountSettings`
- `Account` has now a new one-to-one relationship mapping to `AccountSettings`

#### (@alexcurylo 2015-11-26)

- `Theme` added new string attributes `author` and `authorUrl` to store a theme's author information  
- `Theme` added new boolean attribute `purchased` to store a premium theme's purchased status

## WordPress 42 (@jleandroperez 2015-11-06)

Changes to the data model:
- Added new entity: `BlogSettings`, to encapsulate all of the Blog Settings
- `Blog` has now a new one-to-one relationship mapping to  `BlogSettings`
- Migrated the attribute `Blog.blogName` over to `BlogSettings.name`
- Migrated the attribute `Blog.blogTagline` over to `BlogSettings.tagline`
- Migrated the attribute `Blog.defaultCategoryID` over to `BlogSettings.defaultCategoryID`
- Migrated the attribute `Blog.defaultPostFormat` over to `BlogSettings.defaultPostFormat`
- Migrated the attribute `Blog.geolocationEnabled` over to `BlogSettings.geolocationEnabled`
- Migrated the attribute `Blog.privacy` over to `BlogSettings.privacy`
- Migrated the attribute `Blog.relatedPostsAllowed` over to `BlogSettings.relatedPostsAllowed`
- Migrated the attribute `Blog.relatedPostsEnabled` over to `BlogSettings.relatedPostsEnabled`
- Migrated the attribute `Blog.relatedPostsShowHeadline` over to `BlogSettings.relatedPostsShowHeadline`
- Migrated the attribute `Blog.relatedPostsShowThumbnails` over to `BlogSettings.relatedPostsShowThumbnails`

## WordPress 41 (@jleandroperez 2015-11-23)

- `Notification.id` field has been updated to Integer 64

## WordPress 40 (@alexcurylo 2015-10-14)

Changes to the data model:

- `Theme` added a new string attribute called `demoUrl` to store a theme's demo site address
- `Theme` added a new string attribute called `price` to store a premium theme's price display string
- `Theme` added a new string attribute called `stylesheet` to store identifier used to construct helper links
- `Theme` added a new number attribute called `order` to store the display order retrieved by
- Added new entity `Person`

## (@aerych 2015-11-09)
- Added new entity `ReaderCrossPostMeta`
- `ReaderPost` added new relationship called `crossPostMeta` to store the source post ID of a cross-post.


## WordPress 39 (@sergioestevao 2015-09-09)

- `Blog` added a new boolean attribute called `relatedPostsAllowed` to store the related setting on the site;
- `Blog` added a new boolean attribute called `relatedPostsEnabled` to store the related setting on the site;
- `Blog` added a new boolean attribute called `relatedPostsShowHeadline` to store the related setting on the site;
- `Blog` added a new boolean attribute called `relatedPostsShowThumbnails` to store the related setting on the site;

## WordPress 38 (@sergioestevao 2015-08-21)

Changes to the data model:

- `Blog` added a new number attribute called `privacy` to store the privacy setting on the site
- `ReaderPost` added new string fields for `blavatar`, `primaryTag`, and `primaryTagSlug`
- `ReaderPost` added new integer fields for `wordCount`, and `readingTime`
- `ReaderPost` added new boolean fields for `isExternal`, and `isJetpack`
- `ReaderPost` removed fields `dateCommentsSynced`, and `storedComment`
- Added new entities: `ReaderAbstractTopic`, `ReaderTagTopic`, `ReaderListTopic`, `ReaderDefaultTopic`, `ReaderSiteTopic`, `ReaderGapMarker`.
- Edited obsolete mapping model: `SafeReaderTopicToReaderTopic`
- Removes obsolete `ReaderTopic` model

## WordPress 37 (@sergioestevao 2015-08-01)

Changes to the data model:

- `Blog` added a new number attribute called `defaultCategoryID` to store the default category id for new posts on the site
- `Blog` added a new string attribute called `defaultPostFormat` to store the default post format for new posts on the site

## WordPress 36 (@sergioestevao 2015-07-08)

Changes to the data model:

- `Blog` added a new attribute called `blogTagline` to store the tagline of a site
- `Abstract Post` se the default value for `metaPublishImmediately` attribute to yes
- `BasePost` set the default value for the `status` attribute to "publish"
- `Account` added a `displayName` attribute (@koke)

## WordPress 35 (@sergioestevao 2015-07-08)

Changes to the data model:

- `Media` added a new attribute called localThumbnailURL to store the url of a thumbnail on the server, specially relevant for videos

## WordPress 34 (@sergioestevao 2015-06-20)

- `Media` added a new attribute called remoteThumbnailURL to store the url of a thumbnail on the server, specially relevant for videos

## WordPress 33 (@koke 2015-06-12)

Changes to the data model:

- `Account` loses the `isWpcom` attribute. Only WordPress.com accounts are stored in Core Data now
- `Blog.account` is now optional
- `Account` loses the `xmlrpc` attribute, as they will all be the same WordPress.com XML-RPC endpoint.
- Self hosted username is stored in `Blog.username` now, and it's no longer transient.
- Removed `isJetpack` attribute
- Added `isHostedAtWPcom` attribute

Migration details:

- Only `Account` objects where `isWpcom == YES` will be migrated, added a predicate filter to the mapping model
- `Blog` has a custom migration policy to calculate `isHostedAtWPcom` and `username`
