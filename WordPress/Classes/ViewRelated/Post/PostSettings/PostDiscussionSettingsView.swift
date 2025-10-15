import SwiftUI

struct PostDiscussionSettingsView: View {
    @Binding var postSettings: PostSettings

    var body: some View {
        Form {
            // Comments Section
            Section {
                Toggle(Strings.allowCommentsLabel, isOn: $postSettings.allowComments)
                    .accessibilityIdentifier("post_discussion_allow_comments_toggle")
            } footer: {
                Text(commentsFooterText)
            }

            // Pingbacks Section
            Section {
                Toggle(Strings.allowPingsLabel, isOn: $postSettings.allowPings)
                    .accessibilityIdentifier("post_discussion_allow_pings_toggle")
            } footer: {
                Link(destination: Strings.pingbacksLearnMoreURL) {
                    (Text(Strings.learnMorePingbacksText) + Text(" ") + Text(Image(systemName: "link")))
                        .font(.footnote)
                }
                .accessibilityIdentifier("post_discussion_pingbacks_learn_more_button")
            }
        }
        .navigationTitle(Strings.discussionTitle)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var commentsFooterText: String {
        if postSettings.allowComments {
            return Strings.commentsEnabledFooter
        } else {
            return Strings.commentsDisabledFooter
        }
    }
}

private enum Strings {
    static let discussionTitle = NSLocalizedString(
        "postDiscussion.title",
        value: "Discussion",
        comment: "Navigation title for post discussion settings"
    )

    static let allowCommentsLabel = NSLocalizedString(
        "postDiscussion.allowComments.label",
        value: "Allow Comments",
        comment: "Toggle label for allowing comments on post"
    )

    static let allowPingsLabel = NSLocalizedString(
        "postDiscussion.allowPings.label",
        value: "Allow Pingbacks",
        comment: "Toggle label for allowing pings/trackbacks on post"
    )

    static let commentsEnabledFooter = NSLocalizedString(
        "postDiscussion.comments.enabled.footer",
        value: "Visitors can add new comments and replies.",
        comment: "Footer text when comments are enabled"
    )

    static let commentsDisabledFooter = NSLocalizedString(
        "postDiscussion.comments.disabled.footer",
        value: "Visitors cannot add new comments or replies. Existing comments remain visible.",
        comment: "Footer text when comments are disabled"
    )

    static let pingbacksLearnMoreURL = URL(string: "https://wordpress.org/documentation/article/trackbacks-and-pingbacks/")!

    static let learnMorePingbacksText = NSLocalizedString(
        "postDiscussion.pingbacks.learnMore.text",
        value: "Learn more about pingbacks & trackbacks",
        comment: "Link text for learning more about pingbacks and trackbacks"
    )
}
