# Core Data migrations

This file documents changes in the data model. Please explain any changes to the
data model as well as any custom migrations.

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
