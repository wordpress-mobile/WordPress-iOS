# Core Data migrations

This file documents changes in the data model. Please explain any changes to the
data model as well as any custom migrations.

## WordPress 41 (@alexcurylo / @aerych 2015-10-21

Changes to the data model:

- Added `PublicizeService` entity. Represents third-party services available to Publicize
- Added `PublicizeConnection` entity. Represents a connection between a blog and a third-party Publicize service.
- `Blog` added a new relationship called `connections`. These are the PublicizeConnections for the blog.

## WordPress 40 (@alexcurylo 2015-10-14)

Changes to the data model:

- `Theme` added a new string attribute called `demoUrl` to store a theme's demo site address
- `Theme` added a new string attribute called `price` to store a premium theme's price display string
- `Theme` added a new string attribute called `stylesheet` to store identifier used to construct helper links
- `Theme` added a new number attribute called `order` to store the display order retrieved by

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