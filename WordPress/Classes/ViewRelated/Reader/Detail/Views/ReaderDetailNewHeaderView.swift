import SwiftUI
import WordPressUI

protocol ReaderDetailHeaderViewDelegate: AnyObject {
    func didTapBlogName()
    func didTapHeaderAvatar()
    func didTapFollowButton(completion: @escaping () -> Void)
    func didSelectTopic(_ topic: String)
    func didTapLikes()
    func didTapComments()
}

class ReaderDetailNewHeaderViewHost: UIView {
    weak var delegate: ReaderDetailHeaderViewDelegate? {
        didSet {
            viewModel.headerDelegate = delegate
        }
    }

    // TODO: Find out if we still need this.
    var useCompatibilityMode: Bool = false

    var displaySetting: ReaderDisplaySetting = .standard {
        didSet {
            viewModel.displaySetting = displaySetting
            Task { @MainActor in
                refreshContainerLayout()
            }
        }
    }

    private var postObjectID: TaggedManagedObjectID<ReaderPost>? = nil

    // TODO: Populate this with values from the ReaderPost.
    private lazy var viewModel: ReaderDetailHeaderViewModel = {
        $0.topicDelegate = self
        return $0
    }(ReaderDetailHeaderViewModel(displaySetting: displaySetting))

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init() {
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

        DispatchQueue.main.async {
            swiftUIView.invalidateIntrinsicContentSize()
            self.layoutIfNeeded()
        }
    }
}

// MARK: ReaderDetailHeader

