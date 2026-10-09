import SwiftUI
import UIKit
import WordPressData
import WordPressUI

struct ReaderUserProfileView: View {
    let viewModel: ReaderUserProfileViewModel

    var body: some View {
        // Scrolls only when the profile is taller than the sheet, e.g. with a long bio or at the largest text sizes
        ScrollView {
            VStack(spacing: 30) {
                header
                    .frame(maxWidth: .infinity, alignment: .center)
                VStack(spacing: 20) {
                    site
                        .frame(maxWidth: .infinity, alignment: .leading)
                    if let bio = viewModel.bio {
                        about(bio)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 16)
        }
        .scrollBounceBehavior(.basedOnSize)
    }

    private var site: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(Strings.site.uppercased())
                .font(.footnote.weight(.medium))
            if let siteURL = viewModel.siteURL {
                Link(destination: siteURL) {
                    Text(siteURL.host ?? siteURL.absoluteString)
                        .foregroundColor(AppColor.primary)
                        .lineLimit(2)
                        // Outside a `List`, a link centers a label that wraps
                        .multilineTextAlignment(.leading)
                }
            } else {
                Text(verbatim: "–")
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func about(_ bio: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(Strings.about.uppercased())
                .font(.footnote.weight(.medium))
            Text(bio)
                .textSelection(.enabled)
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
    let bio: String?

    init(comment: Comment) {
        self.avatarURL = comment.avatarURLForDisplay()
        self.name = comment.author
        self.siteURL = URL(string: comment.author_url)
        self.bio = nil
    }

    init(post: ReaderPost) {
        self.avatarURL = post.avatarURLForDisplay()
        self.name = post.authorForDisplay() ?? ""
        self.siteURL = post.blogURL.flatMap(URL.init(string:))
        self.bio = nil
    }

    init(profile: ReaderUserProfile) {
        self.avatarURL = profile.avatarURL
        self.name = profile.displayName
        self.siteURL = profile.siteURL
        self.bio = profile.bio
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
        let fittingSize = CGSize(width: presentingViewController.view.bounds.width, height: .greatestFiniteMagnitude)
        let contentHeight = profileViewController.sizeThatFits(in: fittingSize).height
        navigationController.sheetPresentationController?.detents = [
            .custom(identifier: .readerUserProfileFitted) { [weak navigationController] context in
                let heights = sheetHeights(for: contentHeight, in: navigationController, context: context)
                return min(heights.fitted, heights.half)
            },
            .custom(identifier: .readerUserProfileExpanded) { [weak navigationController] context in
                let heights = sheetHeights(for: contentHeight, in: navigationController, context: context)
                return heights.fitted > heights.half ? heights.fitted : nil
            }
        ]
        presentingViewController.present(navigationController, animated: true)
    }

    private static func sheetHeights(
        for contentHeight: CGFloat,
        in navigationController: UINavigationController?,
        context: any UISheetPresentationControllerDetentResolutionContext
    ) -> (fitted: CGFloat, half: CGFloat) {
        let barHeight = navigationController?.navigationBar.frame.maxY ?? 0
        let fitted = min(contentHeight + barHeight, context.maximumDetentValue)
        let half =
            UISheetPresentationController.Detent.medium().resolvedValue(in: context)
            ?? context.maximumDetentValue / 2
        return (fitted, half)
    }
}

extension UISheetPresentationController.Detent.Identifier {
    fileprivate static let readerUserProfileFitted = Self("reader-user-profile-fitted")
    fileprivate static let readerUserProfileExpanded = Self("reader-user-profile-expanded")
}

private final class ReaderUserProfileViewController: UIHostingController<ReaderUserProfileView> {
    private var topInset: CGFloat = 0

    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()

        // The navigation bar only reaches its final height once it is in the sheet,
        // and iOS 17 does not resolve the detent again when it does.
        guard view.safeAreaInsets.top != topInset else {
            return
        }
        topInset = view.safeAreaInsets.top
        navigationController?.sheetPresentationController?.invalidateDetents()
    }
}

private enum Strings {
    static let site = NSLocalizedString("reader.userProfile.site", value: "Site", comment: "Field title")
    static let about = NSLocalizedString(
        "reader.userProfile.about",
        value: "About",
        comment: "Title of the field that shows a user's bio in the Reader profile sheet"
    )
}
