import UIKit

extension CircularProgressView {
    func startAnimating() {
        isHidden = false
        state = .indeterminate
    }

    func stopAnimating() {
        isHidden = true
        state = .stopped
    }
}
