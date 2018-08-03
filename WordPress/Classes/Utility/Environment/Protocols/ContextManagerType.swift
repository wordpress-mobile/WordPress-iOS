
protocol ContextManagerType {
    var mainContext: NSManagedObjectContext { get }
    static var shared: ContextManagerType { get }
}

extension ContextManager: ContextManagerType {
    static var shared: ContextManagerType {
        return ContextManager.sharedInstance()
    }
}
