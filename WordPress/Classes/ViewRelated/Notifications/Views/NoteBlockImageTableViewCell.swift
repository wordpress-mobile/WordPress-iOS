import UIKit
import WordPressShared
import WordPressUI

class NoteBlockImageTableViewCell: NoteBlockTableViewCell {
    // MARK: - Public Properties
    fileprivate var imageURL: URL?
    override var isBadge: Bool {
        didSet {
            backgroundColor = isBadge ? Styles.badgeBackgroundColor : Styles.blockBackgroundColor
        }
    }

    var backgroundImage: UIImage? {
        didSet {
            backgroundImageView.image = backgroundImage
        }
    }

    // MARK: - Public Methods

    /// Downloads a remote image, given it's URL, assuming that we're already not displaying that very same image.
    ///
    /// - Parameter url: Target image URL.
    ///
    @objc func downloadImage(_ url: URL?) {
        guard imageURL != url else {
            return
        }

        imageURL = url

        blockImageView.downloadImage(
            from: url,
            success: nil,
            failure: { [weak self] _ in
                // Only reset if we're still pointing at the failed URL — the cell may have been reused for another notification in the meantime.
                guard let self, self.imageURL == url else {
                    return
                }
                self.imageURL = nil
            }
        )
    }

    // MARK: - View Methods

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        selectionStyle = .none
        contentView.backgroundColor = .clear

        let stackView = UIStackView(arrangedSubviews: [blockImageView])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.isOpaque = false
        stackView.axis = .vertical
        stackView.alignment = .center

        contentView.addSubview(backgroundImageView)
        contentView.addSubview(stackView)
        contentView.pinSubviewToAllEdgeMargins(stackView)

        let imageHeightConstraint = blockImageView.heightAnchor.constraint(equalToConstant: Metrics.imageSize)
        imageHeightConstraint.priority = UILayoutPriority(999)
        NSLayoutConstraint.activate([
            backgroundImageView.centerXAnchor.constraint(equalTo: stackView.centerXAnchor),
            backgroundImageView.centerYAnchor.constraint(equalTo: stackView.centerYAnchor),
            blockImageView.widthAnchor.constraint(equalToConstant: Metrics.imageSize),
            imageHeightConstraint
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        blockImageView.image = nil
        backgroundImageView.image = nil
        imageURL = nil
        backgroundImage = nil
    }

    // MARK: - Helpers
    fileprivate typealias Styles = WPStyleGuide.Notifications

    private enum Metrics {
        static let imageSize: CGFloat = 180
    }

    // MARK: - Subviews
    let blockImageView = NoteBlockImageTableViewCell.makeImageView()
    let backgroundImageView: UIImageView = {
        let imageView = NoteBlockImageTableViewCell.makeImageView()
        imageView.clipsToBounds = true
        return imageView
    }()

    private static func makeImageView() -> UIImageView {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.setContentHuggingPriority(UILayoutPriority(251), for: .horizontal)
        imageView.setContentHuggingPriority(UILayoutPriority(251), for: .vertical)
        return imageView
    }
}
