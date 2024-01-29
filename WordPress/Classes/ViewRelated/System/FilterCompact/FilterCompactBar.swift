import SwiftUI

struct FilterCompactBar<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                content()
            }
            .padding(.horizontal, 16)
        }
        .listRowSeparator(.hidden, edges: .all)
        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
    }
}
