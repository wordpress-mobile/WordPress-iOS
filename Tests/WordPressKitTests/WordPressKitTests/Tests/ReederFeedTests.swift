import Foundation
import Testing

@testable import WordPressKit

struct ReaderFeedTests {

    @Test func decodesReaderFeedEnvelopeWithSiteFallbacks() throws {
        // GIVEN: JSON response where URL and title are not embedded at root level
        let jsonData = try #require(readerFeedJSON.data(using: .utf8))

        // WHEN: Decoding the envelope
        let decoder = JSONDecoder()
        let envelope = try decoder.decode(ReaderFeedEnvelope.self, from: jsonData)

        // THEN: Envelope contains feeds array
        #expect(envelope.feeds.count == 1)

        let feed = try #require(envelope.feeds.first)

        // THEN: Feed ID is decoded from root level
        #expect(feed.feedID == "188407")

        // THEN: URL falls back to data.site.URL since not present at root
        #expect(feed.url?.absoluteString == "https://ma.tt")

        // THEN: Title falls back to data.site.name since not present at root
        #expect(feed.title == "Matt Mullenweg")

        // THEN: Description is decoded from data.site.description
        #expect(feed.feedDescription == "Unlucky in Cards")

        // THEN: Blavatar URL is decoded from data.site.icon.img
        #expect(feed.blavatarURL?.absoluteString == "https://ma.tt/files/2024/01/cropped-matt-favicon.png")
    }
}

// MARK: - Test Data

private let readerFeedJSON = """
{
  "feeds": [
    {
      "subscribe_URL": "https://ma.tt/feed/",
      "feed_ID": "188407",
      "meta": {
        "links": {
          "feed": "https://public-api.wordpress.com/rest/v1.1/read/feed/188407",
          "site": "https://public-api.wordpress.com/rest/v1.1/read/sites/1047865"
        },
        "data": {
          "site": {
            "ID": 1047865,
            "name": "Matt Mullenweg",
            "description": "Unlucky in Cards",
            "URL": "https://ma.tt",
            "jetpack": true,
            "jetpack_connection": true,
            "post_count": 5599,
            "subscribers_count": 4520,
            "lang": "en-US",
            "icon": {
              "img": "https://ma.tt/files/2024/01/cropped-matt-favicon.png",
              "ico": "https://ma.tt/files/2024/01/cropped-matt-favicon.png?w=16"
            },
            "logo": {
              "id": 0,
              "sizes": [],
              "url": ""
            },
            "visible": true,
            "is_private": false,
            "is_coming_soon": false,
            "is_following": false,
            "organization_id": 0,
            "meta": {
              "links": {
                "self": "https://public-api.wordpress.com/rest/v1.1/read/sites/1047865",
                "help": "https://public-api.wordpress.com/rest/v1.1/read/sites/1047865/help",
                "posts": "https://public-api.wordpress.com/rest/v1.1/read/sites/1047865/posts/",
                "comments": "https://public-api.wordpress.com/rest/v1.1/sites/1047865/comments/",
                "xmlrpc": "https://ma.tt/blog/xmlrpc.php"
              }
            },
            "launch_status": false,
            "site_migration": {
              "is_complete": false,
              "in_progress": false
            },
            "is_fse_active": false,
            "is_fse_eligible": false,
            "is_core_site_editor_enabled": false,
            "is_wpcom_atomic": false,
            "is_wpcom_staging_site": false,
            "is_deleted": false,
            "is_a4a_client": false,
            "is_a4a_dev_site": false,
            "is_wpcom_flex": false,
            "capabilities": {
              "edit_pages": false,
              "edit_posts": false,
              "edit_others_posts": false,
              "edit_theme_options": false,
              "list_users": false,
              "manage_categories": false,
              "manage_options": false,
              "publish_posts": false,
              "upload_files": false,
              "view_stats": false
            },
            "is_multi_author": true,
            "feed_ID": 188407,
            "feed_URL": "http://ma.tt/feed",
            "header_image": false,
            "owner": {
              "ID": 5,
              "login": "matt",
              "name": "Matt",
              "first_name": "Matt",
              "last_name": "Mullenweg",
              "nice_name": "matt",
              "URL": "https://matt.blog/",
              "avatar_URL": "https://0.gravatar.com/avatar/33252cd1f33526af53580fcb1736172f06e6716f32afdd1be19ec3096d15dea5?s=96&d=retro&r=G",
              "profile_URL": "https://gravatar.com/matt",
              "ip_address": false,
              "site_visible": true,
              "has_avatar": true
            },
            "subscription": {
              "delivery_methods": {
                "email": null,
                "notification": {
                  "send_posts": false
                }
              }
            },
            "is_blocked": false,
            "unseen_count": 0
          }
        }
      }
    }
  ]
}
"""
