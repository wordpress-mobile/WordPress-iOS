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
            ReaderSidebarSubscriptionCell(site: site)
                .contextMenu {
                    Button(SharedStrings.Reader.unsubscribe, systemImage: "minus.circle", role: .destructive) {
                        ReaderSubscriptionHelper().unfollow(site)
                    }
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
                ReaderSiteFavoriteButton(site: site, source: "edit_mode")
                    .labelStyle(.iconOnly)
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

struct ReaderSiteFavoriteButton: View {
    let site: ReaderSiteTopic
    let source: String

    var body: some View {
        Button {
            if !site.showInMenu {
                WPAnalytics.track(.readerAddSiteToFavoritesTapped, properties: ["via": source])
            }
            let siteObjectID = TaggedManagedObjectID(site)
            ContextManager.shared.performAndSave({ managedObjectContext in
                let site = try managedObjectContext.existingObject(with: siteObjectID)
                site.showInMenu.toggle()
            }, completion: nil, on: DispatchQueue.main)
        } label: {
            Label(site.showInMenu ? SharedStrings.Reader.removeFromFavorites : SharedStrings.Reader.addToFavorites, systemImage: site.showInMenu ? "star.fill" : "star")
                .foregroundStyle(site.showInMenu ? .pink : .secondary)
        }.buttonStyle(.plain)
    }
}
