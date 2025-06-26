import SwiftUI
import WordPressUI

@main
struct MiniatureApp: App {
    var body: some Scene {
        WindowGroup {
            NavigationView {
                ContentView()
            }
            .tint(AppColor.primary)
        }
    }
}
