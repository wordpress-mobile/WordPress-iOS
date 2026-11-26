import SwiftUI
import DesignSystem

struct ApplicationTokenListItemView: View {

    let item: ApplicationTokenItem

    @ObservedObject var viewModel: ApplicationTokenListViewModel

    init(item: ApplicationTokenItem, viewModel: ApplicationTokenListViewModel) {
        self.viewModel = viewModel
        self.item = item
    }

    var body: some View {
        NavigationLink(
            destination: {
                ApplicationTokenItemView(token: item, viewModel: viewModel)
            },
            label: {
                HStack {
                    VStack(alignment: .leading) {
                        Text(item.name)
                            .font(.headline)
                            .multilineTextAlignment(.leading)
                            .lineLimit(2)
                            .truncationMode(.middle)
                        Text(verbatim: "\(createdDateText) • \(lastUsedText)")
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
            }
        )
    }

    private var lastUsedText: String {
        guard let lastUsed = item.lastUsed else {
            return Self.unusedText
        }

        return String(format: Self.lastUsedFormat, lastUsed.toShortString())
    }

    private var createdDateText: String {
        String(format: Self.createdDateFormat, item.createdAt.toShortString())
    }

    private static let unusedText: String = NSLocalizedString(
        "applicationPassword.list.item.unused",
        value: "Not used yet.",
        comment: "Last used time of an application password if it's never been used"
    )

    private static let lastUsedFormat: String = NSLocalizedString(
        "applicationPassword.list.item.last-used-format",
        value: "Last used %@",
        comment:
            "String format of last used time of an application password. There is one argument: the last used time relative to now (i.e. 5 days ago)."
    )

    private static let createdDateFormat: String = NSLocalizedString(
        "applicationPassword.list.item.created-date-format",
        value: "Created %@",
        comment:
            "String format of creation date of an application password. There is one argument: the creation date relative to now (i.e. 5 days ago)."
    )
}

#Preview {
    NavigationView {
        ApplicationTokenListView(dataProvider: StaticTokenProvider(tokens: .success(.testTokens)))
    }
}
