import UIKit

extension UIViewController {

    /// Sets up a gesture recognizer to make tap gesture close the keyboard
    func setupEditingEndingTapGestureRecognizer() {
        let gestureRecognizer = UITapGestureRecognizer()
        gestureRecognizer.on { [weak self] (gesture) in
            self?.view.endEditing(true)
        }
        gestureRecognizer.cancelsTouchesInView = false
        view.addGestureRecognizer(gestureRecognizer)
    }
}
