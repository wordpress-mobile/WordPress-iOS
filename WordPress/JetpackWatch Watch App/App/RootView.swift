import SwiftUI

struct RootView: View {
    @EnvironmentObject private var env: AppEnvironment

    var body: some View {
        NavigationStack {
            RecordView(env: env)
                .navigationTitle("Jetpack")
        }
    }
}

#Preview {
    RootView()
        .environmentObject(AppEnvironment.preview())
}
