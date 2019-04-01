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

extension JetpackRemoteInstallViewModel {
    func testState(_ index: Int) {
        switch index {
        case 0:
            state = .install
        case 1:
            state = .installing
        case 2:
            state = .success
        case 3:
            state = .failure(.unknown)
        default:
            return
        }
    }
}
