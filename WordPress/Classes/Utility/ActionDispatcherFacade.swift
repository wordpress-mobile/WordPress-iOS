
import Foundation
import WordPressFlux

/// A class that can be used in lieu of `ActionDispatcher` to test dispatched actions.
///
/// I think it's possible to make either `ActionDispatcher` or `Dispatcher<>` an `open` class
/// so we can mock that in tests. However, current circumstances do not permit us to make this
/// change in WordPressFlux.
class ActionDispatcherFacade {
    private let dispatcher = ActionDispatcher.global

    func dispatch(_ action: Action) {
        dispatcher.dispatch(action)
    }
}
