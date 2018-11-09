import UIKit

protocol WizardStep {
    static var identifier: Identifier { get }
    // Identifier
    var identifier: Identifier { get }

    /// The UIViewController rendering the step content
    var content: UIViewController { get }

    /// Delegate
    var delegate: WizardDelegate? { get set }
}

extension WizardStep {
    static var identifier: Identifier {
        return Identifier(value: String(describing: self))
    }

    var identifier: Identifier {
        return type(of: self).identifier
    }
}
