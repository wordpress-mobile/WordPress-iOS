import UIKit

class ModalInfoViewController: UIViewController {
    private struct Constants {
        static let cornerRadius: CGFloat = 15.0
    }

    @IBOutlet weak var wrapperView: UIView!
    @IBOutlet weak var headerImageWrapperView: UIView!
    @IBOutlet weak var headerImageView: UIImageView!
    @IBOutlet weak var dividerView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var bodyLabel: UILabel!
    @IBOutlet weak var moreInfoButton: UIButton!
    @IBOutlet weak var titleAccessoryButton: UIButton!
    @IBOutlet weak var buttonStackView: UIStackView!

    static func controller() -> ModalInfoViewController {
        return UIStoryboard(name: "ModalInfo", bundle: Bundle.main).instantiateInitialViewController() as! ModalInfoViewController
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        wrapperView.layer.masksToBounds = true
        wrapperView.layer.cornerRadius = Constants.cornerRadius

        headerImageWrapperView.backgroundColor = WPStyleGuide.lightGrey()
        headerImageView.image = UIImage(named: "wp-illustration-hand-write")

        dividerView.backgroundColor = WPStyleGuide.lightGrey()

        titleLabel.textColor = WPStyleGuide.darkGrey()
        bodyLabel.textColor = WPStyleGuide.greyDarken10()

        titleLabel.text = "Try the New Editor"
        bodyLabel.text = "The WordPress app now includes a beautiful new editor. Try it out by creating a new post!"

        configureBetaButton(titleAccessoryButton)
        titleAccessoryButton.setTitle("Beta", for: .normal)

        moreInfoButton.titleLabel?.font = WPFontManager.systemBoldFont(ofSize: bodyLabel.font.pointSize)
        moreInfoButton.tintColor = WPStyleGuide.wordPressBlue()
        moreInfoButton.setTitle("What's New?", for: .normal)
    }

    func configureBetaButton(_ button: UIButton) {
        button.titleLabel?.font = UIFont.systemFont(ofSize: 11.0)
        button.layer.borderWidth = 1.0
        button.layer.cornerRadius = 3.0

        button.tintColor = WPStyleGuide.darkGrey()
        button.setTitleColor(WPStyleGuide.darkGrey(), for: .disabled)
        button.layer.borderColor = WPStyleGuide.greyLighten20().cgColor

        let verticalInset = CGFloat(6.0)
        let horizontalInset = CGFloat(8.0)
        button.contentEdgeInsets = UIEdgeInsets(top: verticalInset,
                                                left: horizontalInset,
                                                bottom: verticalInset,
                                                right: horizontalInset)
    }
}
