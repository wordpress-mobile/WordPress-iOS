import UIKit

protocol WizardStep {
    // Identifier
    var identifier: Identifier { get }

    /// The UIViewController rendering the step header
    var header: UIViewController { get }

    /// The UIViewController rendering the step content
    var content: UIViewController { get }

    /// Delegate
    var delegate: WizardDelegate? { get set }
}
