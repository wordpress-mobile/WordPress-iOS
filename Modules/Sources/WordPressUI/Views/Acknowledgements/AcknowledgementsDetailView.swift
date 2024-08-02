import SwiftUI

struct AcknowledgementsDetailView: View {
    let item: AcknowledgementItem

    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                Text(item.license)
                    .font(.body)
                    .foregroundStyle(.primary)
                    .padding()
                    .multilineTextAlignment(.leading)
            }.navigationTitle(item.title)
        }
    }
}

#Preview {
    NavigationView {
        AcknowledgementsDetailView(item: .sampleData.first!)
    }
}
