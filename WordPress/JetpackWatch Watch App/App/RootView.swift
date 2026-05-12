import SwiftUI

struct RootView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 8) {
                Image(systemName: "mic.circle.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 48)
                    .foregroundStyle(.red)
                Text("Voice Notes")
                    .font(.headline)
                Text("Scaffolding")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .navigationTitle("Jetpack")
        }
    }
}

#Preview {
    RootView()
}
