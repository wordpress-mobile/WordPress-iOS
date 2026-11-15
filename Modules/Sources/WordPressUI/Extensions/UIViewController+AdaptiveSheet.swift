import UIKit

extension UIViewController {
    /// Presents `viewController` as a form sheet while the window has a regular width, and as a sheet with
    /// `compactDetents` while it has a compact width.
    ///
    /// The style follows the window's size class while the sheet is on screen, for example when an iPad window
    /// is resized or a large iPhone rotates. The compact detents can't stay set in a regular-width window,
    /// because iPad applies detents and the corner radius to form sheets too, which changes their height.
    ///
    /// - Parameters:
    ///   - viewController: The view controller to present.
    ///   - formSheetSize: The size of the form sheet in a regular-width window.
    ///   - compactDetents: The detents of the sheet in a compact-width window.
    ///   - compactCornerRadius: The corner radius of the sheet in a compact-width window, or `nil` for the
    ///     system default.
    ///   - animated: Whether to animate the presentation.
    ///   - completion: A closure to run after the presentation finishes.
    public func presentAdaptiveSheet(
        _ viewController: UIViewController,
        formSheetSize: CGSize,
        compactDetents: [UISheetPresentationController.Detent],
        compactCornerRadius: CGFloat? = nil,
        animated: Bool = true,
        completion: (() -> Void)? = nil
    ) {
        viewController.modalPresentationStyle = .formSheet
        viewController.preferredContentSize = formSheetSize

        guard let sheet = viewController.sheetPresentationController else {
            return present(viewController, animated: animated, completion: completion)
        }

        let configure: (UISheetPresentationController, UIUserInterfaceSizeClass) -> Void = { sheet, sizeClass in
            sheet.configureAdaptiveSheet(
                for: sizeClass,
                compactDetents: compactDetents,
                compactCornerRadius: compactCornerRadius
            )
        }
        // Ask the window: a presenter in a split view column or a form sheet is compact inside a wide window.
        let presentedSizeClass = viewIfLoaded?.window?.traitCollection.horizontalSizeClass
            ?? traitCollection.horizontalSizeClass
        configure(sheet, presentedSizeClass)

        present(viewController, animated: animated) { [weak sheet] in
            // The container view spans the window, so it has the window's size class, while the presented
            // view controller's is compact in a form sheet. It exists only while the sheet is presented.
            if let sheet, let containerView = sheet.containerView {
                if containerView.traitCollection.horizontalSizeClass != presentedSizeClass {
                    sheet.animateChanges { configure(sheet, containerView.traitCollection.horizontalSizeClass) }
                }
                containerView.registerForTraitChanges([UITraitHorizontalSizeClass.self]) {
                    [weak sheet] (containerView: UIView, _) in
                    guard let sheet else { return }
                    sheet.animateChanges { configure(sheet, containerView.traitCollection.horizontalSizeClass) }
                }
            }
            completion?()
        }
    }
}

extension UISheetPresentationController {
    /// Applies the detents and corner radius for a window with the given horizontal size class: the form
    /// sheet's own size in a regular-width window, and `compactDetents` in a compact-width window.
    func configureAdaptiveSheet(
        for windowSizeClass: UIUserInterfaceSizeClass,
        compactDetents: [UISheetPresentationController.Detent],
        compactCornerRadius: CGFloat?
    ) {
        let isRegular = windowSizeClass == .regular
        detents = isRegular ? [.large()] : compactDetents
        preferredCornerRadius = isRegular ? nil : compactCornerRadius
    }
}
