import UIKit

struct StatsTotalRowData {
    var name: String
    var data: String
    var dataBarPercent: Float?
    var icon: UIImage?
    var socialIconURL: URL?
    var userIconURL: URL?
    var nameDetail: String?
    var showDisclosure: Bool

    init(name: String,
         data: String,
         dataBarPercent: Float? = nil,
         icon: UIImage? = nil,
         socialIconURL: URL? = nil,
         userIconURL: URL? = nil,
         nameDetail: String? = nil,
         showDisclosure: Bool = false) {
        self.name = name
        self.data = data
        self.dataBarPercent = dataBarPercent
        self.nameDetail = nameDetail
        self.icon = icon
        self.socialIconURL = socialIconURL
        self.userIconURL = userIconURL
        self.showDisclosure = showDisclosure
    }
}

class StatsTotalRow: UIView, NibLoadable {

    // MARK: - Properties

    @IBOutlet weak var separatorLine: UIView!

    @IBOutlet weak var imageStackView: UIStackView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var imageWidthConstraint: NSLayoutConstraint!

    @IBOutlet weak var itemLabel: UILabel!
    @IBOutlet weak var itemDetailLabel: UILabel!
    @IBOutlet weak var dataLabel: UILabel!

    @IBOutlet weak var dataBarView: UIView!
    @IBOutlet weak var dataBar: UIView!
    @IBOutlet weak var dataBarTrailingConstraint: NSLayoutConstraint!

    @IBOutlet weak var disclosureStackView: UIStackView!
    @IBOutlet weak var disclosureButton: UIButton!

    private var dataBarMaxWidth: Float = 0.0
    private typealias Style = WPStyleGuide.Stats

    var showSeparator = true {
        didSet {
            separatorLine.isHidden = !showSeparator
        }
    }

    // MARK: - Configure

    override func awakeFromNib() {
        super.awakeFromNib()
        dataBarMaxWidth = Float(dataBarTrailingConstraint.constant)
    }

    func configure(rowData: StatsTotalRowData) {

        configureIcon(rowData)
        configureDataBarWithPercent(rowData.dataBarPercent)

        // Set values
        itemLabel.text = rowData.name
        itemDetailLabel.text = rowData.nameDetail
        dataLabel.text = rowData.data

        // Toggle optionals
        disclosureStackView.isHidden = !rowData.showDisclosure
        disclosureButton.isEnabled = rowData.showDisclosure
        itemDetailLabel.isHidden = (rowData.nameDetail == nil)
        separatorLine.isHidden = !showSeparator

        applyStyles()
    }

}

private extension StatsTotalRow {

    func applyStyles() {
        Style.configureLabelAsCellRowTitle(itemLabel)
        Style.configureLabelItemDetail(itemDetailLabel)
        Style.configureLabelAsData(dataLabel)
        Style.configureViewAsSeperator(separatorLine)
        Style.configureViewAsDataBar(dataBar)
    }

    func configureIcon(_ rowData: StatsTotalRowData) {

        let haveIcon = rowData.icon != nil || rowData.socialIconURL != nil || rowData.userIconURL != nil
        imageStackView.isHidden = !haveIcon

        if let icon = rowData.icon {
            imageWidthConstraint.constant = Constants.defaultImageSize
            imageView.image = icon
        }

        if let iconURL = rowData.socialIconURL {
            imageWidthConstraint.constant = Constants.socialImageSize
            downloadImageFrom(iconURL)
        }

        if let iconURL = rowData.userIconURL {
            imageWidthConstraint.constant = Constants.userImageSize
            imageView.layer.cornerRadius = Constants.userImageSize * 0.5
            imageView.clipsToBounds = true

            // Use placeholder image until real image is loaded.
            imageView.image = Style.gravatarPlaceholderImage()

            downloadImageFrom(iconURL)
        }
    }

    func configureDataBarWithPercent(_ dataBarPercent: Float?) {

        guard let dataBarPercent = dataBarPercent else {
            dataBarView.isHidden = true
            return
        }

        dataBarView.isHidden = false
        let barWidthOffset = dataBarPercent * dataBarMaxWidth
        dataBarTrailingConstraint.constant = CGFloat(dataBarMaxWidth + (dataBarMaxWidth - barWidthOffset))
    }

    func downloadImageFrom(_ iconURL: URL) {
        WPImageSource.shared()?.downloadImage(for: iconURL, withSuccess: { image in
            self.imageView.image = image
        }, failure: { error in
            DDLogInfo("Error downloading image: \(String(describing: error?.localizedDescription)). From URL: \(iconURL).")
            self.imageStackView.isHidden = true
        })
    }

    struct Constants {
        static let defaultImageSize = CGFloat(24)
        static let socialImageSize = CGFloat(20)
        static let userImageSize = CGFloat(28)
    }

    @IBAction func didTapDisclosureButton(_ sender: UIButton) {
        let alertController =  UIAlertController(title: "More will be disclosed.",
                                                 message: nil,
                                                 preferredStyle: .alert)
        alertController.addCancelActionWithTitle("OK")
        alertController.presentFromRootViewController()
    }

}
