class PluginListCell: UITableViewCell {

    @IBOutlet var accessoryViewContainer: UIView!
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var authorLabel: UILabel!
    @IBOutlet var iconImageView: UIImageView!

    var pluginAccessoryView: UIView? = nil {
        willSet {
            pluginAccessoryView?.removeFromSuperview()
        }

        didSet {
            guard let view = pluginAccessoryView else { return }

            accessoryViewContainer.addSubview(view)


            view.trailingAnchor.constraint(equalTo: accessoryViewContainer.trailingAnchor).isActive = true
            view.bottomAnchor.constraint(equalTo: accessoryViewContainer.bottomAnchor).isActive = true
            view.leadingAnchor.constraint(greaterThanOrEqualTo: accessoryViewContainer.leadingAnchor).isActive = true
        }
    }
    override func prepareForReuse() {
        super.prepareForReuse()

        iconImageView.cancelImageDownloadTask()
    }

}
