import SwiftUI
import WordPressUI
import WordPressData
import WordPressShared
import WordPressKit
import JetpackStats

struct ContentView: View {
    var body: some View {
        List {
            Section("Intelligence") {
                if #available(iOS 26, *) {
                    NavigationLink("Image Alt Generator") {
                        ImageAltGeneratorTestView()
                    }
                } else {
                    Text("Image Alt Generator (iOS 26+ required)")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Miniature")
    }
}

#Preview {
    ContentView()
}
