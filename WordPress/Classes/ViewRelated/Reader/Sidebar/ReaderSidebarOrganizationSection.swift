import UIKit
import SwiftUI
import Combine
import WordPressUI

struct ReaderSidebarOrganizationSection: View {
    let viewModel: ReaderSidebarViewModel
    var teams: FetchedResults<ReaderTeamTopic>

    var body: some View {
        ForEach(teams, id: \.self) { list in
            Label {
                Text(list.title)
                    .lineLimit(1)
            } icon: {
                // TODO: update icon
                Image(systemName: "list.star")
                    .foregroundStyle(.secondary)
            }
            .tag(ReaderSidebarItem.organization(TaggedManagedObjectID(list)))
        }
    }
}
