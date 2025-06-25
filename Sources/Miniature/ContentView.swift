import SwiftUI
import WordPressUI
import WordPressData
import WordPressShared
import WordPressKit
import CoreData

struct ContentView: View {
    @State private var showPostSettings = false

    var body: some View {
        VStack {
            Button("Show Post Settings") {
                showPostSettings = true
            }
            .buttonStyle(.borderedProminent)
        }
        .sheet(isPresented: $showPostSettings) {
            PostSettingsView()
        }
    }
}

#Preview {
    ContentView()
}
