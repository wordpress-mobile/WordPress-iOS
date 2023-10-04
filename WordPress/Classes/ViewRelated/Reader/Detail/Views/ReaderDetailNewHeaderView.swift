import SwiftUI
import WordPressUI
import Gridicons

/// A protocol conformed by both `ReaderDetailHeaderView` and `ReaderDetailNewHeaderViewHost`.
/// This is a temporary solution to abstract and simplify usage in the view controller.
///
/// NOTE: This protocol should be removed once the `readerImprovements` flag is deleted.
///
protocol ReaderDetailHeader: NSObjectProtocol {
    var delegate: ReaderDetailHeaderViewDelegate? { get set }
    var useCompatibilityMode: Bool { get set }

    func configure(for post: ReaderPost)
    func refreshFollowButton()
}

// MARK: - SwiftUI View Host

class ReaderDetailNewHeaderViewHost: UIView {
    weak var delegate: ReaderDetailHeaderViewDelegate? {
        didSet {
            viewModel.headerDelegate = delegate
        }
    }

    // TODO: Find out if we still need this.
    var useCompatibilityMode: Bool = false

    private let isLoggedIn: Bool

    private var postObjectID: TaggedManagedObjectID<ReaderPost>? = nil

    // TODO: Populate this with values from the ReaderPost.
    private lazy var viewModel: ReaderDetailHeaderViewModel = {
        $0.topicDelegate = self
        return $0
    }(ReaderDetailHeaderViewModel())

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init(isLoggedIn: Bool) {
        self.isLoggedIn = isLoggedIn

        super.init(frame: .zero)
        setupView()
    }

    func setupView() {
        translatesAutoresizingMaskIntoConstraints = false

        let headerView = ReaderDetailNewHeaderView(viewModel: viewModel) { [weak self] in
            self?.refreshContainerLayout()
        }

        let view = UIView.embedSwiftUIView(headerView)
        addSubview(view)
        pinSubviewToAllEdges(view)
    }

    func refreshContainerLayout() {
        guard let swiftUIView = subviews.first else {
            return
        }
        swiftUIView.invalidateIntrinsicContentSize()
        layoutIfNeeded()
    }
}

// MARK: ReaderDetailHeader

extension ReaderDetailNewHeaderViewHost: ReaderDetailHeader {
    func configure(for post: ReaderPost) {
        viewModel.configure(with: TaggedManagedObjectID(post),
                            isLoggedIn: isLoggedIn,
                            completion: refreshContainerLayout)
    }

    func refreshFollowButton() {
        viewModel.refreshFollowState()
    }
}

// MARK: ReaderTopicCollectionViewCoordinatorDelegate

extension ReaderDetailNewHeaderViewHost: ReaderTopicCollectionViewCoordinatorDelegate {
    func coordinator(_ coordinator: ReaderTopicCollectionViewCoordinator, didSelectTopic topic: String) {
        delegate?.didSelectTopic(topic)
    }

    func coordinator(_ coordinator: ReaderTopicCollectionViewCoordinator, didChangeState: ReaderTopicCollectionViewState) {
        // no op
    }
}

// MARK: - SwiftUI View Model

class ReaderDetailHeaderViewModel: ObservableObject {
    private let coreDataStack: CoreDataStackSwift
    private var postObjectID: TaggedManagedObjectID<ReaderPost>? = nil

    weak var headerDelegate: ReaderDetailHeaderViewDelegate?
    weak var topicDelegate: ReaderTopicCollectionViewCoordinatorDelegate?

    // Follow/Unfollow states
    @Published var isFollowingSite = false
    @Published var showsFollowButton = false
    @Published var isFollowButtonInteractive = true

    @Published var siteIconURL: URL? = nil
    @Published var authorAvatarURL: URL? = nil
    @Published var authorName = String()
    @Published var relativePostTime = String()
    @Published var siteName = String()
    @Published var postTitle: String? = nil // post title can be empty.
    @Published var tags: [String] = []

    init(coreDataStack: CoreDataStackSwift = ContextManager.shared) {
        self.coreDataStack = coreDataStack
    }

    func configure(with objectID: TaggedManagedObjectID<ReaderPost>,
                   isLoggedIn: Bool,
                   completion: (() -> Void)?) {
        postObjectID = objectID
        coreDataStack.performQuery { [weak self] context -> Void in
            guard let self,
                  let post = try? context.existingObject(with: objectID) else {
                return
            }

            self.showsFollowButton = isLoggedIn
            self.isFollowingSite = post.isFollowing

            self.siteIconURL = post.siteIconForDisplay(ofSize: Int(ReaderDetailNewHeaderView.Constants.siteIconLength))
            self.authorAvatarURL = post.avatarURLForDisplay() ?? nil

            if let authorName = post.authorForDisplay(), !authorName.isEmpty {
                self.authorName = authorName
            }

            if let relativePostTime = post.dateForDisplay()?.toMediumString() {
                self.relativePostTime = relativePostTime
            }

            if let siteName = post.blogNameForDisplay(), !siteName.isEmpty {
                self.siteName = siteName
            }

            self.postTitle = post.titleForDisplay() ?? nil
            self.tags = post.tagsForDisplay() ?? []
        }

        DispatchQueue.main.async {
            completion?()
        }
    }

