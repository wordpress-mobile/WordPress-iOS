public class Dispatcher: GenericDispatcher<Action> {
    public static let global = Dispatcher()

    public static func dispatch(_ action: Action, dispatcher: Dispatcher = .global) {
        dispatcher.dispatch(action)
    }
}
