public protocol Action {}

public class ActionDispatcher: Dispatcher<Action> {
    public static let global = ActionDispatcher()
    public static func dispatch(_ action: Action, dispatcher: ActionDispatcher = .global) {
        dispatcher.dispatch(action)
    }
}
