import Foundation

extension UIAlertController {

    typealias AlertHandler = @convention(block) (UIAlertAction) -> Void

    func tap(_ label: String) {
        if let action = actions.first(where: { $0.title == label }) {
            let block = action.value(forKey: "handler")
            let blockPtr = UnsafeRawPointer(Unmanaged<AnyObject>.passUnretained(block as AnyObject).toOpaque())
            let handler = unsafeBitCast(blockPtr, to: AlertHandler.self)
            handler(action)
        }
    }

}