    func refreshFollowState() {
        guard let postObjectID else {
            return
        }

        isFollowingSite = coreDataStack.performQuery { context in
            guard let post = try? context.existingObject(with: postObjectID) else {
                return false
            }
            return post.isFollowing
        }
    }

    func didTapAuthorSection() {
        headerDelegate?.didTapBlogName()
    }

    func didTapFollowButton() {
        guard let headerDelegate else {
            return
        }

        isFollowButtonInteractive = false
        isFollowingSite.toggle()

        headerDelegate.didTapFollowButton { [weak self] in
            self?.isFollowButtonInteractive = true
        }
    }
}

// MARK: - SwiftUI

/// The updated header version for Reader Details.
///
/// TODO: Rename this to `ReaderDetailHeaderView` once the `readerImprovements` flag is removed.
///
struct ReaderDetailNewHeaderView: View {

    @SwiftUI.Environment(\.layoutDirection) var direction

    @ObservedObject var viewModel: ReaderDetailHeaderViewModel

    /// A callback for the parent to react to collection view size changes.
    var onTagsViewUpdated: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 16.0) {
            headerRow
            if let postTitle = viewModel.postTitle {
                Text(postTitle)
                    .font(.title)
                    .fontWeight(.bold)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true) // prevents the title from being truncated.
            }
            if !viewModel.tags.isEmpty {
                tagsView
            }
        }
        // Added an extra 4.0 to top padding to account for a legacy layout issue with featured image.
        // Bottom padding is 0 as there's already padding between the header container and the webView in the storyboard.
        .padding(EdgeInsets(top: 12.0, leading: 16.0, bottom: 0.0, trailing: 16.0))
    }

    var headerRow: some View {
        HStack(spacing: 8.0) {
            authorStack
            if viewModel.showsFollowButton {
                Spacer()
                followButton(isPhone: WPDeviceIdentification.isiPhone())
            }
        }
    }

    var authorStack: some View {
        HStack(spacing: 8.0) {
            if let siteIconURL = viewModel.siteIconURL,
               let avatarURL = viewModel.authorAvatarURL {
                avatarView(with: siteIconURL, avatarURL: avatarURL)
            }
            VStack(alignment: .leading) {
                Text(viewModel.siteName)
                    .font(.callout)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                authorText
            }
        }
        .onTapGesture {
            viewModel.didTapAuthorSection()
        }
    }

    @ViewBuilder
    func avatarView(with siteIconURL: URL, avatarURL: URL) -> some View {
        ZStack(alignment: .bottomTrailing) {
            AsyncImage(url: siteIconURL) { image in
                image.resizable()
            } placeholder: {
                Image("post-blavatar-default").resizable()
            }
            .frame(width: Constants.siteIconLength, height: Constants.siteIconLength)
            .clipShape(Circle())

            AsyncImage(url: avatarURL) { image in
                image.resizable()
            } placeholder: {
                Image("blavatar-default").resizable()
            }
            .frame(width: Constants.authorImageLength, height: Constants.authorImageLength)
            .clipShape(Circle())
            .overlay {
                Circle()
                    .stroke(Color(uiColor: .systemBackground), lineWidth: 1.0)
            }
            .offset(x: 2.0, y: 2.0)
        }
    }

    var tagsView: some View {
        ReaderDetailTagsWrapperView(topics: viewModel.tags, delegate: viewModel.topicDelegate)
            .background(GeometryReader { geometry in
                // The host view does not react properly after the collection view finished its layout.
                // This informs any size changes to the host view so that it can readjust correctly.
                Color.clear
                    .onChange(of: geometry.size) { newValue in
                        onTagsViewUpdated?()
                    }
            })
    }

    var authorText: some View {
        var texts: [Text] = [
            Text(viewModel.authorName)
                .font(.footnote)
                .foregroundColor(Color(.text)),

            Text(" • ")
                .font(.footnote)
                .foregroundColor(Color(.secondaryLabel)),

            // TODO: Process the logic for relative post time.
            // TODO: Use the current relative time formatter.
            Text(viewModel.relativePostTime)
                .font(.footnote)
                .foregroundColor(Color(.secondaryLabel))
        ]

        if direction == .rightToLeft {
            texts.reverse()
        }

        return texts.reduce(Text(""), +)
    }

    /// TODO: Update when the Follow buttons are updated.
    @ViewBuilder
    private func followButton(isPhone: Bool = true) -> some View {
        let style: LegacyFollowButtonStyle = viewModel.isFollowingSite ? .following : .follow

        Button {
            viewModel.didTapFollowButton()
        } label: {
            if isPhone {
                // only shows the icon as the button.
                Image(uiImage: .gridicon(style.gridiconType, size: style.iconButtonSize))
                    .tint(style.tintColor)
            } else {
                // shows both the icon and the label.
                Label {
                    Text(style.buttonLabel)
                        .font(.callout)
                        .fontWeight(style.fontWeight)
                } icon: {
                    Image(uiImage: .gridicon(style.gridiconType, size: style.labelIconSize).imageWithTintColor(style.labelIconTintColor)!)
                }
                .padding(style.buttonPadding)
                .background(style.labelBackgroundColor)
                .tint(style.labelTintColor)
                .clipShape(RoundedRectangle(cornerRadius: style.cornerRadius))
                .overlay {
                    RoundedRectangle(cornerRadius: style.cornerRadius)
                        .stroke(style.borderColor, lineWidth: style.borderWidth)
                }
            }
        }
        .accessibilityLabel(style.buttonLabel)
        .accessibilityHint(style.accessibilityHint)
        .disabled(!viewModel.isFollowButtonInteractive)
    }
}

