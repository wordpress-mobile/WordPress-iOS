import SwiftUI

struct RootView: View {
    @EnvironmentObject private var env: AppEnvironment

    var body: some View {
        NavigationStack {
            List {
                Section("Wiring check") {
                    LabeledContent("Sites", value: "\(env.siteCatalog.sites.count)")
                    LabeledContent("Default", value: env.siteCatalog.defaultSite?.name ?? "—")
                    LabeledContent("Notes", value: "\(env.noteStore.notes.count)")
                }
            }
            .navigationTitle("Jetpack")
        }
    }
}

#Preview {
    RootView()
        .environmentObject(AppEnvironment.preview())
}
