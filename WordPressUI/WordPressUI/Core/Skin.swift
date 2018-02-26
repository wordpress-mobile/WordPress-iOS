import Foundation

class Skin {
    static var active = DefaultSkin()
    
    init() {
        fatalError("Please instantiate a subclass. This is an abstract class.")
    }

    // Stubs of methods and properties that will need defined in each subclass
}
