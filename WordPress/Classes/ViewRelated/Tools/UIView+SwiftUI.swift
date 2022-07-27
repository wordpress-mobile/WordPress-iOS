import SwiftUI
import UIKit


extension UIView {
    class func embedSwiftUIView<Content: View>(_ view: Content) -> UIView {
        let controller = UIHostingController(rootView: view)
        controller.view.translatesAutoresizingMaskIntoConstraints = false
        controller.view.backgroundColor = .clear
        return controller.view
    }
}
