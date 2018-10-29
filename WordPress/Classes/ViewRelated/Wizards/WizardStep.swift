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
