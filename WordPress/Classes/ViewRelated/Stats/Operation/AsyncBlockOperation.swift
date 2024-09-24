class AsyncBlockOperation: AsyncOperation, @unchecked Sendable {

    private let block: (@escaping () -> Void) -> Void

    init(block: @escaping (@escaping () -> Void) -> Void) {
        self.block = block
    }

    override func main() {
        self.block { [weak self] in
            self?.state = .isFinished
        }
    }

}
