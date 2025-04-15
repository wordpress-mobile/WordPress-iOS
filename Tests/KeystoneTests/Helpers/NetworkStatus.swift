import WordPressShared

func makeNetworkAvailable() {
    ReachabilityUtils.connectionAvailable = true
}

func makeNetworkUnavailable() {
    ReachabilityUtils.connectionAvailable = false
}
