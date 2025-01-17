import UIKit
import WordPressUI

protocol ReaderDiscoverHeaderViewDelegate: AnyObject {
    func readerDiscoverHeaderView(_ view: ReaderDiscoverHeaderView, didChangeSelection selection: ReaderDiscoverChannel)
}

final class ReaderDiscoverHeaderView: ReaderBaseHeaderView, UITextViewDelegate {
    private let titleView = ReaderTitleView()
    private let channelsStackView = UIStackView(spacing: 8, [])
    private let scrollView = UIScrollView()
    private var channelViews: [ReaderDiscoverChannelView] = []
    private var previousWidth: CGFloat?

    private var selectedChannel: ReaderDiscoverChannel?

    weak var delegate: ReaderDiscoverHeaderViewDelegate?

    override init(frame: CGRect) {
        super.init(frame: frame)

        scrollView.addSubview(channelsStackView)
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.clipsToBounds = false
        scrollView.decelerationRate = .fast

        channelsStackView.pinEdges()
        scrollView.heightAnchor.constraint(equalTo: channelsStackView.heightAnchor).isActive = true

        contentView.addSubview(titleView)
        addSubview(scrollView) // Gets added directly to the header to enable interactions when scrolled

        NSLayoutConstraint.activate([
            titleView.topAnchor.constraint(equalTo: contentView.topAnchor),
            scrollView.topAnchor.constraint(equalTo: titleView.bottomAnchor, constant: 8),
            scrollView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
        ])
        titleView.pinEdges(.horizontal)
        scrollView.pinEdges(.horizontal)

        titleView.titleLabel.text = SharedStrings.Reader.discover
        titleView.detailsTextView.attributedText = {
            guard let details = try? NSMutableAttributedString(markdown: Strings.details) else {
                return nil
            }
            details.addAttributes([
                .font: UIFont.preferredFont(forTextStyle: .subheadline),
                .foregroundColor: UIColor.secondaryLabel,
            ], range: NSRange(location: 0, length: details.length))
            return details
        }()
        titleView.detailsTextView.delegate = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        if previousWidth != bounds.width {
            previousWidth = bounds.width
            updateScrollViewInsets()
        }
    }

    private func updateScrollViewInsets() {
        scrollView.contentInset.left = contentView.frame.minX - (isCompact ? 0 : 10)
        scrollView.contentInset.right = frame.maxX - contentView.frame.maxX + 10
        scrollView.contentOffset = CGPoint(x: -scrollView.contentInset.left, y: 0)
    }

    func configure(channels: [ReaderDiscoverChannel]) {
        for view in channelViews {
            view.removeFromSuperview()
        }
        channelViews = channels.map(makeChannelView)
        for view in channelViews {
            channelsStackView.addArrangedSubview(view)
        }
    }

    func setSelectedChannel(_ channel: ReaderDiscoverChannel) {
        selectedChannel = channel
        refreshChannelViews()
    }

    override func didUpdateIsCompact(_ isCompact: Bool) {
        super.didUpdateIsCompact(isCompact)
        updateScrollViewInsets()
    }

    // MARK: Channels

    private func makeChannelView(_ channel: ReaderDiscoverChannel) -> ReaderDiscoverChannelView {
        let view = ReaderDiscoverChannelView(channel: channel)
        view.button.addAction(UIAction { [weak self] _ in
            self?.didSelectChannel(channel)
        }, for: .primaryActionTriggered)
        return view
    }

    private func didSelectChannel(_ channel: ReaderDiscoverChannel) {
        guard selectedChannel != channel else {
            return
        }
        selectedChannel = channel
        delegate?.readerDiscoverHeaderView(self, didChangeSelection: channel)
        refreshChannelViews()
    }

    private func refreshChannelViews() {
        for view in channelViews {
            view.isSelected = view.channel == selectedChannel
        }
    }

