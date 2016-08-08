protocol NamedManagedObject {
    static func entityName() -> String
}

extension NamedManagedObject {

    // NSStringFromClass([MyClass class]) isn't as clean in swift, without using @objc(MyClass)
    public class var entityName:String {
        get {
            return NSStringFromClass(self).componentsSeparatedByString(".").last!
        }
    }
    
}

extension AbstractPost: NamedManagedObject {}