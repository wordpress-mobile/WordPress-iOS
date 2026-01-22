import SwiftUI

public struct AdsTabView: View {

    public init() {}

    public var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text("Ads")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top, 20)

                Text("Coming Soon")
                    .font(.headline)
                    .foregroundColor(.secondary)

                Spacer(minLength: 100)
            }
            .padding()
        }
    }
}

#Preview {
    AdsTabView()
}
