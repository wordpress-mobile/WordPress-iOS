import SwiftUI

struct PostDiscussionSettingsView: View {
    @Binding var postSettings: PostSettings

    var body: some View {
        Form {
            Section {
                Toggle(Strings.allowCommentsLabel, isOn: $postSettings.allowComments)
                    .accessibilityIdentifier("post_discussion_allow_comments_toggle")

                Toggle(Strings.allowPingsLabel, isOn: $postSettings.allowPings)
                    .accessibilityIdentifier("post_discussion_allow_pings_toggle")
            } header: {
                Text(Strings.discussionHeader)
            } footer: {
                Text(Strings.discussionFooter)
            }
        }
        .navigationTitle(Strings.discussionTitle)
        .navigationBarTitleDisplayMode(.inline)
    }
}

private enum Strings {
    static let discussionTitle = NSLocalizedString(
        "postDiscussion.title",
        value: "Discussion Settings",
        comment: "Navigation title for post discussion settings"
    )

    static let discussionHeader = NSLocalizedString(
        "postDiscussion.header",
        value: "Discussion Settings",
        comment: "Section header for discussion settings"
    )

    static let allowCommentsLabel = NSLocalizedString(
        "postDiscussion.allowComments.label",
        value: "Allow Comments",
        comment: "Toggle label for allowing comments on post"
    )

    static let allowPingsLabel = NSLocalizedString(
        "postDiscussion.allowPings.label",
        value: "Allow Pings",
        comment: "Toggle label for allowing pings/trackbacks on post"
    )

    static let discussionFooter = NSLocalizedString(
        "postDiscussion.footer",
        value: "Allow readers to comment on this post and to send trackbacks and pingbacks from their own sites.",
        comment: "Footer text explaining discussion settings"
    )
}
