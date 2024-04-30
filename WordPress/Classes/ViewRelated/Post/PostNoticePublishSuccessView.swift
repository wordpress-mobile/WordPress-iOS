import Foundation
import SwiftUI
import DesignSystem

struct PostNoticePublishSuccessView: View {
    let post: Post
    let context: Context
    let onDoneTapped: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 33) {
            Spacer()

            HStack(alignment: .center, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(Strings.title)
                        .font(.subheadline)

                    Text(post.titleForDisplay())
                        .font(.title3.weight(.semibold))
                        .lineLimit(2)

                    Button(action: buttonViewTapped) {
                        HStack {
                            let domain = post.blog.primaryDomainAddress
                            if !domain.isEmpty {
                                Text(String(format: Strings.viewOn, domain))
                            } else {
                                Text(Strings.view)
                            }
                            Image("icon-post-actionbar-view")
                        }
                        .font(.subheadline)
                        .lineLimit(1)
                    }
                    .tint(.secondary)
                }

                Spacer()

                Image("post-published")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 90)
            }

            VStack(alignment: .leading, spacing: 16) {
                Text(Strings.trafficSectionTitle)
                HStack {
                    Button(action: buttonShareTapped) {
                        Label(Strings.share, systemImage: "square.and.arrow.up")
                    }
                    if BlazeHelper.isBlazeFlagEnabled() && post.canBlaze {
                        Button(action: buttonBlazeTapped) {
                            Label(Strings.promoteWithBlaze, image: "icon-blaze")
                        }
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.primary)
            }

            Spacer()

            DSButton(title: Strings.done, style: .init(emphasis: .secondary, size: .large), action: onDoneTapped)
        }
        .dynamicTypeSize(.medium ... .accessibility3)
        .padding()
        .onAppear {
            WPAnalytics.track(.postEpilogueDisplayed)
        }
    }

    private func buttonViewTapped() {
        guard let presenter = context.viewController else {
            return wpAssertionFailure("presenter missing")
        }
        WPAnalytics.track(.postEpilogueView)
        let controller = PreviewWebKitViewController(post: post, source: "edit_post_preview")
        controller.trackOpenEvent()
        let navWrapper = LightNavigationController(rootViewController: controller)
        presenter.present(navWrapper, animated: true)
    }

    private func buttonShareTapped() {
        guard let presenter = context.viewController else {
            return wpAssertionFailure("presenter missing")
        }
        WPAnalytics.track(.postEpilogueShare)
        let shareController = PostSharingController()
        shareController.sharePost(post, fromView: presenter.view, inViewController: presenter)
    }

    private func buttonBlazeTapped() {
        guard let presenter = context.viewController else {
            return wpAssertionFailure("presenter missing")
        }
        BlazeEventsTracker.trackEntryPointTapped(for: .publishSuccessView)
        BlazeFlowCoordinator.presentBlaze(in: presenter, source: .publishSuccessView, blog: post.blog, post: post)
    }

    final class Context {
        weak var viewController: UIViewController?
    }
}

private enum Strings {
    static let title = NSLocalizedString("publishSuccessView.title", value: "Post published!", comment: "Post publish success view: title")
    static let trafficSectionTitle = NSLocalizedString("publishSuccessView.trafficSectionTitle", value: "Get more traffic:", comment: "Post publish success view: section 'Get more traffic:' title")
    static let share = NSLocalizedString("publishSuccessView.share", value: "Share", comment: "Post publish success view: button 'Share'")
    static let view = NSLocalizedString("publishSuccessView.view", value: "View", comment: "Post publish success view: button 'View'")
    static let viewOn = NSLocalizedString("publishSuccessView.viewOn", value: "View on %@", comment: "Post publish success view: button 'View on <name-of-domain>'")
    static let promoteWithBlaze = NSLocalizedString("publishSuccessView.promoteWithBlaze", value: "Promote with Blaze", comment: "Post publish success view: button 'Promote with Blaze'")
    static let done = NSLocalizedString("publishSuccessView.done", value: "Done", comment: "Post publish success view: button 'Done'")
}
