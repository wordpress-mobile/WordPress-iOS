import Foundation

class Style: NSObject {
    static var skin = DefaultSkin()
}

public protocol Skin {
    func configureFancyAlertCancelButton(_ cancel: UIButton)
}