extension ReaderDetailNewHeaderViewHost {
    func configure(for post: ReaderPost) {
        viewModel.configure(with: TaggedManagedObjectID(post),
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
    @Published var isFollowButtonInteractive = true

    @Published var siteIconURL: URL? = nil
    @Published var authorAvatarURL: URL? = nil
    @Published var authorName = String()
    @Published var relativePostTime = String()
    @Published var siteName = String()
    @Published var postTitle: String? = nil // post title can be empty.
    @Published var likeCount: Int? = nil
    @Published var commentCount: Int? = nil
    @Published var tags: [String] = []

    @Published var showsAuthorName: Bool = true

    @Published var displaySetting: ReaderDisplaySetting

    var likeCountString: String? {
        guard let count = likeCount, count > 0 else {
            return nil
        }
        return WPStyleGuide.likeCountForDisplay(count)
    }

    var commentCountString: String? {
        guard let count = commentCount, count > 0 else {
            return nil
        }
        return WPStyleGuide.commentCountForDisplay(count)
    }

    init(displaySetting: ReaderDisplaySetting, coreDataStack: CoreDataStackSwift = ContextManager.shared) {
        self.displaySetting = displaySetting
        self.coreDataStack = coreDataStack
    }

    func configure(with objectID: TaggedManagedObjectID<ReaderPost>, completion: (() -> Void)?) {
        postObjectID = objectID
        coreDataStack.performQuery { [weak self] context -> Void in
            guard let self,
                  let post = try? context.existingObject(with: objectID) else {
                return
            }

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

            // hide the author name if it exactly matches the site name.
            // context: https://github.com/wordpress-mobile/WordPress-iOS/pull/21674#issuecomment-1747202728
            self.showsAuthorName = self.authorName != self.siteName && !self.authorName.isEmpty

            self.postTitle = post.titleForDisplay() ?? nil
            self.likeCount = post.likeCount?.intValue
            self.commentCount = post.commentCount?.intValue
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

    func didTapLikes() {
        headerDelegate?.didTapLikes()
    }

    func didTapComments() {
        headerDelegate?.didTapComments()
    }
}

// MARK: - SwiftUI

/// The updated header version for Reader Details.
///
/// TODO: Rename this to `ReaderDetailHeaderView` once the `readerImprovements` flag is removed.
///
struct ReaderDetailNewHeaderView: View {

    @Environment(\.layoutDirection) var direction
    @Environment(\.colorScheme) var colorScheme

    @ObservedObject var viewModel: ReaderDetailHeaderViewModel

    /// A callback for the parent to react to content size changes.
    var onContentSizeChanged: (() -> Void)? = nil

    /// Used for the inward border. We want the color to be inverted, such that the avatar can "preserve" its shape
    /// when the image has low or almost no contrast with the background (imagine white avatar on white background).
    var avatarInnerBorderColor: UIColor {
        let color = viewModel.displaySetting.color.background
        return colorScheme == .light ? color.darkVariant() : color.lightVariant()
    }

    var primaryTextColor: UIColor {
        viewModel.displaySetting.color.foreground
    }

    var innerBorderOpacity: CGFloat {
        return colorScheme == .light ? 0.1 : 0.2
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16.0) {
            headerRow
            if let postTitle = viewModel.postTitle {
                Text(postTitle)
                    .font(Font(viewModel.displaySetting.font(with: .title1, weight: .bold)))
                    .foregroundStyle(Color(primaryTextColor))
                    .lineLimit(nil)
                    .textSelection(.enabled)
                    .fixedSize(horizontal: false, vertical: true) // prevents the title from being truncated.
            }
            if viewModel.likeCountString != nil || viewModel.commentCountString != nil {
                postCounts
            }
            if !viewModel.tags.isEmpty {
                tagsView
            }
        }
        // Added an extra 4.0 to top padding to account for a legacy layout issue with featured image.
        // Bottom padding is 0 as there's already padding between the header container and the webView in the storyboard.
        .padding(EdgeInsets(top: 12.0, leading: 16.0, bottom: 0.0, trailing: 16.0))
        .background {
            GeometryReader { proxy in
                Color.clear
                    .onAppear {
                        onContentSizeChanged?()
                    }
                    .onChange(of: proxy.size) { _ in
                        onContentSizeChanged?()
                    }
            }
        }
    }

    var headerRow: some View {
        HStack(spacing: 8.0) {
            authorStack
            Spacer()
            ReaderFollowButton(isFollowing: viewModel.isFollowingSite,
                               isEnabled: viewModel.isFollowButtonInteractive,
                               size: .compact,
                               displaySetting: viewModel.displaySetting) {
                viewModel.didTapFollowButton()
            }
        }
    }

    var authorStack: some View {
        HStack(spacing: 8.0) {
            if let siteIconURL = viewModel.siteIconURL,
               let avatarURL = viewModel.authorAvatarURL {
                avatarView(with: siteIconURL, avatarURL: avatarURL)
            }
            VStack(alignment: .leading, spacing: 4.0) {
                Text(viewModel.siteName)
                    .font(Font(viewModel.displaySetting.font(with: .callout, weight: .semibold)))
                    .foregroundStyle(Color(primaryTextColor))
                    .lineLimit(1)
                authorAndTimestampView
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits([.isButton])
        .accessibilityHint(Constants.authorStackAccessibilityHint)
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
            .overlay {
                // adds an inward border with low opacity to preserve the avatar's shape.
                Circle()
                    .strokeBorder(Color(uiColor: avatarInnerBorderColor), lineWidth: 0.5)
                    .opacity(innerBorderOpacity)
            }

            AsyncImage(url: avatarURL) { image in
                image.resizable()
            } placeholder: {
                Image("blavatar-default").resizable()
            }
            .frame(width: Constants.authorImageLength, height: Constants.authorImageLength)
            .clipShape(Circle())
            .overlay {
                // adds an inward border with low opacity to preserve the avatar's shape.
                Circle()
                    .strokeBorder(Color(uiColor: avatarInnerBorderColor), lineWidth: 0.5)
                    .opacity(innerBorderOpacity)
            }
            .background {
                // adds a border between the the author avatar and the site icon.
                Circle()
                    .stroke(Color(uiColor: viewModel.displaySetting.color.background), lineWidth: 1.0)
            }
            .offset(x: 2.0, y: 2.0)
        }
    }

    var postCounts: some View {
        HStack(spacing: 0) {
            if let likeCount = viewModel.likeCountString {
                Group {
                    Button(action: viewModel.didTapLikes) {
                        Text(likeCount)
                    }
                    if viewModel.commentCountString != nil {
                        Text(" • ")
                    }
                }
            }
            if let commentCount = viewModel.commentCountString {
                Button(action: viewModel.didTapComments) {
                    Text(commentCount)
                }
            }
        }
        .font(Font(viewModel.displaySetting.font(with: .footnote)))
        .foregroundStyle(Color(viewModel.displaySetting.color.secondaryForeground))
    }

    var tagsView: some View {
        ReaderDetailTagsWrapperView(topics: viewModel.tags, displaySetting: viewModel.displaySetting, delegate: viewModel.topicDelegate)
            .background(GeometryReader { geometry in
                // The host view does not react properly after the collection view finished its layout.
                // This informs any size changes to the host view so that it can readjust correctly.
                Color.clear
                    .onChange(of: geometry.size) { _ in
                        onContentSizeChanged?()
                    }
            })
    }

    var authorAndTimestampView: some View {
        HStack(spacing: 0) {
            if viewModel.showsAuthorName {
                Text(viewModel.authorName)
                    .font(Font(viewModel.displaySetting.font(with: .footnote)))
                    .foregroundStyle(Color(primaryTextColor))
                    .lineLimit(1)

                Text(" • ")
                    .font(Font(viewModel.displaySetting.font(with: .footnote)))
                    .foregroundColor(Color(viewModel.displaySetting.color.secondaryForeground))
                    .lineLimit(1)
                    .layoutPriority(1)
            }

            timestampText
                .lineLimit(1)
                .layoutPriority(1)

            Spacer()
        }
        .accessibilityElement()
        .accessibilityLabel(authorAccessibilityLabel)
    }

    var timestampText: Text {
        Text(viewModel.relativePostTime)
            .font(Font(viewModel.displaySetting.font(with: .footnote)))
            .foregroundColor(Color(viewModel.displaySetting.color.secondaryForeground))
    }
}

// MARK: Private Helpers

fileprivate extension ReaderDetailNewHeaderView {

    struct Constants {
        static let siteIconLength: CGFloat = 40.0
        static let authorImageLength: CGFloat = 20.0

        static let authorStackAccessibilityHint = NSLocalizedString(
            "reader.detail.header.authorInfo.a11y.hint",
            value: "Views posts from the site",
            comment: "Accessibility hint to inform that the author section can be tapped to see posts from the site."
        )
    }

    var authorAccessibilityLabel: String {
        var labels = [viewModel.relativePostTime]

        if viewModel.showsAuthorName {
            labels.insert(viewModel.authorName, at: .zero)
        }

        return labels.joined(separator: ", ")
    }
}

// MARK: - TopicCollectionView UIViewRepresentable Wrapper

fileprivate struct ReaderDetailTagsWrapperView: UIViewRepresentable {
    private let topics: [String]
    private let displaySetting: ReaderDisplaySetting
    private weak var delegate: ReaderTopicCollectionViewCoordinatorDelegate?

    init(topics: [String], displaySetting: ReaderDisplaySetting, delegate: ReaderTopicCollectionViewCoordinatorDelegate?) {
        self.topics = topics
        self.displaySetting = displaySetting
        self.delegate = delegate
    }

    func makeUIView(context: Context) -> UICollectionView {
        let view = TopicsCollectionView(frame: .zero, collectionViewLayout: ReaderInterestsCollectionViewFlowLayout())
        view.topics = topics
        view.topicDelegate = delegate

        if ReaderDisplaySetting.customizationEnabled {
            view.coordinator?.displaySetting = displaySetting
        }

        // ensure that the collection view hugs its content.
        view.setContentHuggingPriority(.defaultHigh, for: .vertical)
        view.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return view
    }

    func updateUIView(_ uiView: UICollectionView, context: Context) {
        if let view = uiView as? TopicsCollectionView,
           ReaderDisplaySetting.customizationEnabled {
            view.coordinator?.displaySetting = displaySetting
        }

        uiView.reloadData()
        uiView.layoutIfNeeded()
    }
}
