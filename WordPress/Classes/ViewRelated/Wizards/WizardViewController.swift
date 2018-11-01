import UIKit

final class WizardViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .red
    }

    func render(step: WizardStep) {
        print("rendering step with id: ", step.identifier)
    }
}
