//
//  UserManager.swift
//  InteroceptionPrototype
//
//  Created by Joel Barker on 20/06/2019.
//  Copyright © 2019 Biobeats. All rights reserved.
//

import UIKit
import Firebase
import SwiftKeychainWrapper

class UserManager: NSObject {

    @objc
    static let shared = UserManager ()
    
    @objc
    static var me:User?
    
    @objc
    static let KEY_UID = "keyUid"
    
    @objc
    func loginOrSignUpAnon (completionClosure: @escaping (_ errorStr: String) ->()) {
        
        if UserDefaults.standard.object(forKey: "firstRun") == nil {
            // Logging.JLog(message: "firstRun")
            
            KeychainWrapper.standard.removeAllKeys()
            
            UserDefaults.standard.set("0", forKey: "firstRun")
        }
        
        //
        
        if let uuid = KeychainWrapper.standard.string(forKey: UserManager.KEY_UID) {
            NSLog ("alreadySignedIn")

            NSLog ("uuid : \(uuid)")
            
            UserDetails.shared.storeAnyValueForKey(key: "isAnonUser", value: false, uid: uuid)
            
            UserDetails.shared.getUsersBlockByUuid(uuid: uuid)
            { (matesGot: Array<User>, errorStr: String) in
                
                
                NSLog ("matesGot : \(matesGot.count)")
                
                if matesGot.count > 0 {
                    UserManager.me = matesGot.first!
                    
                }
                
                completionClosure(errorStr)
                return
            }
        } else {
            // sign-up anon
            self.signInAnon() { (errorStr: String) in
                completionClosure(errorStr)
            }
        }
        
        
    }
    
    @objc
    func signInAnon (completionClosure: @escaping (_ errorStr: String) ->()) {
        
        Auth.auth().signInAnonymously() { (authResult, error) in
            
            if error != nil {
                NSLog("anon sign in error : \(String(describing: error))")
                
                completionClosure(error!.localizedDescription)
                
            } else {
                
                let user = authResult?.user
                let uuid = user?.uid
                
                NSLog("signed up as : \(String(describing: uuid))")
                
                NSLog ("IsSignedIn : \(UserDetails.shared.isSignedIn())")
                
                let _: Bool = KeychainWrapper.standard.set(uuid!, forKey: UserManager.KEY_UID)
                
                let anonUser = User (theUuid: uuid!, userDict: [String:Any] ())
                anonUser.isAnonUser = true
                
                UserDetails.shared.storeAnyValueForKey(key: "isAnonUser", value: true, uid: uuid!)
                
                
                UserManager.me = anonUser
                
               
                
                //
                
                
                
                NSLog("anon user : \(String(describing: uuid))")
                
                completionClosure("")
            }
            
        }
        
    }

    
    func loginOrSignUp (userName: String, passWord: String, completionClosure: @escaping (_ errorStr: String) ->()) {
        
        UserDetails.shared.logUserOut()
        
        KeychainWrapper.standard.removeAllKeys()
        
        NSLog ("userName : \(userName)")
        
        if UserDetails.shared.isSignedIn() {
            NSLog ("alreadySignedIn")
            
            let uuid = UserDetails.shared.getUuid()
            
            NSLog ("uuid : \(uuid)")
            
            UserDetails.shared.storeAnyValueForKey(key: "isAnonUser", value: false, uid: uuid)
            
            UserDetails.shared.getUsersBlockByUuid(uuid: uuid)
            { (matesGot: Array<User>, errorStr: String) in
                
                
                NSLog ("matesGot : \(matesGot.count)")
                
                if matesGot.count > 0 {
                    UserManager.me = matesGot.first!
                    
                }
                
                completionClosure(errorStr)
                return
            }
            
            
        } else {
            
            let email = userName
            //self.signIn(email: email, password: PASSWORD)
            
            self.signIn(email: email, password: passWord) { (errorStr: String, uuid: String) in
                
                NSLog ("errorStr : \(errorStr)")
                
                if errorStr == "loginOK" {
                    
                    UserDetails.shared.storeAnyValueForKey(key: "isAnonUser", value: false, uid: uuid)
                    
                    UserDetails.shared.getUsersBlockByUuid(uuid: uuid)
                    { (matesGot: Array<User>, errorStr: String) in
                        
                        
                        NSLog ("matesGot : \(matesGot.count)")
                        
                        if matesGot.count > 0 {
                            UserManager.me = matesGot.first
                        }
                        
                        completionClosure(errorStr)
                        return
                    }
                }
                
                if errorStr == "There is no user record corresponding to this identifier. The user may have been deleted." {
                    
                    self.doSignUp(email: email, password: passWord) { (errorStr: String, uuid: String) in
                        
                        NSLog ("uuid : \(uuid)")
                        NSLog ("signUpError : \(errorStr)")
                        NSLog ("IsSignedIn : \(UserDetails.shared.isSignedIn())")
                        
                        
                        
                        UserManager.me?.isAnonUser = false
                        UserDetails.shared.storeAnyValueForKey(key: "isAnonUser", value: false, uid: uuid)
                        
                        UserManager.me = User (theUuid: uuid, userDict: [:])
                        
                        
                        completionClosure(errorStr)
                        
                    }
                }
                
                
                
            }
            
        }
        
        
    }
    
    @objc
    func signIn (email: String, password: String, completionClosure: @escaping (_ errorStr: String, _ uuidGot: String) ->()) {
        
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        
        let emailCreds = EmailAuthProvider.credential(withEmail: email, password: password)
        
        Auth.auth().signInAndRetrieveData(with: emailCreds) { (userData, error) in
            
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
            
            if let error = error {
                
                NSLog ("sign in : \(error.localizedDescription)")
                completionClosure(error.localizedDescription, "")
                return
            }
            
            let uuid = UserDetails.shared.getUuid()
            
            let _: Bool = KeychainWrapper.standard.set(uuid, forKey: UserManager.KEY_UID)
            
            NSLog ("logged in ok : uuid : \(uuid)")
            UserManager.me?.uuid = uuid
            
            completionClosure("loginOK", uuid)
            
            //Globals.shared.me?.isAnonUser = false
            
        }
    }
    
    @objc
    func doSignUp (email: String, password: String, completionClosure: @escaping (_ errorStr: String, _ uuid: String) ->()) {
        
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        
        let uuidMade = ""
        
        Auth.auth().createUser(withEmail: email, password: password) { (authResult, error) in
            
            if error != nil {
                NSLog ("signup error : \(String(describing: error?.localizedDescription))")
                
                completionClosure((error?.localizedDescription)!, uuidMade)
                return
            }
            
            let emailCreds = EmailAuthProvider.credential(withEmail: email, password: password)
            
            Auth.auth().signInAndRetrieveData(with: emailCreds) { (userData, error) in
                
                if let error = error {
                    NSLog ("sign in : \(error.localizedDescription)")
                    completionClosure((error.localizedDescription), uuidMade)
                    
                    return
                }
                
                let uuid = UserDetails.shared.getUuid()
                NSLog ("logged in ok : uuid : \(uuid)")
                let _: Bool = KeychainWrapper.standard.set(uuid, forKey: UserManager.KEY_UID)
                
                
                
                completionClosure("signUpOK", uuid)
            }
        }
        
        
    }
    
    @objc
    func fullyLogout () {
        UserDetails.shared.logUserOut()
        KeychainWrapper.standard.removeAllKeys()
    }
    
    
    
}
