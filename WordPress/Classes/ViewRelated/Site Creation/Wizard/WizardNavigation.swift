import UIKit

// MARK: - EnhancedSiteCreationNavigationController

private final class EnhancedSiteCreationNavigationController: GutenbergLightNavigationController {
    override var shouldAutorotate: Bool {
        return WPDeviceIdentification.isiPad() ? true : false
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return WPDeviceIdentification.isiPad() ? .all : .portrait
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        if FeatureFlag.siteCreationHomePagePicker.enabled {
            return .default
        }
        return super.preferredStatusBarStyle
    }
}

// MARK: - WizardNavigation

final class WizardNavigation {
    private let steps: [WizardStep]
    private let pointer: WizardNavigationPointer

    private lazy var navigationController: UINavigationController? = {
        guard let root = self.firstContentViewController else {
            return nil
        }

        let returnValue = EnhancedSiteCreationNavigationController(rootViewController: root)
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
        self.pointer = WizardNavigationPointer(capacity: steps.count)

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
        guard let navigationController = navigationController, let nextStepIndex = pointer.nextIndex else {
            // If we find this statement in Fabric, it suggests 11388 might not have been resolved
            DDLogInfo("We've exceeded the max index of our wizard navigation steps (i.e., \(pointer.currentIndex)")

            return
        }

        let nextStep = steps[nextStepIndex]
        let nextViewController = nextStep.content

        // If we find this statement in Fabric, it's likely that we haven't resolved 11388
        if navigationController.viewControllers.contains(nextViewController) {
            DDLogInfo("Attempting to push \(String(describing: nextViewController.title)) when it's already on the navigation stack!")
        }

        navigationController.pushViewController(nextViewController, animated: true)
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
