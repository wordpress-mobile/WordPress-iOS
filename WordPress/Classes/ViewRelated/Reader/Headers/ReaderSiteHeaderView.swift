import SwiftUI
import WordPressUI

class ReaderSiteHeaderView: ReaderBaseHeaderView, ReaderStreamHeader {

    weak var delegate: ReaderStreamHeaderDelegate?

    private lazy var headerViewModel: ReaderSiteHeaderViewModel = {
        ReaderSiteHeaderViewModel(onFollowTap: { [weak self] completion in
            guard let self else {
                return
            }
            self.delegate?.handleFollowActionForHeader(self, completion: completion)
        })
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        let header = ReaderSiteHeader(viewModel: headerViewModel)
        let view = UIView.embedSwiftUIView(header)
        contentView.addSubview(view)
        view.pinEdges()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configureHeader(_ topic: ReaderAbstractTopic) {
        guard let siteTopic = topic as? ReaderSiteTopic else {
            assertionFailure("This header should only be used for site topics.")
            return
        }
        headerViewModel.site = siteTopic
        headerViewModel.title = siteTopic.title
        headerViewModel.siteUrl = URL(string: siteTopic.siteURL)?.host ?? ""
        headerViewModel.siteDetails = siteTopic.siteDescription
        headerViewModel.postCount = siteTopic.postCount.doubleValue.abbreviatedString()
        headerViewModel.followerCount = siteTopic.subscriberCount.doubleValue.abbreviatedString()
        headerViewModel.isFollowingSite = siteTopic.following
    }
}

// MARK: - ReaderSiteHeader

private struct ReaderSiteHeader: View {
    @ObservedObject var viewModel: ReaderSiteHeaderViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let site = viewModel.site {
                ReaderSiteIconView(site: site, size: .large)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.title)
                    .font(Font(WPStyleGuide.fontForTextStyle(.title1, fontWeight: .semibold)))
                Group {
                    if let site = viewModel.site, let url = URL(string: site.siteURL) {
                        Link(viewModel.siteUrl, destination: url)
                    } else {
                        Text(viewModel.siteUrl)
                    }
                }
                .font(.subheadline)
                .foregroundColor(.secondary)
            }
            if !viewModel.siteDetails.isEmpty {
                Text(viewModel.siteDetails)
                    .lineLimit(3)
                    .font(.subheadline)
            }
            if viewModel.site?.isExternal == false {
                countsDisplay
            }
            HStack {
                ReaderFollowButton(isFollowing: viewModel.isFollowingSite,
                                   isEnabled: viewModel.isFollowEnabled,
                                   size: .regular) {
                    viewModel.updateFollowStatus()
                }
                if let site = viewModel.site, site.canManageNotifications {
                    ReaderSubscriptionNotificationSettingsButton(site: site)
                        .padding(.horizontal, 2)
                        .padding(.vertical, 8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 5)
                                .stroke(Color(.separator), lineWidth: 1)
                        )
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(EdgeInsets(top: 8, leading: 0, bottom: 16, trailing: 0))
    }

    private var countsDisplay: some View {
        let countsString = String(format: Constants.countsFormat, viewModel.postCount, viewModel.followerCount)
        let stringItems = countsString.components(separatedBy: " ")

        return stringItems.reduce(Text(""), {
            var text = Text($1)
            if $1 == viewModel.postCount || $1 == viewModel.followerCount {
                text = text.font(.subheadline)
            } else {
                text = text.font(.subheadline).foregroundColor(.secondary)
            }
            return $0 + text + Text(" ")
        })
    }

    struct Constants {
        static let countsFormat = NSLocalizedString("reader.blog.header.values",
                                                    value: "%1$@ posts • %2$@ subscribers",
                                                    comment: "The formatted number of posts and followers for a site. " +
                                                    "'%1$@' is a placeholder for the blog post count. " +
                                                    "'%2$@' is a placeholder for the blog subscriber count. " +
                                                    "Example: `5,000 posts • 10M subscribers`")
    }
}

// MARK: - ReaderSiteHeaderViewModel

private final class ReaderSiteHeaderViewModel: ObservableObject {
    @Published var site: ReaderSiteTopic?
    @Published var title: String
    @Published var siteUrl: String
    @Published var siteDetails: String
    @Published var postCount: String
    @Published var followerCount: String
    @Published var isFollowingSite: Bool
    @Published var isFollowEnabled: Bool

    private let onFollowTap: (_ completion: @escaping () -> Void) -> Void

    init(title: String = "",
         siteUrl: String = "",
         siteDetails: String = "",
         postCount: String = "",
         followerCount: String = "",
         isFollowingSite: Bool = false,
         isFollowEnabled: Bool = true,
         onFollowTap: @escaping (_ completion: @escaping () -> Void) -> Void = { _ in }) {
        self.title = title
        self.siteUrl = siteUrl
        self.siteDetails = siteDetails
        self.postCount = postCount
        self.followerCount = followerCount
        self.isFollowingSite = isFollowingSite
        self.isFollowEnabled = isFollowEnabled
        self.onFollowTap = onFollowTap
    }

    func updateFollowStatus() {
        isFollowEnabled = false
        onFollowTap { [weak self] in
            self?.isFollowEnabled = true
        }
    }
}
