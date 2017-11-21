/// A protocol to represent a Flux Action.
///
public protocol Action {}

/// Specialized Dispatcher that broadcasts Actions.
///
public class ActionDispatcher: Dispatcher<Action> {
    /// A shared global dispatcher.
    ///
    public static let global = ActionDispatcher()

    /// Dispatches an action with the given dispatcher, using the global
    /// dispatcher if none is specified.
    ///
    public static func dispatch(_ action: Action, dispatcher: ActionDispatcher = .global) {
        dispatcher.dispatch(action)
    }
}
