import UIKit
import SwiftUI

extension UIEdgeInsets {
    public init(_ edges: Edge.Set, _ value: CGFloat) {
        self = .zero
        if edges.contains(.top) { self.top = value }
        if edges.contains(.trailing) { self.right = value }
        if edges.contains(.bottom) { self.bottom = value }
        if edges.contains(.leading) { self.left = value }
    }

    public init(horizontal: CGFloat, vertical: CGFloat) {
        self = UIEdgeInsets(top: vertical, left: horizontal, bottom: vertical, right: horizontal)
    }
}
