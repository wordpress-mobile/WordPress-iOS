import UIKit

protocol WizardStep {
    // Identifier, in the event we need to convey sequence from the server
    var identifier: Identifier { get }

    /// The localized title we anticipate receiving from the service
    var header: UIViewController { get }

    /// The localized subtitle we anticipate receiving from the service
    var content: UIViewController { get }

    func setWizard(_ wizard : Wizard)
}

final class WizardStepViewController: UIViewController {
    /// The injected WizardStep
    private let step: WizardStep

    required init(step: WizardStep) {
        self.step = step

        super.init(nibName: nil, bundle: nil)
        // Additional customization TBD
    }

    required init(coder decoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
