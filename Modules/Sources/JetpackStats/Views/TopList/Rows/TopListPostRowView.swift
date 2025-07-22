import SwiftUI
import WordPressShared

struct TopListPostRowView: View {
    let item: TopListData.Post
    let showDetails: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            ZStack {
                // Ensure stable height
                Text(item.title)
                    .lineLimit(2, reservesSpace: true)
                    .opacity(0)
                Text(item.title)
            }
            .font(.callout)
            .foregroundColor(.primary)
            .lineSpacing(-3)
            .lineLimit(2)
            .padding(.trailing, 4)
        }
    }
}
