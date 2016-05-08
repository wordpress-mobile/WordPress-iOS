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

                if let people = try? self.peopleFromResponse(responseObject, siteID: siteID) {
                    success(people)
                } else {
                    failure(Error.DecodeError)
                }
            },
            failure: {
                (operation, error) -> Void in
                failure(error)
        })
    }

    private func peopleFromResponse(responseObject: AnyObject, siteID: Int) throws -> People {
        let response = responseObject as? [String: AnyObject]
        let users = response.flatMap { return $0["users"] as? [[String: AnyObject]] }
        guard let unwrappedUsers = users else {
            throw Error.DecodeError
        }

        let people = unwrappedUsers.map {
            (user: [String: AnyObject]) -> Person? in
            guard let ID = user["ID"] as? Int else {
                return nil
            }
            guard let username = user["nice_name"] as? String else {
                return nil
            }
            guard let displayName = user["name"] as? String else {
                return nil
            }

            let firstName = user["first_name"] as? String
            let lastName = user["last_name"] as? String
            let avatarURL = (user["avatar_URL"] as? String)
                .flatMap { NSURL(string: $0)}
                .flatMap { Gravatar($0)?.canonicalURL }
            let isSuperAdmin = user["is_super_admin"] as? Bool ?? false
            let roles = user["roles"] as? [String]

            let role = roles?.map({
                (role: String) -> Person.Role in
                return Person.Role(string: role)
            }).sort().first ?? .Unsupported

            return Person(ID: ID, username: username, firstName: firstName, lastName: lastName, displayName: displayName, role: role, siteID: siteID, avatarURL: avatarURL, isSuperAdmin: isSuperAdmin)
        }

        let errorCount = people.reduce(0) { (sum, person) -> Int in
            if person == nil {
                return sum + 1
            }
            return sum
        }
        if errorCount > 0 {
            throw Error.DecodeError
        }
        return people.flatMap { $0 }
    }

    enum Error: ErrorType {
        case DecodeError
    }
}