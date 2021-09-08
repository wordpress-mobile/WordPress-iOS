import UIKit

// MARK: - WizardNavigation
final class WizardNavigation: GutenbergLightNavigationController {
    private let steps: [WizardStep]
    private let pointer: WizardNavigationPointer

    private lazy var firstContentViewController: UIViewController? = {
        guard let firstStep = self.steps.first else {
            return nil
        }
        return firstStep.content
    }()

    init(steps: [WizardStep]) {
        self.steps = steps
        self.pointer = WizardNavigationPointer(capacity: steps.count)

        guard let firstStep = self.steps.first else {
            fatalError("Navigation Controller was initialized with no steps.")
        }

        let root = firstStep.content
        super.init(rootViewController: root)

        delegate = self.pointer
        configureSteps()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // Navigation Overrides
    override var shouldAutorotate: Bool {
        return WPDeviceIdentification.isiPad() ? true : false
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return WPDeviceIdentification.isiPad() ? .all : .portrait
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .default
    }

    private func configureSteps() {
        for var step in steps {
            step.delegate = self
        }
    }
}

extension WizardNavigation: WizardDelegate {
    func nextStep() {
        guard let nextStepIndex = pointer.nextIndex else {
            // If we find this statement in Fabric, it suggests 11388 might not have been resolved
            DDLogInfo("We've exceeded the max index of our wizard navigation steps (i.e., \(pointer.currentIndex)")
            return
        }

        let nextStep = steps[nextStepIndex]
        let nextViewController = nextStep.content

        // If we find this statement in Fabric, it's likely that we haven't resolved 11388
        if viewControllers.contains(nextViewController) {
            DDLogInfo("Attempting to push \(String(describing: nextViewController.title)) when it's already on the navigation stack!")
        }

        pushViewController(nextViewController, animated: true)
    }
}

final class WizardNavigationPointer: NSObject, UINavigationControllerDelegate {

    private let maxIndex: Int
    private(set) var currentIndex = 0

    init(capacity: Int = 1) {
        self.maxIndex = max(capacity - 1, 0)
    }

    var nextIndex: Int? {
        guard currentIndex < maxIndex else {
            return nil
        }
        return (currentIndex + 1)
    }

    func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
        guard let index = navigationController.viewControllers.firstIndex(of: viewController) else {
            return
        }
        currentIndex = index
    }
}
