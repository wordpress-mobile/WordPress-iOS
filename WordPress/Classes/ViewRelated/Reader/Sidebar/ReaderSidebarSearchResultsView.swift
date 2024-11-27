import SwiftUI

struct ReaderSidebarSearchResultsView: View {
    let searchText: String

    @FetchRequest(
        sortDescriptors: [SortDescriptor(\.title, order: .forward)],
        predicate: NSPredicate(format: "following = YES")
    )
    private var topics: FetchedResults<ReaderAbstractTopic>

    var body: some View {
        ForEach(filteredTopics(), id: \.objectID) {
            switch $0 {
            case let site as ReaderSiteTopic:
                ReaderSidebarSubscriptionCell(site: site)
            case let list as ReaderListTopic:
                ReaderSidebarListCell(list: list)
            default:
                EmptyView()
            }
        }
    }

    private func filteredTopics() -> [ReaderAbstractTopic] {
        let searchText = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !searchText.isEmpty else {
            return []
        }
        return topics.search(searchText, using: \.title)
    }
}
