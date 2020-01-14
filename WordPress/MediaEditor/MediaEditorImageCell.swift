import UIKit

class MediaEditorImageCell: UICollectionViewCell {
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var errorView: UIView!
    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet weak var retryButton: UIButton!

    weak var delegate: MediaEditorHubDelegate?

    func apply(styles: MediaEditorStyles) {

        if let errorLoadingImageMessage = styles[.errorLoadingImageMessage] as? String {
            errorLabel.text = errorLoadingImageMessage
        }

        if let retryIcon = styles[.retryIcon] as? UIImage {
            retryButton.setImage(retryIcon, for: .normal)
        }

    }

    @IBAction func retry(_ sender: Any) {
        delegate?.retry()
    }

}
