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
        ForEach(subscriptions, id: \.self) {
            ReaderSidebarSubscriptionCell(site: $0)
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

struct ReaderSidebarSubscriptionCell: View {
    @ObservedObject var site: ReaderSiteTopic
    @Environment(\.editMode) var editMode

    var body: some View {
        HStack {
            Label {
                Text(site.title)
            } icon: {
                ReaderSiteIconView(site: site, size: .small)
            }
            if editMode?.wrappedValue.isEditing == true {
                Spacer()
                Button {
                    if !site.showInMenu {
                        WPAnalytics.track(.readerAddSiteToFavoritesTapped)
                    }

                    let siteObjectID = TaggedManagedObjectID(site)
                    ContextManager.shared.performAndSave({ managedObjectContext in
                        let site = try managedObjectContext.existingObject(with: siteObjectID)
                        site.showInMenu.toggle()
                    }, completion: nil, on: DispatchQueue.main)
                } label: {
                    Image(systemName: site.showInMenu ? "star.fill" : "star")
                        .foregroundStyle(site.showInMenu ? .pink : .secondary)
                }.buttonStyle(.plain)
            }
        }
        .lineLimit(1)
        .tag(ReaderSidebarItem.subscription(TaggedManagedObjectID(site)))
        .swipeActions(edge: .trailing) {
            Button(SharedStrings.Reader.unfollow, role: .destructive) {
                ReaderSubscriptionHelper().unfollow(site)
            }.tint(.red)
        }
    }
}
