import Foundation

/// This class offers a generic mechanism to group closures and execute them.
/// This can be very useful to group together logic that needs to be executed
/// as a result of events.
///
/// As an example: you can have an instance of this class to run code
/// whenever Reachability detects the App is online and whenever the App
/// comes to the foreground.
///
class ClosureGroup {

    /// Just a typealias for readability.
    ///
    typealias Closure = () -> ()

    /// The closures that have been registered.
    ///
    private var closures = [String: Closure]()

    // MARK: - Running the closure group

    /// Runs all registered closures.
    ///
    func run() {
        for (_, closure) in closures {
            closure()
        }
    }

    // MARK: - Registering and Unregistering closures.

    /// Registers a closure for running in this group.
    ///
    func register(identifier: String, closure: @escaping Closure) {
        guard closures[identifier] == nil else {
            assertionFailure("We shouldn't be adding two closures with the same identifier to the same group.")
            return
        }

        closures[identifier] = closure
    }

    /// Unregisters a closure from this group.
    ///
    func unregister(identifier: String) {
        closures.removeValue(forKey: identifier)
    }
}
