import Foundation
import CoreData

@objc(PageTemplateLayout)
public class PageTemplateLayout: NSManagedObject {

}

extension PageTemplateLayout: Thumbnail {
    var urlDesktop: String? {
        preview
    }

    var urlTablet: String? {
        preview
    }

    var urlMobile: String? {
        preview
    }
}
