@_exported import WordPressKitModels
@_exported import WordPressKitObjC
@_exported import WordPressKitObjCUtils

extension ServiceRemoteWordPressComREST {
    public var wordPressComRestApi: WordPressComRestApi {
        self.wordPressComRESTAPI as! WordPressComRestApi
    }
}

extension ServiceRemoteWordPressXMLRPC {
    public var xmlrpcApi: WordPressOrgXMLRPCApi {
        self.api as! WordPressOrgXMLRPCApi
    }
}
