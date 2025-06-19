import SwiftUI
import WordPressUI
import WordPressData
import WordPressShared
import WordPressKit

struct ContentView: View {
    var body: some View {
        List {
            NavigationLink("Activity Log Details (Backup)") {
                ActivityLogDetailsView(
                    activity: createMockBackupActivity(),
                    rewindStatus: createMockActiveRewindStatus()
                )
            }
            
            NavigationLink("Activity Log Details (Plugin Update)") {
                ActivityLogDetailsView(
                    activity: createMockPluginActivity(),
                    rewindStatus: createMockInactiveRewindStatus()
                )
            }
        }
        .navigationTitle("Miniature")
    }
}

#Preview {
    NavigationView {
        ContentView()
    }
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
        "published": "2025-06-18T17:35:00+00:00",
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
    decoder.dateDecodingStrategy = .custom { decoder in
        let container = try decoder.singleValueContainer()
        let dateString = try container.decode(String.self)
        if let date = Date.dateWithISO8601WithMillisecondsString(dateString) {
            return date
        }
        throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid date format")
    }
    
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
        "published": "2025-06-18T16:35:00+00:00",
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
    decoder.dateDecodingStrategy = .custom { decoder in
        let container = try decoder.singleValueContainer()
        let dateString = try container.decode(String.self)
        if let date = Date.dateWithISO8601WithMillisecondsString(dateString) {
            return date
        }
        throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid date format")
    }
    
    return try! decoder.decode(Activity.self, from: json.data(using: .utf8)!)
}

private func createMockActiveRewindStatus() -> RewindStatus {
    // Using the internal initializer for mocking
    RewindStatus(state: .active)
}

private func createMockInactiveRewindStatus() -> RewindStatus {
    // Using the internal initializer for mocking
    RewindStatus(state: .inactive)
}
