
extension CircularProgressView: ActivityIndicatorType {
    func startAnimating() {
        isHidden = false
        state = .indeterminate
    }

    func stopAnimating() {
        isHidden = true
        state = .stopped
    }
}
