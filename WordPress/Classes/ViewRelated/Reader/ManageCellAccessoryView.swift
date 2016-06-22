import Foundation
import WordPressShared
import Gridicons

typealias ManageCellAccessoryCallback = () -> Void

class ManageCellAccessoryView : UIView
{
    @IBOutlet var manageButton: UIButton!
    @IBOutlet var disclosureImage: UIImageView!

    var onManageTapped: ManageCellAccessoryCallback?


    class func creaateFromNib() -> ManageCellAccessoryView {
        return UINib(nibName: "ManageCellAccessoryView", bundle: nil).instantiateWithOwner(nil, options: nil)[0] as! ManageCellAccessoryView
    }


    override func awakeFromNib() {
        configureButton()
        configureDisclosureImage()
    }


    func configureButton() {
        let title = NSLocalizedString("Manage", comment: "Verb. Button title. Tapping lets the user manage the sites they follow.")
        manageButton.setTitle(title, forState: .Normal)
        manageButton.setTitleColor(WPStyleGuide.wordPressBlue(), forState: .Normal)
        manageButton.setTitleColor(WPStyleGuide.grey(), forState: .Highlighted)
    }


    func configureDisclosureImage() {
        let image = Gridicon.iconOfType(.ChevronRight, withSize: CGSize(width: 20, height: 20))
        disclosureImage.image = image
    }


    @IBAction func handleManageButtonTapped(sender: UIButton) {
        onManageTapped?()
    }

}
