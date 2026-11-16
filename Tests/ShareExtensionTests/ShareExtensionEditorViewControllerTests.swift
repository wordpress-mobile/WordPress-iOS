import Testing
import UIKit

@MainActor
struct ShareExtensionEditorViewControllerTests {

    /// Shared content can arrive before the first constraints pass. Setting the title then used to crash
    /// because the title's height constraint didn't exist yet (#26248).
    @Test func setTitleBeforeFirstLayoutPass() {
        let viewController = ShareExtensionEditorViewController()
        viewController.loadViewIfNeeded()

        viewController.setTitleText("A shared photo")

        #expect(viewController.titleTextField.text == "A shared photo")
    }

    @Test func repeatedConstraintPassesDoNotAddConstraints() {
        let viewController = ShareExtensionEditorViewController()
        viewController.loadViewIfNeeded()
        let view = viewController.view!

        view.setNeedsUpdateConstraints()
        view.updateConstraintsIfNeeded()
        let count = view.constraints.count

        view.setNeedsUpdateConstraints()
        view.updateConstraintsIfNeeded()

        #expect(view.constraints.count == count)
    }
}
