class JetpackRemoteInstallViewModel {
    typealias JetpackRemoteInstallOnChangeState = (JetpackRemoteInstallViewState) -> Void

    var onChangeState: JetpackRemoteInstallOnChangeState?

    private(set) var state: JetpackRemoteInstallViewState = .install {
        didSet {
            onChangeState?(state)
        }
    }

    func viewReady() {
        state = .install
    }
}
