/// TODO: Move the app-wide Notice API into a shared module and remove this bridge.
@MainActor
public protocol NoticePresenting {
    func present(title: String)
}
