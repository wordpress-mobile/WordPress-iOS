import UIKit

protocol ReaderDiscoverHeaderViewDelegate: AnyObject {
    func readerDiscoverHeaderView(_ view: ReaderDiscoverHeaderView, didChangeSelection selection: ReaderDiscoverChannel)
}

final class ReaderDiscoverHeaderView: UIView {
    private let titleView = ReaderStreamTitleView()
    private let channelsStackView = UIStackView(spacing: 8, [])
    private var channelViews: [ReaderDiscoverChannelView] = []

    private var selectedChannel: ReaderDiscoverChannel?

    weak var delegate: ReaderDiscoverHeaderViewDelegate?

    override init(frame: CGRect) {
        super.init(frame: frame)

        let scrollView = UIScrollView()
        scrollView.addSubview(channelsStackView)
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.clipsToBounds = false
        channelsStackView.pinEdges()
        scrollView.heightAnchor.constraint(equalTo: channelsStackView.heightAnchor).isActive = true

        let stackView = UIStackView(axis: .vertical, spacing: 8, [titleView, scrollView])
        addSubview(stackView)
        stackView.pinEdges(insets: UIEdgeInsets(top: 16, left: 16, bottom: 8, right: 16))

        titleView.titleLabel.text = Strings.title
        titleView.detailsLabel.text = Strings.details
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
            backgroundView.backgroundColor = UIColor.opaqueSeparator.withAlphaComponent(0.33)
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
            tag.title.localizedCapitalized
        }
    }
}

private enum Strings {
    static let title = NSLocalizedString("reader.discover.header.title", value: "Discover", comment: "Header view title")
    static let details = NSLocalizedString("reader.discover.header.title", value: "Explore popular blogs that inspire, educate, and entertain.", comment: "Header view details")
}

@available(iOS 17, *)
#Preview {
    ReaderDiscoverHeaderView()
}
