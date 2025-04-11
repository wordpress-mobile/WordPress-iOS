import SwiftUI
import WordPressUI

/// A "Subscriptions" tab content view for on Reader's "Following" screen.
struct ReaderFollowingSubscriptionsView: View {
    let viewModel: ReaderFollowingViewModel

    @FetchRequest(
        sortDescriptors: [SortDescriptor(\.title, order: .forward)],
        predicate: NSPredicate(format: "following = YES")
    )
    private var subscriptions: FetchedResults<ReaderSiteTopic>

    var body: some View {
        ForEach(subscriptions, id: \.objectID, content: makeSubscriptionCell)
            .onDelete(perform: delete)
    }

    private func makeSubscriptionCell(for site: ReaderSiteTopic) -> some View {
        Button {
            viewModel.navigate(to: .topic(site))
        } label: {
            ReaderSubscriptionCell(site: site, onDelete: delete)
        }
        .swipeActions(edge: .leading) {
            if let siteURL = URL(string: site.siteURL) {
                ShareLink(item: siteURL).tint(.blue)
            }
        }
        .swipeActions(edge: .trailing) {
            Button(SharedStrings.Reader.unfollow, role: .destructive) {
                ReaderSubscriptionHelper().unfollow(site)
            }.tint(.red)
        }
    }

    private func getSubscription(at index: Int) -> ReaderSiteTopic {
//        if isShowingSearchResuts {
//            searchResults[index]
//        } else {
            subscriptions[index]
//        }
    }

    private func delete(at offsets: IndexSet) {
        for site in offsets.map(getSubscription) {
            delete(site)
        }
    }

    private func delete(_ site: ReaderSiteTopic) {
        ReaderSubscriptionHelper().unfollow(site)
    }
}
