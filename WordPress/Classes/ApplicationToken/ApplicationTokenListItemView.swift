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
            HStack {
                VStack(alignment: .leading) {
                    Text(item.name)
                        .font(.headline)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                        .truncationMode(.middle)
                    Text("\(createdDateText) • \(lastUsedText)")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                if item.isCurrent {
                    Circle()
                        .fill(Color.accentColor)
                        .frame(width: 8, height: 8)
                }
            }
        })
    }

    private var lastUsedText: String {
        guard let lastUsed = item.lastUsed else {
            return Self.unusedText
        }

        return String(format: Self.lastUsedFormat, lastUsed.toShortString())
    }

    private var createdDateText: String {
        return String(format: Self.createdDateFormat, item.createdAt.toShortString())
    }

    private static let unusedText: String = NSLocalizedString("applicationPassword.list.item.unused", value: "Not used yet.", comment: "Last used time of an application password if it's never been used")

    private static let lastUsedFormat: String = NSLocalizedString("applicationPassword.list.item.last-used-format", value: "Last used %@", comment: "String format of last used time of an application password. There is one argument: the last used time relative to now (i.e. 5 days ago).")

    private static let createdDateFormat: String = NSLocalizedString("applicationPassword.list.item.created-date-format", value: "Created %@", comment: "String format of creation date of an application password. There is one argument: the creation date relative to now (i.e. 5 days ago).")
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
