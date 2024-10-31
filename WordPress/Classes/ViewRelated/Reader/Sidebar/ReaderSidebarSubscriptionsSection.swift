import UIKit
import SwiftUI
import Combine
import WordPressUI

struct ReaderSidebarSubscriptionsSection: View {
    let viewModel: ReaderSidebarViewModel

    @FetchRequest(
        sortDescriptors: [SortDescriptor(\.title, order: .forward)],
        predicate: NSPredicate(format: "following = YES")
    )
    private var subscriptions: FetchedResults<ReaderSiteTopic>

    var body: some View {
        ForEach(subscriptions, id: \.self) { site in
            Label {
                Text(site.title)
            } icon: {
                SiteIconView(viewModel: SiteIconViewModel(readerSiteTopic: site, size: .small))
                    .frame(width: 28, height: 28)
            }
            .lineLimit(1)
            .tag(ReaderSidebarItem.subscription(TaggedManagedObjectID(site)))
            .swipeActions(edge: .trailing) {
                Button(SharedStrings.Reader.unfollow, role: .destructive) {
                    ReaderSubscriptionHelper().unfollow(site)
                }.tint(.red)
            }
        }
        .onDelete(perform: delete)
    }

    func delete(at offsets: IndexSet) {
        let sites = offsets.map { subscriptions[$0] }
        for site in sites {
            ReaderSubscriptionHelper().unfollow(site)
        }
    }
}
