import Foundation

/// An WordPressRSDParser is able to parse an RSD file and search for the XMLRPC WordPress url.
public class WordPressRSDParser: NSObject, NSXMLParserDelegate {

    private let parser: NSXMLParser
    private var endpoint: String?

    init?(xmlString:String) {
        guard let data = xmlString.dataUsingEncoding(NSUTF8StringEncoding) else {
            return nil
        }
        parser = NSXMLParser(data: data)
        super.init()
        parser.delegate = self
    }


    func parsedEndpoint() throws -> String? {
        if parser.parse() {
            return endpoint
        }
        guard let error = parser.parserError else {
            return nil
        }
        throw error
    }

    //MARK: - NSXMLParserDelegate
    public func parser(parser: NSXMLParser,
                didStartElement elementName: String,
                                namespaceURI: String?,
                                qualifiedName qName: String?,
                                              attributes attributeDict: [String : String]) {
        if elementName == "api" {
            if let apiName = attributeDict["name"] where apiName == "WordPress" {
                if let endpoint = attributeDict["apiLink"] {
                    self.endpoint = endpoint
                } else {
                    parser.abortParsing()
                }
            }
        }
    }

    public func parser(parser: NSXMLParser, parseErrorOccurred parseError: NSError) {
        DDLogSwift.logInfo("Error parsing RSD: \(parseError)")
    }

}
