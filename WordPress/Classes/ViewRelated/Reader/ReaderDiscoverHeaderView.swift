import UIKit

final class ReaderDiscoverHeaderView: UIView {
    private let titleView = ReaderStreamTitleView()
    private let tagsStackView = UIStackView(spacing: 8, [])
    private var tagViews: [ReaderTagView] = []

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

        // TODO: (reader) configure dynamically. where does these come from?
        configure(tags: ["Recommended", "First posts", "Latest", "Daily prompts", "Food"])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(tags: [String]) {
        for view in tagViews {
            view.removeFromSuperview()
        }
        tagViews = tags.map(makeTagView)
        for view in tagViews {
            tagsStackView.addArrangedSubview(view)
        }
    }

    private func makeTagView(_ title: String) -> ReaderTagView {
        let view = ReaderTagView(title: title)
        view.button.addAction(UIAction { [weak self, weak view] _ in
            guard let self, let view else { return }
            self.readerTagViewTapped(view)
        }, for: .primaryActionTriggered)
        return view
    }

    @objc private func readerTagViewTapped(_ view: ReaderTagView) {
        didSelectTag(view.title)
    }

    private func didSelectTag(_ tag: String) {
        for view in self.tagViews {
            view.isSelected = view.title == tag
        }
    }
}

private final class ReaderTagView: UIView {
    private let textLabel = UILabel()
    private let backgroundView = UIView()
    let button = UIButton(type: .system)
    let title: String

    var isSelected: Bool = false {
        didSet {
            guard oldValue != isSelected else { return }
            configure(isSelected: isSelected)
        }
    }

    init(title: String) {
        self.title = title

        super.init(frame: .zero)

        textLabel.font = UIFont.preferredFont(forTextStyle: .subheadline).withWeight(.medium)
        textLabel.text = title

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

private enum Strings {
    static let title = NSLocalizedString("reader.discover.header.title", value: "Discover", comment: "Header view title")
    static let details = NSLocalizedString("reader.discover.header.title", value: "Explore popular blogs that inspire, educate, and entertain.", comment: "Header view details")
}

@available(iOS 17, *)
#Preview {
    ReaderDiscoverHeaderView()
}
