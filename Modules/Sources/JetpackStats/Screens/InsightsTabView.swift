import SwiftUI

struct InsightsTabView: View {

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text("Insights")
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
    InsightsTabView()
}
