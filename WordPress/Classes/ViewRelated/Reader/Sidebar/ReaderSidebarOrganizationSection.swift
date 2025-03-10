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
                let imageName = {
                    switch list.slug {
                    case "a8c": "reader-menu-a8c"
                    case "p2": "reader-menu-pin"
                    default: "reader-menu-list"
                    }
                }()
                ScaledImage(imageName, height: 24, relativeTo: .body)
                    .foregroundStyle(.secondary)
            }
            .tag(ReaderSidebarItem.organization(TaggedManagedObjectID(list)))
        }
    }
}
