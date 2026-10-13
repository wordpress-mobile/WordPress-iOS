import SwiftUI
import UIKit
import WordPressData
import WordPressUI

private struct ReaderUserProfileView: View {
    let viewModel: ReaderUserProfileViewModel
    /// Called when the height of the profile changes, e.g. at another width or text size.
    var onHeightChange: () -> Void = {}

    var body: some View {
        // Scrolls only when the profile is taller than the sheet, e.g. at the largest text sizes
        ScrollView {
            VStack(spacing: 30) {
                header
                    .frame(maxWidth: .infinity, alignment: .center)
                if viewModel.siteURL != nil {
                    fields
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 16)
            .onGeometryChange(for: CGFloat.self) { proxy in
                proxy.size.height
            } action: { _ in
                onHeightChange()
            }
        }
        .scrollBounceBehavior(.basedOnSize)
    }

    /// Only the fields the profile has: an author may have no site.
    private var fields: some View {
        VStack(alignment: .leading, spacing: 20) {
            if let siteURL = viewModel.siteURL {
                field(Strings.site) {
                    Link(destination: siteURL) {
                        Text(siteURL.host ?? siteURL.absoluteString)
                            .foregroundColor(AppColor.primary)
                            .lineLimit(2)
                            // Outside a `List`, a link centers a label that wraps
                            .multilineTextAlignment(.leading)
                    }
                }
            }
        }
    }

    private func field(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .textCase(.uppercase)
                .font(.footnote.weight(.medium))
                .accessibilityAddTraits(.isHeader)
            content()
        }
    }

    private var header: some View {
        VStack(spacing: 12) {
            AvatarView(
                style: .single(viewModel.avatarURL),
                diameter: 72,
                placeholderImage: Image("gravatar").resizable()
            )

            VStack(alignment: .leading, spacing: 3) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(viewModel.name)
                        .font(.title3.weight(.semibold))
                        .textSelection(.enabled)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
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

    init(post: ReaderPost) {
        self.avatarURL = post.avatarURLForDisplay()
        self.name = post.authorForDisplay() ?? ""
        self.siteURL = post.blogURL.flatMap(URL.init(string:))
    }

    init(profile: ReaderUserProfile) {
        self.avatarURL = profile.avatarURL
        self.name = profile.displayName
        self.siteURL = profile.siteURL
    }
}

enum ReaderUserProfilePresenter {
    static func present(_ viewModel: ReaderUserProfileViewModel, from presentingViewController: UIViewController) {
        let profileViewController = ReaderUserProfileViewController(
            rootView: ReaderUserProfileView(viewModel: viewModel)
        )
        let navigationController = UINavigationController(rootViewController: profileViewController)
        profileViewController.navigationItem.leftBarButtonItem = UIBarButtonItem(
            systemItem: .close,
            primaryAction: .init { [weak profileViewController] _ in
                profileViewController?.presentingViewController?.dismiss(animated: true)
            }
        )
        // Size the sheet to fit the profile, up to half the screen. A taller profile scrolls,
        // and the sheet can be pulled up to show more of it.
        profileViewController.presentingWidth = presentingViewController.view.bounds.width
        profileViewController.rootView.onHeightChange = { [weak profileViewController] in
            profileViewController?.invalidateDetents()
        }
        navigationController.sheetPresentationController?.detents = [
            .custom(identifier: .readerUserProfileFitted) { [weak profileViewController] context in
                guard let heights = profileViewController?.sheetHeights(in: context) else {
                    return nil
                }
                return min(heights.fitted, heights.half)
            },
            .custom(identifier: .readerUserProfileExpanded) { [weak profileViewController] context in
                guard let heights = profileViewController?.sheetHeights(in: context) else {
                    return nil
                }
                return heights.fitted > heights.half ? heights.fitted : nil
            }
        ]
        presentingViewController.present(navigationController, animated: true)
    }
}

extension UISheetPresentationController.Detent.Identifier {
    fileprivate static let readerUserProfileFitted = Self("reader-user-profile-fitted")
    fileprivate static let readerUserProfileExpanded = Self("reader-user-profile-expanded")
}

private final class ReaderUserProfileViewController: UIHostingController<ReaderUserProfileView> {
    /// The width to measure the profile at until the sheet has laid it out.
    var presentingWidth: CGFloat = 0

    private var topInset: CGFloat = 0

    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()

        // The navigation bar only reaches its final height once it is in the sheet,
        // and iOS 17 does not resolve the detent again when it does.
        guard view.safeAreaInsets.top != topInset else {
            return
        }
        topInset = view.safeAreaInsets.top
        invalidateDetents()
    }

    /// The detents depend on the profile's height and on the navigation bar's, which the sheet
    /// does not know about, so it has to be told when either changes.
    func invalidateDetents() {
        navigationController?.sheetPresentationController?.invalidateDetents()
    }

    func sheetHeights(
        in context: any UISheetPresentationControllerDetentResolutionContext
    ) -> (fitted: CGFloat, half: CGFloat) {
        let barHeight = navigationController?.navigationBar.frame.maxY ?? 0
        let fitted = min(contentHeight + barHeight, context.maximumDetentValue)
        let half =
            UISheetPresentationController.Detent.medium().resolvedValue(in: context)
            ?? context.maximumDetentValue / 2
        return (fitted, half)
    }

    /// Measured each time a detent is resolved, at the width the sheet gives the profile. That can be
    /// narrower than the view that presents it (on iPad), and the profile wraps differently then.
    private var contentHeight: CGFloat {
        guard let view = viewIfLoaded, view.window != nil, view.bounds.width > 0 else {
            return sizeThatFits(in: CGSize(width: presentingWidth, height: .greatestFiniteMagnitude)).height
        }
        // Once the profile is on screen, the size that fits it includes the safe area insets
        let height = sizeThatFits(in: CGSize(width: view.bounds.width, height: .greatestFiniteMagnitude)).height
        return height - view.safeAreaInsets.top - view.safeAreaInsets.bottom
    }
}

private enum Strings {
    static let site = NSLocalizedString("reader.userProfile.site", value: "Site", comment: "Field title")
}
