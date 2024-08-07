import SwiftUI
import DesignSystem

public struct ApplicationTokenListItemView: View {

    let item: ApplicationTokenItem

    public init(item: ApplicationTokenItem) {
        self.item = item
    }

    public var body: some View {
        NavigationLink(destination: {
            ApplicationTokenItemView(token: item)
        }, label: {
            VStack(alignment: .leading) {
                Text(item.name)
                    .font(.headline)
                    .multilineTextAlignment(.leading)
                Text(item.uuid.uuidString)
                    .font(.callout)
                    .lineLimit(1)
            }
        })
    }
}

#Preview {
    NavigationView(content: {
        List {
            ForEach([ApplicationTokenItem].testTokens) { token in
                ApplicationTokenListItemView(item: token)
            }
        }.navigationTitle("Test")
    })
}
