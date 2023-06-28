import UIKit

extension CATransaction {

    static func perform(block: () -> Void, completion: @escaping () -> Void) {
        CATransaction.begin()
        CATransaction.setCompletionBlock(completion)
        block()
        CATransaction.commit()
    }
}
