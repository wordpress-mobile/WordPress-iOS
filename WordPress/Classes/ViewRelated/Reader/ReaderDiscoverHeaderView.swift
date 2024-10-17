import UIKit

protocol ReaderDiscoverHeaderViewDelegate: AnyObject {
    func readerDiscoverHeaderView(_ view: ReaderDiscoverHeaderView, didChangeSelection selection: ReaderDiscoverTag)
}

final class ReaderDiscoverHeaderView: UIView {
    private let titleView = ReaderStreamTitleView()
    private let tagsStackView = UIStackView(spacing: 8, [])
    private var tagViews: [ReaderDiscoverTagView] = []

    private var selectedTag: ReaderDiscoverTag?

    weak var delegate: ReaderDiscoverHeaderViewDelegate?

    override init(frame: CGRect) {
        super.init(frame: frame)

        let scrollView = UIScrollView()
        scrollView.addSubview(tagsStackView)
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.clipsToBounds = false
        tagsStackView.pinEdges()
        scrollView.heightAnchor.constraint(equalTo: tagsStackView.heightAnchor).isActive = true

        let stackView = UIStackView(axis: .vertical, spacing: 8, [titleView, scrollView])
        addSubview(stackView)
        stackView.pinEdges(insets: UIEdgeInsets(top: 16, left: 16, bottom: 8, right: 16))

        titleView.titleLabel.text = Strings.title
        titleView.detailsLabel.text = Strings.details
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(tags: [ReaderDiscoverTag]) {
        for view in tagViews {
            view.removeFromSuperview()
        }
        tagViews = tags.map(makeTagView)
        for view in tagViews {
            tagsStackView.addArrangedSubview(view)
        }
    }

    func setSelectedTag(_ tag: ReaderDiscoverTag) {
        selectedTag = tag
        refreshTagViews()
    }

    private func makeTagView(_ tag: ReaderDiscoverTag) -> ReaderDiscoverTagView {
        let view = ReaderDiscoverTagView(tag: tag)
        view.button.addAction(UIAction { [weak self] _ in
            self?.didSelectTag(tag)
        }, for: .primaryActionTriggered)
        return view
    }

    private func didSelectTag(_ tag: ReaderDiscoverTag) {
        guard selectedTag != tag else {
            return
        }
        selectedTag = tag
        delegate?.readerDiscoverHeaderView(self, didChangeSelection: tag)
        refreshTagViews()
    }

    private func refreshTagViews() {
        for view in tagViews {
            view.isSelected = view.discoverTag == selectedTag
        }
    }
}

private final class ReaderDiscoverTagView: UIView {
    private let textLabel = UILabel()
    private let backgroundView = UIView()
    let button = UIButton(type: .system)
    let discoverTag: ReaderDiscoverTag

    var isSelected: Bool = false {
        didSet {
            guard oldValue != isSelected else { return }
            configure(isSelected: isSelected)
        }
    }

    init(tag: ReaderDiscoverTag) {
        self.discoverTag = tag

        super.init(frame: .zero)

        textLabel.font = UIFont.preferredFont(forTextStyle: .subheadline).withWeight(.medium)
        textLabel.text = discoverTag.localizedTitle

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

enum ReaderDiscoverTag: Hashable {
    /// The default channel showing your selected tags.
    case recommended

    // case firstPosts

    /// Latest post from your selected tags.
    case latest

    /// A quick access for your tags.
    case tag(ReaderTagTopic)

    var localizedTitle: String {
        switch self {
        case .recommended:
            NSLocalizedString("reader.discover.header.tag.recommended", value: "Recommended", comment: "Header view tag (filter)")
        case .latest:
            NSLocalizedString("reader.discover.header.tag.latest", value: "Latest", comment: "Header view tag (filter)")
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
