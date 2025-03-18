import SwiftUI
import WordPressUI

struct ReaderUserProfileView: View {
    let viewModel: ReaderUserProfileViewModel

    var body: some View {
        List {
            header
                .frame(maxWidth: .infinity, alignment: .center)
                .listRowSeparator(.hidden)

            VStack(alignment: .leading, spacing: 4) {
                Text(Strings.site.uppercased())
                    .font(.footnote.weight(.medium))
                if let siteURL = viewModel.siteURL {
                    Link(destination: siteURL) {
                        Text(siteURL.host ?? siteURL.absoluteString)
                            .foregroundColor(AppColor.primary)
                            .lineLimit(2)
                    }
                } else {
                    Text("–")
                        .foregroundStyle(.secondary)
                }
            }
            .listRowSeparator(.hidden)
        }
        .listStyle(.plain)
    }

    private var header: some View {
        VStack(spacing: 12) {
            AvatarView(style: .single(viewModel.avatarURL), diameter: 72, placeholderImage: Image("gravatar").resizable())

            VStack(alignment: .leading, spacing: 3) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(viewModel.name)
                        .font(.title3.weight(.semibold))
                        .textSelection(.enabled)
                        .lineLimit(2)
                }
            }
        }
    }
}

struct ReaderUserProfileViewModel {
    let avatarURL: URL?
    let name: String
    let siteURL: URL?

    init(comment: Comment) {
        self.avatarURL = comment.avatarURLForDisplay()
        self.name = comment.author
        self.siteURL = URL(string: comment.author_url)
    }
}

private enum Strings {
    static let site = NSLocalizedString("reader.userProfile.site", value: "Site", comment: "Field title")
}
