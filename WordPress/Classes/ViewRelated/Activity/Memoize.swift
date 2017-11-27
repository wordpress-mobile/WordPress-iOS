/// Returns a memoized function.
/// https://medium.com/@mvxlr/swift-memoize-walk-through-c5224a558194
///
/// - Parameters:
///     - function: The function to memoize.
///
func memoizeRecursive<Parameters: Hashable, Result>(function: @escaping ((Parameters) -> Result, Parameters) -> Result) -> (Parameters) -> Result {
    var memo = [Parameters: Result]()

    func wrapper(x: Parameters) -> Result {
        if let value = memo[x] {
            return value
        }
        let value = function(wrapper, x)
        memo[x] = value
        return value
    }

    return wrapper
}
