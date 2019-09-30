import UIKit
import WordPressKit
import Gridicons

class PluginDirectoryCollectionViewCell: UICollectionViewCell {

    @IBOutlet var logoImageView: UIImageView!
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var authorLabel: UILabel!

    var accessoryView: UIView? {
        didSet {
            oldValue?.removeFromSuperview()

            guard let view = accessoryView else {
                return
            }

            self.addSubview(view)

            view.topAnchor.constraint(greaterThanOrEqualTo: authorLabel.bottomAnchor).isActive = true
            view.leadingAnchor.constraint(equalTo: self.leadingAnchor).isActive = true
            view.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -10).isActive = true
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        nameLabel.font = WPStyleGuide.subtitleFontBold()
        logoImageView.tintColor = WPStyleGuide.cellGridiconAccessoryColor()
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        accessoryView?.removeFromSuperview()
        logoImageView.cancelImageDownload()
        logoImageView.image = nil
    }

    func configure(with directoryEntry: PluginDirectoryEntry) {
        configure(name: directoryEntry.name, author: directoryEntry.author, image: directoryEntry.icon)
    }

    func configure(with plugin: Plugin) {
        configure(name: plugin.state.name, author: plugin.state.author, image: plugin.directoryEntry?.icon)
    }

    func configure(name: String, author: String, image: URL?) {
        let iconPlaceholder = Gridicon.iconOfType(.plugins, withSize: CGSize(width: 98, height: 98))

        if let imageURL = image {
            logoImageView?.downloadImage(from: imageURL, placeholderImage: iconPlaceholder)
        } else {
            logoImageView.image = iconPlaceholder
        }

        nameLabel?.text = name
        authorLabel?.text = author

        nameLabel?.textColor = .text
        authorLabel?.textColor = .textSubtle
    }

}
