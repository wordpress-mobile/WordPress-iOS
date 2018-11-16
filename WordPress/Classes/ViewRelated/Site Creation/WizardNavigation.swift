import UIKit

final class WizardNavigation {
    private let steps: [WizardStep]
    private let pointer = WizardNavigationPointer()

    private lazy var navigationController: UINavigationController? = {
        guard let root = self.firstContentViewController else {
            return nil
        }

        let returnValue = UINavigationController(rootViewController: root)
        returnValue.delegate = self.pointer
        return returnValue
    }()

    private lazy var firstContentViewController: UIViewController? = {
        guard let firstStep = self.steps.first else {
            return nil
        }
        return firstStep.content
    }()


    init(steps: [WizardStep]) {
        self.steps = steps
        configureSteps()
    }

    private func configureSteps() {
        for var step in steps {
            step.delegate = self
        }
    }

    lazy var content: UIViewController? = {
        return self.navigationController
    }()
}

extension WizardNavigation: WizardDelegate {
    func nextStep() {
        guard let nextPointer = pointer.next(max: steps.count) else {
            return
        }

        let nextStep = steps[nextPointer]

        navigationController?.pushViewController(nextStep.content, animated: true)
    }
}

final class WizardNavigationPointer: NSObject, UINavigationControllerDelegate {
    private var value: Int = 0

    func next(max: Int) -> Int? {
        guard value < max else {
            return nil
        }

        increaseValue()

        return value
    }

    private func increaseValue() {
        value = value + 1
    }

    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        let viewControllers = navigationController.viewControllers
        if let index = viewControllers.index(of: viewController) {
            value = index
        }
    }
}
