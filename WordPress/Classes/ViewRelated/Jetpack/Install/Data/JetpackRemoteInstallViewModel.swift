class JetpackRemoteInstallViewModel {
    typealias JetpackRemoteInstallOnChangeState = (JetpackRemoteInstallViewState) -> Void

    var onChangeState: JetpackRemoteInstallOnChangeState?

    private var state: JetpackRemoteInstallViewState = .install {
        didSet {
            onChangeState?(state)
        }
    }

    func viewReady() {
        state = .install
    }
}
