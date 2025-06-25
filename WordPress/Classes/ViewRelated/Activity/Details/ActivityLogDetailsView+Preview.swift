import Foundation
import WordPressKit

extension ActivityLogDetailsView {
    enum Mocks {
        static var mockBackupActivity: Activity {
            let json = """
            {
                "summary": "Backup and scan complete",
                "content": {
                    "text": "9 plugins, 2 themes, 45 uploads, 27 posts, 1 page"
                },
                "name": "rewind__backup_complete_full",
                "actor": {
                    "type": "Application",
                    "name": "Jetpack"
                },
                "type": "Announce",
                "published": "2025-06-18T21:35:29.909+00:00",
                "generator": {
                    "jetpack_version": 14.8,
                    "blog_id": 123456789
                },
                "is_rewindable": true,
                "rewind_id": "1750282529.909",
                "base_rewind_id": null,
                "rewind_step_count": 0,
                "gridicon": "cloud",
                "status": "success",
                "activity_id": "mock-activity-id-123",
                "is_discarded": false
            }
            """
            return try! JSONDecoder().decode(Activity.self, from: json.data(using: .utf8)!)
        }

        static var mockPluginActivity: Activity {
            let json = """
            {
                "activity_id": "789012",
                "summary": "Plugin updated",
                "content": {
                    "text": "Updated Akismet Anti-spam from version 5.2 to 5.3"
                },
                "name": "plugin__updated",
                "type": "plugin",
                "gridicon": "plugins",
                "status": "success",
                "is_rewindable": false,
                "published": "2025-06-18T16:35:00.000+00:00",
                "actor": {
                    "name": "John Doe",
                    "type": "Person",
                    "wp_com_user_id": "12345",
                    "icon": {
                        "url": "https://gravatar.com/avatar/12345"
                    },
                    "role": "administrator"
                }
            }
            """
            return try! JSONDecoder().decode(Activity.self, from: json.data(using: .utf8)!)
        }

        static var mockLoginActivity: Activity {
            let json = """
            {
                "summary": "Login succeeded",
                "content": {
                    "text": "JohnDoe successfully logged in from IP Address 192.0.2.1",
                    "ranges": [
                        {
                            "url": "https://wordpress.com/people/edit/123456789/johndoe",
                            "indices": [
                                0,
                                7
                            ],
                            "id": 12345678,
                            "parent": null,
                            "type": "a",
                            "site_id": 123456789,
                            "section": "user",
                            "intent": "edit"
                        }
                    ]
                },
                "name": "user__login",
                "actor": {
                    "type": "Person",
                    "name": "JohnDoe",
                    "external_user_id": 12345678,
                    "wpcom_user_id": 12345678,
                    "icon": {
                        "type": "Image",
                        "url": "https://secure.gravatar.com/avatar/1234567890abcdef?s=96&d=identicon&r=g",
                        "width": 96,
                        "height": 96
                    },
                    "role": "administrator"
                },
                "type": "Join",
                "published": "2025-06-19T15:04:20.180+00:00",
                "generator": {
                    "jetpack_version": 14.8,
                    "blog_id": 123456789
                },
                "is_rewindable": false,
                "rewind_id": "1750345459.9332",
                "base_rewind_id": null,
                "rewind_step_count": 0,
                "gridicon": "lock",
                "status": null,
                "activity_id": "mock-login-activity-456",
                "object": {
                    "type": "Person",
                    "name": "JohnDoe",
                    "external_user_id": 12345678,
                    "wpcom_user_id": 12345678
                },
                "is_discarded": false
            }
            """
            return try! JSONDecoder().decode(Activity.self, from: json.data(using: .utf8)!)
        }
    }
}
