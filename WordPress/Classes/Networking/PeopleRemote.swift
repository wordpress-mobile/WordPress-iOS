import Foundation

class PeopleRemote: ServiceRemoteREST {
    enum Error: ErrorType {
        case DecodeError
    }
    
    func getTeamFor(siteID  : Int,
                    success : People -> (),
                    failure : ErrorType -> ())
    {
        let endpoint = "sites/\(siteID)/users"
        let path = pathForEndpoint(endpoint, withVersion: ServiceRemoteRESTApiVersion_1_1)
        let parameters = [
            "number": 50,
            "fields": "ID, nice_name, first_name, last_name, name, avatar_URL, roles, is_super_admin",
        ]

        api.GET(path,
            parameters: parameters,
            success: {
                (operation, responseObject) in
                guard let response = responseObject as? [String: AnyObject],
                          people = try? self.peopleFromResponse(response, siteID: siteID) else
                {
                    failure(Error.DecodeError)
                    return
                }

                success(people)
            },
            failure: {
                (operation, error) in
                failure(error)
            })
    }
    
    func updatePersonFor(siteID     : Int,
                         personID   : Int,
                         newRole    : Person.Role,
                         success    : (Person -> ())? = nil,
                         failure    : (ErrorType -> ())? = nil)
    {
        let endpoint = "sites/\(siteID)/users/\(personID)"
        let path = pathForEndpoint(endpoint, withVersion: ServiceRemoteRESTApiVersion_1_1)
        let parameters = ["roles" : [newRole.description]]
        
        api.POST(path,
                parameters: parameters,
                success: {
                    (operation, responseObject) in
                    guard let response = responseObject as? [String: AnyObject],
                              person = try? self.personFromResponse(response, siteID: siteID) else
                    {
                        failure?(Error.DecodeError)
                        return
                    }
                    
                    success?(person)
                },
                failure: {
                    (operation, error) in
                    failure?(error)
                })
    }
}


private extension PeopleRemote {
    private func peopleFromResponse(response: [String: AnyObject], siteID: Int) throws -> People {
        guard let users = response["users"] as? [[String: AnyObject]] else {
            throw Error.DecodeError
        }

        let people = try users.flatMap { (user) -> Person? in
            return try personFromResponse(user, siteID: siteID)
        }
        
        return people
    }
    
    private func personFromResponse(user: [String: AnyObject], siteID: Int) throws -> Person {
        guard let ID = user["ID"] as? Int else {
            throw Error.DecodeError
        }
        
        guard let username = user["nice_name"] as? String else {
            throw Error.DecodeError
        }
        
        guard let displayName = user["name"] as? String else {
            throw Error.DecodeError
        }
        
        let firstName = user["first_name"] as? String
        let lastName = user["last_name"] as? String
        let avatarURL = (user["avatar_URL"] as? String)
            .flatMap { NSURL(string: $0)}
            .flatMap { Gravatar($0)?.canonicalURL }
        
        let isSuperAdmin = user["is_super_admin"] as? Bool ?? false
        let roles = user["roles"] as? [String]
        
        let role = roles?.map({ (role) -> Person.Role in
            return Person.Role(string: role)
        }).sort().first ?? .Unsupported
        
        return Person(ID            : ID,
                      username      : username,
                      firstName     : firstName,
                      lastName      : lastName,
                      displayName   : displayName,
                      role          : role,
                      siteID        : siteID,
                      avatarURL     : avatarURL,
                      isSuperAdmin  : isSuperAdmin)
    }
}
