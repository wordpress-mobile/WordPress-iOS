import Foundation
import UserNotifications

// MARK: - CodingUserInfoKey

extension CodingUserInfoKey {
    static let richNotificationViewModel = CodingUserInfoKey(rawValue: "richNotificationViewModel")!
}

private extension CodingUserInfoKey {
    static let attributedBody = CodingUserInfoKey(rawValue: "attributedBody")!
    static let attributedSubject = CodingUserInfoKey(rawValue: "attributedSubject")!
    static let gravatarURLString = CodingUserInfoKey(rawValue: "gravatarURLString")!
    static let notificationIdentifier = CodingUserInfoKey(rawValue: "notificationIdentifier")!
    static let notificationReadStatus = CodingUserInfoKey(rawValue: "notificationRead")!
    static let noticonText = CodingUserInfoKey(rawValue: "noticon")!
}

// MARK: - RichNotificationViewModel definition

/// This class serves as the medium of exchange between the service & content extensions.
@objc class RichNotificationViewModel: NSObject, NSSecureCoding {

    // MARK: Properties

    /// The body of a rich notification.
    var attributedBody: NSAttributedString?

    /// The subject of a rich notification.
    var attributedSubject: NSAttributedString?

    /// The URL string of the notification "sender's" Gravatar; `nil` otherwise
    var gravatarURLString: String?

    /// The unique identifier for the notification; `nil` otherwise
    var notificationIdentifier: String?

    /// The notification read status if set; `nil` otherwise
    var notificationReadStatus: Bool?

    /// The "noticon" event label corresponding to the notification type; `nil` otherwise
    var noticon: String?

    // MARK: Initialization

    init(attributedBody: NSAttributedString?,
         attributedSubject: NSAttributedString?,
         gravatarURLString: String?,
         notificationIdentifier: String?,
         notificationReadStatus: Bool?,
         noticon: String?) {

        super.init()

        self.attributedBody = attributedBody
        self.attributedSubject = attributedSubject
        self.gravatarURLString = gravatarURLString
        self.notificationIdentifier = notificationIdentifier
        self.notificationReadStatus = notificationReadStatus
        self.noticon = noticon
    }

    convenience init?(data: Data) {
        do {
            let decoder = try NSKeyedUnarchiver(forReadingFrom: data)
            decoder.requiresSecureCoding = true

            self.init(coder: decoder)

            decoder.finishDecoding()
        } catch {
            return nil
        }
    }

    var data: Data {
        let encoder = NSKeyedArchiver(requiringSecureCoding: true)
        encode(with: encoder)
        encoder.finishEncoding()

        return encoder.encodedData
    }

    // MARK: NSSecureCoding

    static var supportsSecureCoding: Bool {
        return true
    }

    required convenience init?(coder aDecoder: NSCoder) {
        let attributedBodyData = aDecoder.decodeObject(of: NSData.self, forKey: CodingUserInfoKey.attributedBody.rawValue) as Data?
        let attributedBody = RichNotificationViewModel.decodeFromData(attributedBodyData)

        let attributedSubjectData = aDecoder.decodeObject(of: NSData.self, forKey: CodingUserInfoKey.attributedSubject.rawValue) as Data?
        let attributedSubject = RichNotificationViewModel.decodeFromData(attributedSubjectData)

        let gravatarURLString = aDecoder.decodeObject(of: NSString.self, forKey: CodingUserInfoKey.gravatarURLString.rawValue) as String?

        let identifier = aDecoder.decodeObject(of: NSString.self, forKey: CodingUserInfoKey.notificationIdentifier.rawValue) as String?

        let readStatus = aDecoder.decodeObject(of: NSNumber.self, forKey: CodingUserInfoKey.notificationReadStatus.rawValue) as NSNumber?
        let readStatusValue = readStatus?.boolValue ?? false

        let noticon = aDecoder.decodeObject(of: NSString.self, forKey: CodingUserInfoKey.noticonText.rawValue) as String?

        self.init(attributedBody: attributedBody?.copy() as? NSAttributedString,
                  attributedSubject: attributedSubject?.copy() as? NSAttributedString,
                  gravatarURLString: gravatarURLString,
                  notificationIdentifier: identifier,
                  notificationReadStatus: readStatusValue,
                  noticon: noticon)
    }

    func encode(with aCoder: NSCoder) {
        let attributedBodyData = RichNotificationViewModel.encodeToData(attributedBody)
        aCoder.encode(attributedBodyData as NSData?, forKey: CodingUserInfoKey.attributedBody.rawValue)

        let attributedSubjectData = RichNotificationViewModel.encodeToData(attributedSubject)
        aCoder.encode(attributedSubjectData as NSData?, forKey: CodingUserInfoKey.attributedSubject.rawValue)

        aCoder.encode(gravatarURLString, forKey: CodingUserInfoKey.gravatarURLString.rawValue)

        aCoder.encode(notificationIdentifier, forKey: CodingUserInfoKey.notificationIdentifier.rawValue)

        let readStatus = notificationReadStatus ?? false
        aCoder.encode(NSNumber(booleanLiteral: readStatus), forKey: CodingUserInfoKey.notificationReadStatus.rawValue)

        aCoder.encode(noticon, forKey: CodingUserInfoKey.noticonText.rawValue)
    }
}

// MARK: - Encoding / Decoding support for NSAttributedString

private extension RichNotificationViewModel {
    static func decodeFromData(_ value: Data?) -> NSAttributedString? {
        guard let attributedData = value else { return nil }

        let decodingAttributes: [NSAttributedString.DocumentReadingOptionKey: Any] = [
            .documentType: NSAttributedString.DocumentType.html,
            .characterEncoding: String.Encoding.utf8.rawValue
        ]

        return try? NSAttributedString(data: attributedData, options: decodingAttributes, documentAttributes: nil)
    }

    static func encodeToData(_ value: NSAttributedString?) -> Data? {
        guard let validValue = value else {
            return nil
        }

        let range = NSRange(location: 0, length: validValue.length)
        let encodingAttributes: [NSAttributedString.DocumentAttributeKey: Any] = [
            .documentType: NSAttributedString.DocumentType.html
        ]

        guard let attributedData = try? validValue.data(from: range, documentAttributes: encodingAttributes) else {
            return nil
        }
        return attributedData
    }
}
