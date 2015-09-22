import Foundation

class PeopleRemote: ServiceRemoteREST {
    func getTeamFor(siteID: Int, success: People -> (), failure: ErrorType -> ()) {
        let endpoint = "sites/\(siteID)/users"
        let path = pathForEndpoint(endpoint, withVersion: ServiceRemoteRESTApiVersion_1_1)
        let parameters = [
            "number": 50,
            "fields": "ID, nice_name, first_name, last_name, name, avatar_URL, roles, is_super_admin",
        ]

        api.GET(path,
            parameters: parameters,
            success: {
                (operation, responseObject) -> Void in
                let response = responseObject as? [String: AnyObject]
                let users = response.flatMap { return $0["users"] as? [[String: AnyObject]] }
                let people = users!.map {
                    (user: [String: AnyObject]) -> Person in
                    let ID = user["ID"] as! Int
                    let nice_name = user["nice_name"] as! String
                    let first_name = user["first_name"] as? String
                    let last_name = user["last_name"] as? String
                    let name = user["name"] as! String
                    let avatar_URL = (user["avatar_URL"] as? String).flatMap { return NSURL(string: $0)}
                    let roles = user["roles"] as! [String]
//                    let is_super_admin = user["is_super_admin"] as! Bool

                    let role = roles.map({
                        return Person.Role(string: $0)
                    }).sort().first ?? .Unsupported

                    return Person(ID: ID, username: nice_name, firstName: first_name, lastName: last_name, displayName: name, role: role, pending: false, siteID: siteID, avatarURL: avatar_URL)
                }
                success(people)
            },
            failure: {
                (operation, error) -> Void in
                failure(error)
        })
    }
}