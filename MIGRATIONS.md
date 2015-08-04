# Core Data migrations

This file documents changes in the data model. Please explain any changes to the
data model as well as any custom migrations.

## WordPress 37 (@alexcurylo 2015-08-04)

- Added `Publicize` to store the services capable of being connected to
- `Blog` added a new attribute called `connections` to store the Publicize connections array

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