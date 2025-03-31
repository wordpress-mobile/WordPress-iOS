import UIKit

extension UIViewController {

    /// Depending on how a VC is presented we need to check different things to know whether it's being dismissed or not.
    /// A VC presented as the first VC in a navigation controller needs to check if the navigation controller is being dismissed.
    /// A VC added to an existing navigation controller is dismissed when `isMovingFromParent` is `true`.
    /// For any other scenario `isBeingDismissed` will do.
    ///
    var isBeingDismissedInAnyWay: Bool {
        isMovingFromParent || isBeingDismissed || (navigationController?.isBeingDismissed ?? false)
    }

    /// Depending on how a VC is presented we need to check different things to know whether it's being presented or not.
    /// A VC presented as the first VC in a navigation controller needs to check if the navigation controller is being presented.
    /// A VC added to an existing navigation controller is presented when `isMovingToParent` is `true`.
    /// For any other scenario `isBeingPresented` will do.
    ///
    var isBeingPresentedInAnyWay: Bool {
        isMovingToParent || isBeingPresented || (navigationController?.isBeingPresented ?? false)
    }
}
