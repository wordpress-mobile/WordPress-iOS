import Foundation
import SwiftUI
import WordPressUI

// MARK: - ReaderHeader

extension ReaderStreamViewController {
    // Convenience type for Reader's headers
    typealias ReaderHeader = UIView & ReaderStreamHeader

    func headerForStream(_ topic: ReaderAbstractTopic?, container: UITableViewController) -> UIView? {
        if let topic, ReaderHelpers.topicIsFollowing(topic) {
            return ReaderHeaderView.makeForFollowing()
        }
        if let topic,
           let header = headerForStream(topic) {
            configure(header, topic: topic, delegate: self)
            return header
        }
        return nil
    }

    func configure(_ header: ReaderHeader?, topic: ReaderAbstractTopic, delegate: ReaderStreamHeaderDelegate) {
        header?.configureHeader(topic)
        header?.delegate = delegate
    }

    func headerForStream(_ topic: ReaderAbstractTopic) -> ReaderHeader? {
        if ReaderHelpers.isTopicTag(topic) {
            return ReaderTagStreamHeader()
        }
        if ReaderHelpers.isTopicList(topic) {
            return ReaderListStreamHeader()
        }
        if ReaderHelpers.isTopicSite(topic) {
            return ReaderSiteHeaderView()
        }
        return nil
    }
}

// MARK: - EmptyStateView (ReaderAbstractTopic)

extension ReaderStreamViewController {
    func makeEmptyStateView(for topic: ReaderAbstractTopic) -> UIView {
        let response = ReaderStreamViewController.responseForNoResults(topic)
        return UIHostingView(view: EmptyStateView(
            response.title,
            image: "wp-illustration-reader-empty",
            description: response.message
        ))
    }

    private struct NoResultsResponse {
        var title: String
        var message: String
    }

    private class func responseForNoResults(_ topic: ReaderAbstractTopic) -> NoResultsResponse {
        if ReaderHelpers.topicIsFollowing(topic) {
            return NoResultsResponse(
                title: NSLocalizedString("Welcome to the Reader", comment: "A message title"),
                message: NSLocalizedString(
                    "reader.no.results.response.message",
                    value: "Recent posts from blogs and sites you subscribe to will appear here.",
                    comment: "A message explaining the Following topic in the reader"
                )
            )
        }
        if ReaderHelpers.topicIsLiked(topic) {
            return NoResultsResponse(
                title: NSLocalizedString("Nothing liked yet", comment: "A message title"),
                message: NSLocalizedString("Posts that you like will appear here.", comment: "A message explaining the Posts I Like feature in the reader")
            )
        }
        if ReaderHelpers.isTopicTag(topic) {
            return NoResultsResponse(
                title: NSLocalizedString("No recent posts", comment: "A message title"),
                message: NSLocalizedString("No posts have been made recently with this tag.", comment: "Message shown whent the reader finds no posts for the chosen tag")
            )
        }
        if ReaderHelpers.isTopicSite(topic) {
            return NoResultsResponse(
                title: NSLocalizedString("No posts", comment: "A message title"),
                message: NSLocalizedString(
                    "reader.no.results.blog.response.message",
                    value: "This blog has not posted anything yet. Try back later.",
                    comment: "Message shown when the reader finds no posts for the chosen blog"
                )
            )
        }
        if ReaderHelpers.isTopicList(topic) {
            return NoResultsResponse(
                title: NSLocalizedString("No recent posts", comment: "A message title"),
                message: NSLocalizedString(
                    "reader.no.results.list.response.message",
                    value: "The blogs in this list have not posted anything recently.",
                    comment: "Message shown when the reader finds no posts for the chosen list"
                )
            )
        }
        if ReaderHelpers.isTopicSearchTopic(topic) {
            let message = NSLocalizedString("No posts found matching %@ in your language.", comment: "Message shown when the reader finds no posts for the specified search phrase. The %@ is a placeholder for the search phrase.")
            return NoResultsResponse(
                title: NSLocalizedString("No posts found", comment: "A message title"),
                message: NSString(format: message as NSString, topic.title) as String
            )
        }
        return defaultResponse
    }

    private static let defaultResponse = NoResultsResponse(
        title: NSLocalizedString("No recent posts", comment: "A message title"),
        message: NSLocalizedString("No posts have been made recently", comment: "A default message shown when the reader can find no post to display")
    )
}

