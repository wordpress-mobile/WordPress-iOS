public protocol Action {}
extension Action {
    func dispatch(dispatcher: ActionDispatcher = .global) {
        dispatcher.dispatch(self)
    }
}

public class ActionDispatcher: Dispatcher<Action> {
    public static let global = ActionDispatcher()
    public static func dispatch(_ action: Action, dispatcher: ActionDispatcher = .global) {
        dispatcher.dispatch(action)
    }
}
