
/// Abstracts a Wizard. A Wizard is a sequence of steps, each one represented by a different screen.
protocol Wizard {
    var steps: [WizardStep] { get }
    var content: UIViewController? { get }
}