// MARK: - EmptyStateView (EmptyStateViewType)

extension ReaderStreamViewController {
    enum EmptyStateViewType {
        case discover
        case noSavedPosts
        case noFollowedSites
        case noConnection
        case steamLoadingFailed
    }

    func makeEmptyStateView(_ type: EmptyStateViewType) -> UIView {
        UIHostingView(view: _makeEmptyStateView(type))
    }

    @ViewBuilder
    private func _makeEmptyStateView(_ type: EmptyStateViewType) -> some View {
        switch type {
        case .steamLoadingFailed:
            EmptyStateView(
                ResultsStatusText.loadingErrorTitle,
                systemImage: "exclamationmark.circle",
                description: ResultsStatusText.loadingErrorMessage
            )
        case .noSavedPosts:
            EmptyStateView(label: {
                Label(NSLocalizedString("No saved posts", comment: "Message displayed in Reader Saved Posts view if a user hasn't yet saved any posts."), image: "wp-illustration-reader-empty")
            }, description: {
                // Had to use UIKit because Text(AttributedString()) won't render the attachment
                HostedAttributedLabel(text: self.makeSavedPostsEmptyViewDescription())
                    .fixedSize()
            }, actions: {
                EmptyView()
            })
        case .discover:
            EmptyStateView(
                ReaderStreamViewController.defaultResponse.title,
                image: "wp-illustration-reader-empty",
                description: ReaderStreamViewController.defaultResponse.message
            )
        case .noConnection:
            EmptyStateView(
                ResultsStatusText.noConnectionTitle,
                systemImage: "network.slash",
                description: noConnectionMessage()
            )
        case .noFollowedSites:
            EmptyStateView(label: {
                Label(Strings.noFollowedSitesTitle, systemImage: "checkmark.circle")
            }, description: {
                Text(Strings.noFollowedSitesSubtitle)
            }, actions: {
                Button(Strings.noFollowedSitesButtonTitle) {
                    RootViewCoordinator.sharedPresenter.showReader(path: .discover)
                }
                .buttonStyle(.primary)
            })
        }
    }

    private func makeSavedPostsEmptyViewDescription() -> NSAttributedString {
        let details = NSLocalizedString("Tap [bookmark-outline] to save a post to your list.", comment: "A hint displayed in the Saved Posts section of the Reader. The '[bookmark-outline]' placeholder will be replaced by an icon at runtime – please leave that string intact.")
        let string = NSMutableAttributedString(string: details, attributes: [
            .font: UIFont.preferredFont(forTextStyle: .subheadline)
        ])
        let icon = UIImage.gridicon(.bookmarkOutline, size: CGSize(width: 18, height: 18))
        string.replace("[bookmark-outline]", with: icon)
        string.addAttribute(.foregroundColor, value: UIColor.secondaryLabel, range: NSRange(location: 0, length: string.length))
        return string
    }
}

private struct HostedAttributedLabel: UIViewRepresentable {
    let text: NSAttributedString

    func makeUIView(context: Context) -> UILabel {
        let label = UILabel()
        label.attributedText = text
        return label
    }

    func updateUIView(_ uiView: UILabel, context: Context) {
        // Do nothing
    }
}

// MARK: - Tracks
extension ReaderStreamViewController {
    func trackSavedListAccessed() {
        WPAnalytics.trackReader(.readerSavedListShown, properties: ["source": ReaderSaveForLaterOrigin.readerMenu.viewAllPostsValue])
    }
}

private struct Strings {
    static let noFollowedSitesTitle = NSLocalizedString(
        "reader.no.blogs.title",
        value: "No blog subscriptions",
        comment: "Title for the no followed blogs result screen"
    )
    static let noFollowedSitesSubtitle = NSLocalizedString(
        "reader.no.blogs.subtitle",
        value: "Subscribe to blogs in Discover and you’ll see their latest posts here. Or search for a blog that you like already.",
        comment: "Subtitle for the no followed blogs result screen"
    )
    static let noFollowedSitesButtonTitle = NSLocalizedString(
        "reader.no.blogs.button",
        value: "Discover Blogs",
        comment: "Title for button on the no followed blogs result screen"
    )
}
