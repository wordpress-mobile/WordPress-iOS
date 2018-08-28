func makeNetworkAvailable() {
    if let delegate = UIApplication.shared.delegate as? TestingAppDelegate {
        delegate.connectionAvailable = true
    }
}

func makeNetworkUnavailable() {
    if let delegate = UIApplication.shared.delegate as? TestingAppDelegate {
        delegate.connectionAvailable = false
    }
}
