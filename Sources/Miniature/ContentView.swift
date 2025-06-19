import SwiftUI
import WordPressUI
import WordPressData
import WordPressShared
import WordPressKit

struct ContentView: View {
    var body: some View {
        List {
            NavigationLink("Activity Log Details (Backup)") {
                ActivityLogDetailsView(activity: createMockBackupActivity())
            }
            
            NavigationLink("Activity Log Details (Plugin Update)") {
                ActivityLogDetailsView(activity: createMockPluginActivity())
            }
        }
        .navigationTitle("Miniature")
    }
}

#Preview {
    ContentView()
}

// MARK: - Mock Data Helpers

private func createMockBackupActivity() -> Activity {
    let json = """
    {
        "activity_id": "123456",
        "summary": "Backup and scan complete",
        "content": {
            "text": "9 plugins, 2 themes, 45 uploads, 27 posts, 1 page"
        },
        "name": "rewind__backup_complete_full",
        "type": "backup",
        "gridicon": "cloud",
        "status": "success",
        "is_rewindable": true,
        "rewind_id": "abc123def456",
        "published": "2025-06-18T17:35:00.000+00:00",
        "actor": {
            "name": "Jetpack",
            "type": "Application",
            "wp_com_user_id": "",
            "icon": {
                "url": ""
            },
            "role": ""
        }
    }
    """
    
    let decoder = JSONDecoder()
    return try! decoder.decode(Activity.self, from: json.data(using: .utf8)!)
}

private func createMockPluginActivity() -> Activity {
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
    
    let decoder = JSONDecoder()
    return try! decoder.decode(Activity.self, from: json.data(using: .utf8)!)
}
