import AutomatticTracks
import Foundation

class AuthenticationService {
    
    static let wpComLoginEndpoint = "https://wordpress.com/wp-login.php"
    
    func getAuthCookiesForSelfHosted(
        username: String,
        password: String,
        success: @escaping (_ cookies: [HTTPCookie]) -> Void,
        failure: @escaping (Error) -> Void) {
        
        // We don't want these cookies loaded onto all of our requests
        let session = URLSession(configuration: .ephemeral)
        
        let endpoint = "https://wordpress.com/wp-login.php"
        let url = URL(string: endpoint)!
        var request = URLRequest(url: url)
        
        request.httpBody = body(withParameters: [
            "log": username,
            "rememberme": "true"
        ])
        
        let task = session.dataTask(with: request) { data, response, error in
            if let error = error {
                failure(error)
                return
            }
            
            let cookies = session.configuration.httpCookieStorage?.cookies ?? [HTTPCookie]()
            success(cookies)
        }
        
        task.resume()
        
        /*
         wordPressComRestApi.GET(path,
         parameters: nil,
         success: {
         responseObject, httpResponse in
         
         do {
         let settings = try self.cookie(from: responseObject)
         success(settings)
         } catch {
         failure(error)
         }
         },
         failure: { error, httpResponse in
         failure(error)
         })
         
         
         var request = URLRequest(url: loginURL)
         request.httpMethod = "POST"
         request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
         request.httpBody = body(url: url)
         if let authToken = authToken {
         request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
         }
         return request
         */
    }
    
    func loadAuthCookiesForWPCom(
        into cookieJar: CookieJar,
        username: String,
        authToken: String,
        success: @escaping () -> Void,
        failure: @escaping (Error) -> Void) {
        
        cookieJar.hasWordPressComCookie(
            username: username,
            atomicSite: false) { [weak self] hasCookie in
                
                guard let self = self else {
                    return
                }
                
                guard !hasCookie else {
                    success()
                    return
                }
                
                self.getAuthCookiesForWPCom(username: username, authToken: authToken, success: { cookies in
                    cookieJar.setCookies(cookies) {
                        success()
                    }
                }) { error in
                    // Make sure this error scenario isn't silently ignored.
                    CrashLogging.logError(error)
                   
                    // Even if getting the auth cookies fail, we'll still try to load the URL
                    // so that the user sees a reasonable error situation on screen.
                    // We could opt to create a special screen but for now I'd rather users report
                    // the issue when it happens.
                    failure(error)
                }
        }
    }
    
    func getAuthCookiesForWPCom(
        username: String,
        authToken: String,
        success: @escaping (_ cookies: [HTTPCookie]) -> Void,
        failure: @escaping (Error) -> Void) {
        
        // We don't want these cookies loaded onto all of our requests
        let session = URLSession(configuration: .ephemeral)
        
        let endpoint = AuthenticationService.wpComLoginEndpoint
        let url = URL(string: endpoint)!
        var request = URLRequest(url: url)
        
        request.httpBody = body(withParameters: [
            "log": username,
            "rememberme": "true"
        ])
        
        let task = session.dataTask(with: request) { data, response, error in
            if let error = error {
                failure(error)
                return
            }
            
            let cookies = session.configuration.httpCookieStorage?.cookies ?? [HTTPCookie]()
            success(cookies)
        }
        
        task.resume()
        
        /*
         wordPressComRestApi.GET(path,
         parameters: nil,
         success: {
         responseObject, httpResponse in
         
         do {
         let settings = try self.cookie(from: responseObject)
         success(settings)
         } catch {
         failure(error)
         }
         },
         failure: { error, httpResponse in
         failure(error)
         })
         
         
         var request = URLRequest(url: loginURL)
         request.httpMethod = "POST"
         request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
         request.httpBody = body(url: url)
         if let authToken = authToken {
         request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
         }
         return request
         */
    }
    
    // MARK - Request Construction
    
    private func body(withParameters parameters: [String: String]) -> Data? {
        var queryItems = [URLQueryItem]()
        
        for parameter in parameters {
            let queryItem = URLQueryItem(name: parameter.key, value: parameter.value)
            queryItems.append(queryItem)
        }
        
        var components = URLComponents()
        components.queryItems = queryItems

        return components.percentEncodedQuery?.data(using: .utf8)
        
        /*
        parameters.append(URLQueryItem(name: "log", value: username))
        if let password = password {
            parameters.append(URLQueryItem(name: "pwd", value: password))
        }
        parameters.append(URLQueryItem(name: "rememberme", value: "true"))
        parameters.append(URLQueryItem(name: "redirect_to", value: redirectedUrl))
        var components = URLComponents()
        components.queryItems = parameters

        return components.percentEncodedQuery?.data(using: .utf8)*/
    }
    /*
    private func body(username: String, password: String) -> Data? {
        var parameters = [URLQueryItem]()
        parameters.append(URLQueryItem(name: "log", value: username))
        if let password = password {
            parameters.append(URLQueryItem(name: "pwd", value: password))
        }
        parameters.append(URLQueryItem(name: "rememberme", value: "true"))
        parameters.append(URLQueryItem(name: "redirect_to", value: redirectedUrl))
        var components = URLComponents()
        components.queryItems = parameters

        return components.percentEncodedQuery?.data(using: .utf8)
    }
 */
}
