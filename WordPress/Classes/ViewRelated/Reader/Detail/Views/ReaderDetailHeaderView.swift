import UIKit
import SwiftUI
import WordPressData
import WordPressUI
import WordPressReader

protocol ReaderDetailHeaderViewDelegate: AnyObject {
    func didTapBlogName()
    func didTapHeaderAvatar()
    func didTapFollowButton(completion: @escaping () -> Void)
    func didSelectTopic(_ topic: String)
}

final class ReaderDetailHeaderHostingView: UIView {
    weak var delegate: ReaderDetailHeaderViewDelegate? {
        didSet {
            viewModel.headerDelegate = delegate
        }
    }

    var displaySetting: ReaderDisplaySettings = .standard {
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

        let headerView = ReaderDetailHeaderView(viewModel: viewModel) { [weak self] in
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

extension ReaderDetailHeaderHostingView {
    func configure(for post: ReaderPost) {
        viewModel.configure(with: TaggedManagedObjectID(post),
                            completion: refreshContainerLayout)
    }

    func configure(for post: ReaderPost, title: String?) {
        viewModel.configure(with: TaggedManagedObjectID(post),
                            customTitle: title,
                            completion: refreshContainerLayout)
    }

    func refreshFollowButton() {
        viewModel.refreshFollowState()
    }
}

// MARK: ReaderTopicCollectionViewCoordinatorDelegate

extension ReaderDetailHeaderHostingView: ReaderTopicCollectionViewCoordinatorDelegate {
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

    @Published var authorAvatarURL: URL? = nil
    @Published var authorName = String()
    @Published var relativePostTime = String()
    @Published var siteName = String()
    @Published var postTitle: String? = nil // post title can be empty.
    @Published var tags: [String] = []

    @Published var displaySetting: ReaderDisplaySettings

    init(displaySetting: ReaderDisplaySettings, coreDataStack: CoreDataStackSwift = ContextManager.shared) {
        self.displaySetting = displaySetting
        self.coreDataStack = coreDataStack
    }

    func configure(with objectID: TaggedManagedObjectID<ReaderPost>, completion: (() -> Void)?) {
        configure(with: objectID, customTitle: nil, completion: completion)
    }

    func configure(with objectID: TaggedManagedObjectID<ReaderPost>, customTitle: String?, completion: (() -> Void)?) {
        postObjectID = objectID
        coreDataStack.performQuery { [weak self] context -> Void in
            guard let self,
                  let post = try? context.existingObject(with: objectID) else {
                return
            }

            self.isFollowingSite = post.isFollowing

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

            self.postTitle = customTitle ?? post.titleForDisplay()
            self.tags = post.tagsForDisplay()
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
struct ReaderDetailHeaderView: View {

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
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 16.0) {
                if let postTitle = viewModel.postTitle {
                    Text(postTitle)
                        .font(Font(viewModel.displaySetting.font(with: .title1, weight: .bold)))
                        .foregroundStyle(Color(primaryTextColor))
                        .lineLimit(nil)
                        .textSelection(.enabled)
                        .fixedSize(horizontal: false, vertical: true) // prevents the title from being truncated.
                }
                headerRow
                if !viewModel.tags.isEmpty {
                    tagsView
                }
            }
            // Added an extra 4.0 to top padding to account for a legacy layout issue with featured image.
            .padding(EdgeInsets(top: 20.0, leading: 16.0, bottom: 16.0, trailing: 16.0))
            .background {
                GeometryReader { proxy in
                    Color.clear
                        .onAppear {
                            onContentSizeChanged?()
                        }
                        .onChange(of: proxy.size) {
                            onContentSizeChanged?()
                        }
                }
            }

            Divider()
                .padding(.horizontal, 16)
        }
    }

    var headerRow: some View {
        HStack(alignment: .center, spacing: 12) {
            authorAvatarView
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline, spacing: 0) {
                    Text(viewModel.authorName)
                        .font(Font(viewModel.displaySetting.font(with: .footnote, weight: .semibold)))
                        .foregroundStyle(Color(primaryTextColor))
                    if !viewModel.authorName.isEmpty {
                        Text(" • ")
                            .font(Font(viewModel.displaySetting.font(with: .footnote)))
                            .foregroundColor(Color(viewModel.displaySetting.color.secondaryForeground))
                            .layoutPriority(1)
                    }
                    timestampText
                        .layoutPriority(1)
                    Spacer()
                }
                .lineLimit(1)

                HStack(alignment: .firstTextBaseline, spacing: 0) {
                    Text(viewModel.siteName)
                        .font(Font(viewModel.displaySetting.font(with: .footnote)))
                        .foregroundStyle(Color(primaryTextColor))
                    if !viewModel.isFollowingSite || !viewModel.isFollowButtonInteractive {
                        Text(" • ")
                            .font(Font(viewModel.displaySetting.font(with: .footnote)))
                            .foregroundColor(Color(viewModel.displaySetting.color.secondaryForeground))
                            .layoutPriority(1)
                        Button(WPStyleGuide.FollowButton.Text.followStringForDisplay) {
                            viewModel.didTapFollowButton()
                        }
                        .font(Font(viewModel.displaySetting.font(with: .footnote)))
                        .disabled(!viewModel.isFollowButtonInteractive)
                    }
                    Spacer()
                }
                .lineLimit(1)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits([.isButton])
        .accessibilityHint(Constants.authorStackAccessibilityHint)
        .onTapGesture {
            viewModel.didTapAuthorSection()
        }
    }

    var authorAvatarView: some View {
        CachedAsyncImage(url: viewModel.authorAvatarURL) { image in
            image.resizable()
        } placeholder: {
            Image("blavatar-default").resizable()
        }
        .frame(width: Constants.siteIconLength, height: Constants.siteIconLength)
        .clipShape(Circle())
        .overlay {
            Circle()
                .strokeBorder(Color(uiColor: avatarInnerBorderColor), lineWidth: 0.5)
                .opacity(innerBorderOpacity)
        }
    }

    var tagsView: some View {
        ReaderDetailTagsWrapperView(topics: viewModel.tags, displaySetting: viewModel.displaySetting, delegate: viewModel.topicDelegate)
            .background(GeometryReader { geometry in
                // The host view does not react properly after the collection view finished its layout.
                // This informs any size changes to the host view so that it can readjust correctly.
                Color.clear
                    .onChange(of: geometry.size) {
                        onContentSizeChanged?()
                    }
            })
    }

    var timestampText: Text {
        Text(viewModel.relativePostTime)
            .font(Font(viewModel.displaySetting.font(with: .footnote)))
            .foregroundColor(Color(viewModel.displaySetting.color.secondaryForeground))
    }
}

// MARK: Private Helpers

fileprivate extension ReaderDetailHeaderView {

    struct Constants {
        static let siteIconLength: CGFloat = 40.0

        static let authorStackAccessibilityHint = NSLocalizedString(
            "reader.detail.header.authorInfo.a11y.hint",
            value: "Views posts from the site",
            comment: "Accessibility hint to inform that the author section can be tapped to see posts from the site."
        )
    }

}

// MARK: - TopicCollectionView UIViewRepresentable Wrapper

fileprivate struct ReaderDetailTagsWrapperView: UIViewRepresentable {
    private let topics: [String]
    private let displaySetting: ReaderDisplaySettings
    private weak var delegate: ReaderTopicCollectionViewCoordinatorDelegate?

    init(topics: [String], displaySetting: ReaderDisplaySettings, delegate: ReaderTopicCollectionViewCoordinatorDelegate?) {
        self.topics = topics
        self.displaySetting = displaySetting
        self.delegate = delegate
    }

    func makeUIView(context: Context) -> UICollectionView {
        let view = TopicsCollectionView(frame: .zero, collectionViewLayout: ReaderInterestsCollectionViewFlowLayout())
        view.topics = topics
        view.topicDelegate = delegate

        if ReaderDisplaySettings.customizationEnabled {
            view.coordinator?.displaySetting = displaySetting
        }

        // ensure that the collection view hugs its content.
        view.setContentHuggingPriority(.defaultHigh, for: .vertical)
        view.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return view
    }

    func updateUIView(_ uiView: UICollectionView, context: Context) {
        if let view = uiView as? TopicsCollectionView,
           ReaderDisplaySettings.customizationEnabled {
            view.coordinator?.displaySetting = displaySetting
        }

        uiView.reloadData()
        uiView.layoutIfNeeded()
    }
}
