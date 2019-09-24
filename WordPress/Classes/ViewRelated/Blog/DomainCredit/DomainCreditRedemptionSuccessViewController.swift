import UIKit

protocol DomainCreditRedemptionSuccessViewControllerDelegate: class {
    func continueButtonPressed()
}

/// Displays messaging after user successfully redeems domain credit.
class DomainCreditRedemptionSuccessViewController: UIViewController {
    private let domain: String

    private weak var delegate: DomainCreditRedemptionSuccessViewControllerDelegate?

    init(domain: String, delegate: DomainCreditRedemptionSuccessViewControllerDelegate) {
        self.domain = domain
        self.delegate = delegate
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        let attributedSubtitleConfiguration: NoResultsViewController.AttributedSubtitleConfiguration = {
            [weak self] attributedText in
            guard let domain = self?.domain else {
                return nil
            }
            return self?.applyDomainStyle(to: attributedText, domain: domain)
        }
        let controller = NoResultsViewController.controllerWith(title: NSLocalizedString("Congratulations", comment: "Title on domain credit redemption success screen"),
                                                                buttonTitle: NSLocalizedString("Continue", comment: "Action title to dismiss domain credit redemption success screen"),
                                                                attributedSubtitle: generateDomainDetailsAttributedString(domain: domain),
                                                                attributedSubtitleConfiguration: attributedSubtitleConfiguration,
                                                                image: "wp-illustration-domain-credit-success")
        controller.delegate = self
        addChild(controller)
        view.addSubview(controller.view)
        controller.didMove(toParent: self)
    }

    private func applyDomainStyle(to attributedString: NSAttributedString, domain: String) -> NSAttributedString? {
        let newAttributedString = NSMutableAttributedString(attributedString: attributedString)
        let range = (newAttributedString.string as NSString).localizedStandardRange(of: domain)
        guard range.location != NSNotFound else {
            return nil
        }
        let font = WPStyleGuide.fontForTextStyle(.body, fontWeight: .semibold)
        newAttributedString.setAttributes([.font: font, .foregroundColor: UIColor.text],
                                          range: range)
        return newAttributedString
    }

    private func generateDomainDetailsAttributedString(domain: String) -> NSAttributedString {
        let string = String(format: NSLocalizedString("your new domain %@ is being set up. Your site is doing somersaults in excitement!", comment: "Details about recently acquired domain on domain credit redemption success screen"), domain)
        let attributedString = NSMutableAttributedString(string: string)
        return attributedString
    }
}

extension DomainCreditRedemptionSuccessViewController: NoResultsViewControllerDelegate {
    func actionButtonPressed() {
        delegate?.continueButtonPressed()
    }
}
