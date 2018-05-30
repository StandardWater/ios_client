//
//  AuthenticationModel.swift
//  StandardWater iOS client
//
//  Created by Grant Broadwater on 5/16/18.
//  Copyright © 2018 StandardWater. All rights reserved.
//

import Foundation
import GoogleSignIn

// Constants
let AUTH_URL = URL(string: "http://standardwater.ddns.net/authenticate")!

class AuthenticationModel {
    
    // Authenticate a users access token
    static func authenticate(token: String, completionHandler: @escaping (Bool, Bool?) -> Void) {
        
        // Form request
        var request = URLRequest(url: AUTH_URL)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        // Completion handler
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            
            // Check for error
            guard error == nil else {
                print(error!)
                DispatchQueue.main.async {
                    completionHandler( false, false );
                }
                return
            }
            
            // Check data is not empty
            guard let _ = data else {
                print("Data is empty")
                DispatchQueue.main.async {
                    completionHandler( false, false );
                }
                return
            }
            
            // Check HTTP Response Status Code
            if let res = response as? HTTPURLResponse {
                
                // Check for accepted response code
                if res.statusCode != 200 {
                    
                    if res.statusCode == 401 /* Unauthorized */ {
                        // Convert data from json
                        var d = [String:AnyObject]()
                        do {
                            d = (try JSONSerialization.jsonObject(with: data!, options: []) as? [String: AnyObject])!
                            
                            let tokenTimeout = d["tkenTimeout"] as! Bool?
                            if let tokenTimeout = tokenTimeout {
                                if tokenTimeout  {
                                    
                                    // Re-sign in
                                    GIDSignIn.sharedInstance().signIn()
                                    
                                    // Call this method with new access token
                                    self.authenticate(
                                        token: GIDSignIn.sharedInstance().currentUser.authentication.accessToken,
                                        completionHandler: completionHandler
                                    )
                                }
                            }
                        } catch {
                            print( error.localizedDescription )
                            DispatchQueue.main.async {
                                completionHandler( false, false );
                            }
                        }
                    }
                    
                    print( "HTTP Response \(res.statusCode)" )
                    DispatchQueue.main.async {
                        completionHandler( false, false );
                    }
                    return
                }
            }
            
            // Convert data from json
            var d = [String:AnyObject]()
            do {
                d = (try JSONSerialization.jsonObject(with: data!, options: []) as? [String: AnyObject])!
            } catch {
                print( error.localizedDescription )
                DispatchQueue.main.async {
                    completionHandler( false, false );
                }
            }
            
            // Get two fields from response
            let isValidGoogleUser = d["isValidGoogleUser"] as! Bool?
            let isValidStandardWaterUser = d["isValidStandardWaterUser"] as! Bool?
            
            // Check field is present
            guard let _ = isValidGoogleUser else {
                print("Could not interprest response")
                DispatchQueue.main.async {
                    completionHandler( false, false );
                }
                return
            }
            
            // Check value is true
            guard isValidGoogleUser! == true else {
                print("Response indicates google user is not valid")
                DispatchQueue.main.async {
                    completionHandler( false, false );
                }
                return
            }
            
            // Check field is present
            guard let _ = isValidStandardWaterUser else {
                print("Could not interprest response")
                DispatchQueue.main.async {
                    completionHandler( false, false );
                }
                return
            }
            
            // Check value is true
            guard isValidStandardWaterUser! == true else {
                print("Response indicates user is not valid")
                DispatchQueue.main.async { 
                    completionHandler( false, false );
                }
                return
            }
            
            // Report user as authenticated
            DispatchQueue.main.async {
                completionHandler( true, d["isAdmin" ] as? Bool );
            }
        }
        
        // Execute async task
        task.resume()
    }
}
