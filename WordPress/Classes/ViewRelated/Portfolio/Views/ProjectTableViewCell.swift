import UIKit

class ProjectTableViewCell: UITableViewCell {
    @IBOutlet fileprivate weak var projectImageView: UIImageView!
    @IBOutlet fileprivate weak var projectTitle: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        self.backgroundColor = .white
    }

    func configure(title: String, imageURLString: String) {
        projectTitle.text = title
        guard let url = URL(string: imageURLString) else { return }
        setProjectImage(with: url)
    }

    private func setProjectImage(with url: URL) {
        guard let imageURL = PhotonImageURLHelper.photonURL(with: projectImageView.frame.size, forImageURL: url)
            else { return }

        //TODO: have portfolio view controller handle thses with it's managed object context
        let inContextImageHandler: (UIImage?) -> Void = { (image) in
            self.projectImageView.image = image
        }
        let inContextErrorHandler: (Error?) -> Void = { (error) in
        }

        WPImageSource.shared().downloadImage(for: imageURL,
                                             withSuccess: inContextImageHandler,
                                             failure: inContextErrorHandler)
    }
}
