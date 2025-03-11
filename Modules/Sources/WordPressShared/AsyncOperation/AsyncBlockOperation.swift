public class AsyncBlockOperation: AsyncOperation, @unchecked Sendable {

    private let block: (@escaping () -> Void) -> Void

    public init(block: @escaping (@escaping () -> Void) -> Void) {
        self.block = block
    }

    public override func main() {
        self.block { [weak self] in
            self?.state = .isFinished
        }
    }

}