// MARK: Private Helpers

fileprivate extension ReaderDetailNewHeaderView {

    struct Constants {
        static let siteIconLength: CGFloat = 40.0
        static let authorImageLength: CGFloat = 20.0
    }

    /// "Legacy" follow button styling.
    /// Mostly taken from `WPStyleGuide+Reader`'s `applyReaderFollowButtonStyle`
    ///
    /// TODO: Remove this when the new Follow buttons are added.
    struct LegacyFollowButtonStyle {
        // Style for the Follow button
        static let follow = LegacyFollowButtonStyle(
            gridiconType: .readerFollow,
            tintColor: Color(uiColor: .primary),
            fontWeight: .semibold,
            labelBackgroundColor: Color(uiColor: WPStyleGuide.FollowButton.Style.followBackgroundColor),
            labelTintColor: Color(uiColor: WPStyleGuide.FollowButton.Style.followTextColor),
            labelIconTintColor: WPStyleGuide.FollowButton.Style.followTextColor,
            borderWidth: 0.0,
            buttonLabel: WPStyleGuide.FollowButton.Text.followStringForDisplay,
            accessibilityHint: WPStyleGuide.FollowButton.Text.accessibilityHint
        )

        // Style for the Following button
        static let following = LegacyFollowButtonStyle(
            gridiconType: .readerFollowing,
            tintColor: Color(uiColor: .gray(.shade20)),
            fontWeight: .regular,
            labelBackgroundColor: Color(uiColor: WPStyleGuide.FollowButton.Style.followingBackgroundColor),
            labelTintColor: Color(uiColor: WPStyleGuide.FollowButton.Style.followingIconColor),
            labelIconTintColor: WPStyleGuide.FollowButton.Style.followingTextColor,
            borderWidth: 1.0,
            buttonLabel: WPStyleGuide.FollowButton.Text.followingStringForDisplay,
            accessibilityHint: WPStyleGuide.FollowButton.Text.accessibilityHint
        )

        let gridiconType: GridiconType

        // iPhone-specific styling
        let iconButtonSize = CGSize(width: 24, height: 24)
        let tintColor: Color
        let iconBackgroundColor: Color = .clear

        // iPad-specific styling
        let font: Font = .callout
        let fontWeight: Font.Weight
        let buttonPadding = EdgeInsets(top: 6.0, leading: 12.0, bottom: 6.0, trailing: 12.0)
        let labelBackgroundColor: Color
        let labelTintColor: Color
        let labelIconTintColor: UIColor
        let cornerRadius = 4.0
        let borderColor = Color(uiColor: .primaryButtonBorder)
        let borderWidth: CGFloat
        let labelIconSize = CGSize(width: WPStyleGuide.fontSizeForTextStyle(.callout),
                                   height: WPStyleGuide.fontSizeForTextStyle(.callout))

        // localization-related
        let buttonLabel: String
        let accessibilityHint: String
    }
}

// MARK: - TopicCollectionView UIViewRepresentable Wrapper

fileprivate struct ReaderDetailTagsWrapperView: UIViewRepresentable {
    private let topics: [String]
    private weak var delegate: ReaderTopicCollectionViewCoordinatorDelegate?

    init(topics: [String], delegate: ReaderTopicCollectionViewCoordinatorDelegate?) {
        self.topics = topics
        self.delegate = delegate
    }

    func makeUIView(context: Context) -> UICollectionView {
        let view = TopicsCollectionView(frame: .zero, collectionViewLayout: ReaderInterestsCollectionViewFlowLayout())
        view.topics = topics
        view.topicDelegate = delegate

        // ensure that the collection view hugs its content.
        view.setContentHuggingPriority(.defaultHigh, for: .vertical)
        return view
    }

    func updateUIView(_ uiView: UICollectionView, context: Context) {
        uiView.layoutIfNeeded()
    }
}
