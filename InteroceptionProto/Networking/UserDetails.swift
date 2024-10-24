//
//  UserDetails.swift
//  InteroceptionPrototype
//
//  Created by Joel Barker on 20/06/2019.
//  Copyright © 2019 Biobeats. All rights reserved.
//

import UIKit
import Firebase

class UserDetails: NSObject {

    @objc
    var ref:DatabaseReference? = nil
    
    @objc
    static let shared = UserDetails ()
    
    @objc
    func isSignedIn () -> Bool {
        let user = Auth.auth().currentUser
        
        if user == nil {
            return false
        }
        
        if !(user?.isAnonymous)! {
            return true
        }
        
        return false
    }
    
    @objc
    func getUuid () -> String {
        
        let user = Auth.auth().currentUser
        return (user?.uid)!
    }
    
    @objc
    func getUsersBlockByUuid (uuid:String, completionClosure: @escaping (_ users :Array<User>, _ errorStr: String) ->()) {
        
        // FIXME : this is sometimes empty
        NSLog ("getUuid : \(uuid)")
        
        var uuidFind = uuid
        
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        
        if uuid == nil || uuid == "" {
            NSLog ("empty uuid")
            uuidFind = "EMPTYUUID"
        }
        
        
        self.ref = Database.database().reference(withPath: "users")
        
        let thisUserOnly = self.ref?.child(uuidFind)
        
        
        var users = [User] ()
        
        
        thisUserOnly?.observeSingleEvent(of: .value, with: { snapshot in
            //thisUserOnly?.observe(.value, with: { snapshot in
            
            NSLog ("getUsersBlockByUuid : data : \(snapshot)")
            
            let vals = snapshot.value as? NSDictionary?
            
            NSLog ("uuid : \(uuid)")
            
            var errorStr = ""
            
            if vals != nil {
                let user = User (theUuid: uuid, userDict: vals as! Dictionary<String, Any>)
                
                users.append(user)
            } else {
                errorStr = "user not found : " + uuidFind
            }
            
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
            completionClosure(users, errorStr)
        })
        
        
    }
    
    @objc
    func storeAnyValueForKey (key: String, value: Any, uid: String) {
        
        NSLog ("storing : key : \(key), value : \(value), for uid : \(uid)")
        
        let user = Auth.auth().currentUser
        
        self.ref =  Database.database().reference(withPath: "users")
        let thisUserOnly = self.ref?.child(uid)
        
        
        //thisUserOnly?.up
        
        thisUserOnly?.updateChildValues([key: value])
        
        
    }
    
    @objc
    func storeAnyValueForKeyWithCompl (key: String, value: Any, uid: String, completionClosure: @escaping (_ errorStr: Error?) ->()) {
        
        // Logging.JLog(message: "storing : key : \(key), value : \(value), for uid : \(uid)")
        
        var keyUse = key.replacingOccurrences(of: ".", with: "")
        keyUse = key.replacingOccurrences(of: "#", with: "")
        keyUse = key.replacingOccurrences(of: "$", with: "")
        keyUse = key.replacingOccurrences(of: "[", with: "")
        keyUse = key.replacingOccurrences(of: "]", with: "")


        // Logging.JLog(message: "keyUse")
        
        self.ref =  Database.database().reference(withPath: "studies")
        let thisUserOnly = self.ref?.child("murphyphdstudent1").child(uid)
        
        
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        
        thisUserOnly?.updateChildValues ([keyUse: value]) {
            (error:Error?, ref:DatabaseReference) in
            
            // back to main for the ui
            DispatchQueue.main.async { [unowned self] in
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
            }
            
            if let error = error {
                // Logging.JLog(message: "Data could not be saved: \(error).")
                completionClosure (error)
                
            } else {
                // Logging.JLog(message: "Data saved successfully!")
                completionClosure (error)
            }
        }

        
        
        
    }
    
    
    @objc
    func logUserOut () {
        
        do{
            try Auth.auth().signOut()
        }catch{
            print("Error while signing out!")
        }
    }
    
    func getAllUuids (completionClosure: @escaping (_ uuids :[String : InteroceptionDataset], _ errorStr: String) ->()) {

        self.ref = Database.database().reference(withPath: "studies/murphyphdstudent1")
        
        var users = [String : InteroceptionDataset] ()
        
        let thisUserOnly = self.ref
        
        thisUserOnly?.observeSingleEvent(of: .value, with: { snapshot in
            
            var uuidsGot = [String : InteroceptionDataset] ()
            
            let vals = snapshot.value as? NSDictionary?
            
            for (key, itemVals) in vals!! {
                
                
                let keyStr = key as! String
                let itemDict = itemVals as! NSDictionary
                
                // Logging.JLog(message: "keyStr : \(keyStr)")
                
                let dataDict = InteroceptionDataset.load(fromDict: itemDict)
                
                uuidsGot [keyStr] = dataDict
                
                // Logging.JLog(message: "dataDict : \(dataDict)")
                
                //uuidsGot.append(keyStr)
            }
            
            
            
            //// Logging.JLog(message: "vals : \(vals)")
            
            completionClosure (uuidsGot, "")
            
        })
        
    }
    
}
