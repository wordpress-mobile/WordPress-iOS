import SwiftUI

@main
struct JetpackWatchApp: App {
    @StateObject private var env = AppEnvironment.live()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(env)
        }
    }
}
