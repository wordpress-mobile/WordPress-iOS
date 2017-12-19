import Foundation

@objc open class RemotePublicizeService: NSObject {
    @objc open var connectURL = ""
    @objc open var detail = ""
    @objc open var icon = ""
    @objc open var jetpackSupport = false
    @objc open var jetpackModuleRequired = ""
    @objc open var label = ""
    @objc open var multipleExternalUserIDSupport = false
    @objc open var order: NSNumber = 0
    @objc open var serviceID = ""
    @objc open var type = ""
}