    // MARK: UITextViewDelegate

    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange) -> Bool {
        WPAnalytics.track(.readerDiscoverEditInterestsTapped)

        let tagsVC = ReaderTagsTableViewController(style: .plain)
        tagsVC.title = Strings.editInterests
        tagsVC.navigationItem.rightBarButtonItem = UIBarButtonItem(title: SharedStrings.Button.done, primaryAction: UIAction { [weak tagsVC] _ in
            tagsVC?.presentingViewController?.dismiss(animated: true)
        })
        let navVC = UINavigationController(rootViewController: tagsVC)
        UIViewController.topViewController?.present(navVC, animated: true)
        return false
    }
}

private final class ReaderDiscoverChannelView: UIView {
    private let textLabel = UILabel()
    private let backgroundView = UIView()
    let button = UIButton(type: .system)
    let channel: ReaderDiscoverChannel

    var isSelected: Bool = false {
        didSet {
            guard oldValue != isSelected else { return }
            configure(isSelected: isSelected)
        }
    }

    init(channel: ReaderDiscoverChannel) {
        self.channel = channel

        super.init(frame: .zero)

        textLabel.font = UIFont.preferredFont(forTextStyle: .subheadline).withWeight(.medium)
        textLabel.text = channel.localizedTitle
        textLabel.adjustsFontForContentSizeCategory = true
        textLabel.maximumContentSizeCategory = .accessibilityMedium

        backgroundView.clipsToBounds = true

        addSubview(backgroundView)
        addSubview(textLabel)
        addSubview(button)

        textLabel.pinEdges(to: backgroundView, insets: UIEdgeInsets(horizontal: 10, vertical: 6))
        backgroundView.pinEdges(insets: UIEdgeInsets(.vertical, 8))
        button.pinEdges()

        configure(isSelected: isSelected)
    }

    private func configure(isSelected: Bool) {
        if isSelected {
            backgroundView.backgroundColor = UIColor.label
            textLabel.textColor = UIColor.systemBackground
        } else {
            backgroundView.backgroundColor = UIColor(light: UIColor.opaqueSeparator.withAlphaComponent(0.33), dark: UIColor.opaqueSeparator)
            textLabel.textColor = UIColor.label
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        backgroundView.layer.cornerRadius = backgroundView.bounds.height / 2
    }
}

enum ReaderDiscoverChannel: Hashable {
    /// The default channel showing your selected tags.
    case recommended

    /// First posts in the selected tags.
    case firstPosts

    /// Latest post from your selected tags.
    case latest

    case dailyPrompts

    /// A quick access for your tags.
    case tag(ReaderTagTopic)

    var localizedTitle: String {
        switch self {
        case .recommended:
            NSLocalizedString("reader.discover.channel.recommended", value: "Recommended", comment: "Header view channel (filter)")
        case .firstPosts:
            NSLocalizedString("reader.discover.channel.firstPost", value: "First Posts", comment: "Header view channel (filter)")
        case .latest:
            NSLocalizedString("reader.discover.channel.latest", value: "Latest", comment: "Header view channel (filter)")
        case .dailyPrompts:
            NSLocalizedString("reader.discover.channel.dailyPrompts", value: "Daily Prompts", comment: "Header view channel (filter)")
        case .tag(let tag):
            tag.formattedTitle
        }
    }

    var analyticsProperties: [String: String] {
        var properties = ["channel": analyticsID]
        if case let .tag(tag) = self {
            properties["tag"] = tag.slug
        }
        return properties
    }

    private var analyticsID: String {
        switch self {
        case .recommended: "recommended"
        case .firstPosts: "first_posts"
        case .latest: "latest"
        case .dailyPrompts: "daily_prompts"
        case .tag: "tag"
        }
    }
}

private enum Strings {
    static let details = NSLocalizedString("reader.discover.header.title", value: "Explore popular blogs that inspire, educate, and entertain based on your [interests](/interests).", comment: "Reader Discover header view details label. The text has a Markdown URL: [interests](/interests). Only the text in the square brackets needs to be translated: [<translate_this>](/interests).")
    static let editInterests = NSLocalizedString("reader.editInterests.title", value: "Edit Interests", comment: "Screen title")
}

@available(iOS 17, *)
#Preview {
    ReaderDiscoverHeaderView()
}
