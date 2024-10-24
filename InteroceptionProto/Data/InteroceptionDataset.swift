//
//  InteroceptionDataset.swift
//  Interoceptor
//
//  Created by Gabriele Cocco on 10/04/2019.
//  Copyright © 2019 BioBeats. All rights reserved.
//

import Foundation
import SwiftDate

class BaseLineDataset {
    
    var date: Date?
    
    var recordedHR: [Float] = []
    var instantBpms: [Float] = []
    
    func equals (other: BaseLineDataset) -> Bool {
        
        var isEqual = true
        
        if self.date != other.date {
            isEqual = false
        }
        
        if self.recordedHR != other.recordedHR {
            isEqual = false
        }
    
        if self.instantBpms != other.instantBpms {
            isEqual = false
        }
        
        return isEqual
    }
    
    fileprivate static func fromDictionary(dictionary: [String: Any]) -> BaseLineDataset {

        let d = BaseLineDataset()

        if let datas = dictionary["recordedHR"] as? [Float] {
            d.recordedHR = datas
        }
        
        if let datas = dictionary["instantBpms"] as? [Float] {
            d.instantBpms = datas
        }

        if let date = dictionary["date"] as? String {
            
            // Logging.JLog(message: "date : \(date)")
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
            let updatedAt = dateFormatter.date(from: date) // "Jun 5, 2016, 4:56 PM"
            d.date = updatedAt
            
            if updatedAt == nil {
                // Logging.JLog(message: "not parsed...!")
            }
        }
        
        if let date = dictionary["date"] as? Date {
            d.date = date
        }
        return d
    }
    
    fileprivate func toDictionary() -> [String: Any] {
           return [
                    "recordedHR": recordedHR,
                    "instantBpms": instantBpms,
                    "date": date!
           ]
       }
    
    fileprivate func toFirebaseDictionary() -> [String: Any] {
        return [
                 "recordedHR": recordedHR,
                 "instantBpms": instantBpms,
                 "date": date!.toISO()
        ]
    }
    
    fileprivate func toCSV () -> String {
        
        
        //// Logging.JLog(message: "")
        
        let dateFormatter = DateFormatter ()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        
        var s = dateFormatter.string(from: self.date!)  + ";"
        
        s = s + "\n"
        
        s = s + "recordedHR;"
        
        for hr in recordedHR {
            s = s + hr.description + ";"
        }
        
        s = s + "\n"
        
        s = s + "instantBpms;"
        
        for hr in instantBpms {
            s = s + hr.description + ";"
        }
        
        s = s + "\n"
        
        return s
    }
    
}

class SyncroTrialDataset {
    
    var date: Date?
    
    var confidence: Int = -1
    var bodyPos: Int = -1
    
    var recordedHR: [Float] = []
    var instantBpms: [Float] = []
    var instantPeriods: [Double] = []
    var averagePeriods: [Double] = []
    var instantErrs: [Double] = []
    var knobScales: [Double] = []
    var currentDelays: [Double] = []
    
    func equals (other: SyncroTrialDataset) -> Bool {
        
        var isEqual = true
        
        if self.date != other.date {
            isEqual = false
        }
        
        if self.confidence != other.confidence {
            isEqual = false
        }

        if self.bodyPos != other.bodyPos {
            isEqual = false
        }

        if self.recordedHR != other.recordedHR {
            isEqual = false
        }
    
        if self.instantBpms != other.instantBpms {
            isEqual = false
        }
        
        if self.instantPeriods != other.instantPeriods {
            isEqual = false
        }
        
        if self.averagePeriods != other.averagePeriods {
            isEqual = false
        }
        
        if self.instantErrs != other.instantErrs {
            isEqual = false
        }
        
        if self.knobScales != other.knobScales {
            isEqual = false
        }
        
        if self.currentDelays != other.currentDelays {
            isEqual = false
        }
        
        return isEqual
    }
    
    fileprivate static func fromDictionary(dictionary: [String: Any]) -> SyncroTrialDataset {

        let d = SyncroTrialDataset()

        if let datas = dictionary["recordedHR"] as? [Float] {
            d.recordedHR = datas
        }
        
        if let datas = dictionary["instantBpms"] as? [Float] {
            d.instantBpms = datas
        }

        if let datas = dictionary["instantPeriods"] as? [Double] {
            d.instantPeriods = datas
        }

        if let datas = dictionary["averagePeriods"] as? [Double] {
            d.averagePeriods = datas
        }

        if let datas = dictionary["instantErrs"] as? [Double] {
            d.instantErrs = datas
        }

        if let datas = dictionary["knobScales"] as? [Double] {
            d.knobScales = datas
        }

        if let datas = dictionary["currentDelays"] as? [Double] {
            d.currentDelays = datas
        }

        
        if let bodyPos = dictionary["bodyPos"] as? Int {
            d.bodyPos = bodyPos
        }

        
        if let confidence = dictionary["confidence"] as? Int {
            d.confidence = confidence
        }
        
        if let date = dictionary["date"] as? Date {
            d.date = date
        }
        
        if let date = dictionary["date"] as? String {
            
            // Logging.JLog(message: "date : \(date)")
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
            let updatedAt = dateFormatter.date(from: date) // "Jun 5, 2016, 4:56 PM"
            d.date = updatedAt
            
            if updatedAt == nil {
                // Logging.JLog(message: "not parsed...!")
            }
        }
        
        return d
    }
    
    fileprivate func toDictionary() -> [String: Any] {
        return [
                 "recordedHR": recordedHR,
                 "instantBpms": instantBpms,
                 "instantPeriods": instantPeriods,
                 "averagePeriods": averagePeriods,
                 "instantErrs": instantErrs,
                 "knobScales": knobScales,
                 "currentDelays": currentDelays,
                 "confidence": confidence,
                 "bodyPos": bodyPos,
                 "date": date!
        ]
    }
    
    fileprivate func toFirebaseDictionary() -> [String: Any] {
        return [
                 "recordedHR": recordedHR,
                 "instantBpms": instantBpms,
                 "instantPeriods": instantPeriods,
                 "averagePeriods": averagePeriods,
                 "instantErrs": instantErrs,
                 "knobScales": knobScales,
                 "currentDelays": currentDelays,
                 "confidence": confidence,
                 "bodyPos": bodyPos,
                 "date": date!.toISO()
        ]
    }
    
    fileprivate func toCSV () -> String {
        
        let dateFormatter = DateFormatter ()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        
        var s = self.confidence.description + ";" + bodyPos.description + ";" + dateFormatter.string(from: self.date!)  + ";"
        
        s = s + "\n"
        
        s = s + "recordedHR;"
        
        for hr in recordedHR {
            s = s + hr.description + ";"
        }
        
        s = s + "\n"
        
        s = s + "instantBpms;"
        
        for hr in instantBpms {
            s = s + hr.description + ";"
        }
        
        s = s + "\n"
        
        s = s + "instantPeriods;"
        
        for hr in instantPeriods {
            s = s + hr.description + ";"
        }
        
        s = s + "\n"
        
        s = s + "averagePeriods;"
        
        for hr in averagePeriods {
            s = s + hr.description + ";"
        }
        
        s = s + "\n"
        
        s = s + "instantErrs;"
        
        for hr in instantErrs {
            s = s + hr.description + ";"
        }
        
        s = s + "\n"
        
        s = s + "knobScales;"
        
        for hr in knobScales {
            s = s + hr.description + ";"
        }
        
        s = s + "\n"
        
        s = s + "currentDelays;"
        
        for hr in currentDelays {
            s = s + hr.description + ";"
        }
        
        s = s + "\n"
        
        return s
    }
    
}

class HRGatherDataset {
    var samples: [Double] = []
    var date: Date?
    
    fileprivate static func fromDictionary(dictionary: [String: Any]) -> HRGatherDataset {
        let d = HRGatherDataset()
        if let s = dictionary["samples"] as? [Double] {
            d.samples = s
        }
        if let date = dictionary["date"] as? Date {
            d.date = date
        }
        return d
    }
    
    fileprivate func toDictionary() -> [String: Any] {
        return [ "samples": samples,
                 "date": date! ]
    }
    
    fileprivate func toFirebaseDictionary() -> [String: Any] {
        return [ "samples": samples,
                 "date": date!.toISO() ]
    }
}

class HDTRunDataset {
    var delayed: Bool = false
    var guessedDelayed: Bool = false
    var confidence: Float = 0
    var recordedRR: [Double] = []
    var date: Date?
    
    fileprivate static func fromDictionary(dictionary: [String: Any]) -> HDTRunDataset {
        let d = HDTRunDataset()
        if let delayed = dictionary["delayed"] as? Bool {
            d.delayed = delayed
        }
        if let guessed = dictionary["guessedDelayed"] as? Bool {
            d.guessedDelayed = guessed
        }
        if let recorded = dictionary["recordedRR"] as? [Double] {
            d.recordedRR = recorded
        }
        if let conf = dictionary["confidence"] as? Float {
            d.confidence = conf
        }
        if let date = dictionary["date"] as? Date {
            d.date = date
        }
        return d
    }
    
    fileprivate func toDictionary() -> [String: Any] {
        return [ "delayed": delayed,
                 "guessedDelayed" : guessedDelayed,
                 "recordedRR": recordedRR,
                 "confidence": confidence,
                 "date": date! ]
    }
    
    fileprivate func toFirebaseDictionary() -> [String: Any] {
        return [ "delayed": delayed,
                 "guessedDelayed" : guessedDelayed,
                 "recordedRR": recordedRR,
                 "confidence": confidence,
                 "date": date!.toISO() ]
    }
}

class InteroceptionDataset {

    var participantID: String
    var uuid: String

    var startDate: Date
    var endDate: Date?
    
    var numRuns:Int?
    
    var baselines: [BaseLineDataset] = []
    
    var baselineRR: [HRGatherDataset] = []
    var postTrainingRR: [HRGatherDataset] = []
    var baselineHDT: [HDTRunDataset] = []
    var postTrainingHDT: [HDTRunDataset] = []

    var postSyncroTraining: [HDTRunDataset] = []

    var syncroTraining: [SyncroTrialDataset] = []
    
    init(date: Date? = nil) {
        self.participantID = ""
        self.uuid = ""
        startDate = (date != nil) ? date! : Date()
    }
    
    init(participant: String, date: Date? = nil) {
        participantID = participant
        self.uuid = ""

        startDate = (date != nil) ? date! : Date()
    }
    
    static func wipePreviousData () {
        
        UserDefaults.standard.removeObject(forKey: "dataset")
    }
    
    static func hasPreviousData () -> Bool {
        
        if let d = UserDefaults.standard.object(forKey: "dataset") as? [String : Any] {
            return true
        }
        
        return false
    }
    
    static func load() -> InteroceptionDataset? {
        if let d = UserDefaults.standard.object(forKey: "dataset") as? [String : Any] {
            return InteroceptionDataset.fromDictionary(dictionary: d)
        }
        return nil
    }
    
    static func load(fromDict: NSDictionary) -> InteroceptionDataset?  {
        
        var partiId = ""
        
        var dataDict = [String:Any] ()
        
        for (key, itemVals) in fromDict {
            
            partiId = key as! String
            
            // Logging.JLog(message: "itemVals : \(itemVals)")
            
            let itemDict = itemVals as! NSDictionary
            
            for (itemDictKey, itemDictVals) in itemDict {
                
                let itemDictKeyStr = itemDictKey as! String
                
                // Logging.JLog(message: "itemDictKey : \(itemDictKey)")
                dataDict [itemDictKeyStr] = itemDictVals
            }
        }
        
        // Logging.JLog(message: "partiId : \(partiId)")
        
        return InteroceptionDataset.fromDictionary(dictionary: dataDict)
 
    }
    
    func toCSV () -> String {
        
        let dateFormatter = DateFormatter ()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        
        var s = self.participantID + ";"
        s = s + dateFormatter.string(from: self.startDate)  + ";"
        
        if self.endDate != nil {
            s = s + dateFormatter.string(from: self.endDate!)  + ";"
        }
        
        if self.numRuns != nil {
            s = s + numRuns!.description + ";"
        } else {
            s = s + "0;"
        }
        
        s = s + self.uuid + ";"
        
        s = s + "\n"
        
        // TODO : Add the other tasks
        
        if self.baselines.count > 0 {
            
            s = s + "BASELINE;\n"
            
            for syncTrain in self.baselines {
                s = s + syncTrain.toCSV()
                s = s + "\n"
            }
        }
        
        if self.syncroTraining.count > 0 {
            
            s = s + "SYNCRO;\n"
            
            for syncTrain in self.syncroTraining {
                s = s + syncTrain.toCSV()
                s = s + "\n"
            }
            
        }

        return s
    }
    
    func storeWithCompletion (completionClosure: @escaping (_ errorStr: String) ->()) {
        
        let dataAsDict = self.toFirebaseDictionary()
        
        let uuid = UserManager.me?.uuid
        
        // Logging.JLog(message: "uuid : \(String(describing: uuid))")
        
        self.store()
        
        UserDetails.shared.storeAnyValueForKeyWithCompl(key: participantID, value: dataAsDict, uid: uuid!) {(errorStr: Error?) in
            
            if errorStr != nil {
                completionClosure (errorStr!.localizedDescription)
            } else {
                completionClosure ("")
            }
        }
        
    }
    
    func store() {
        
        let dataDict = self.toDictionary()
        
        /*
        if UserManager.me != nil {
            
            let uuid = UserManager.me?.uuid
            
            // Logging.JLog(message: "storing for uuid : \(String(describing: uuid))")
            
            UserDetails.shared.storeAnyValueForKeyWithCompl(key: "incData", value: dataDict, uid: uuid!) { (errorStr: String) in
                
                // Logging.JLog(message: "itemsStoredWithError : \(errorStr)")
            }

        }*/
        
        // Logging.JLog(message: "dataDict")
        print (dataDict)
        
        UserDefaults.standard.set(dataDict, forKey: "dataset")
        UserDefaults.standard.synchronize()
    }
    
    fileprivate static func fromDictionary(dictionary: [String: Any]) -> InteroceptionDataset {
        let d = InteroceptionDataset(participant: dictionary["participantID"] as! String, date: dictionary["startDate"] as? Date)
        
        // Logging.JLog(message: "dictionary")
        print (dictionary)
        
        if let baselineRR = dictionary["baselineRR"] as? [[String: Any]] {
            d.baselineRR = baselineRR.map({ (d) -> HRGatherDataset in
                HRGatherDataset.fromDictionary(dictionary: d)
            })
        }
        if let baselineHDT = dictionary["baselineHDT"] as? [[String: Any]] {
            d.baselineHDT = baselineHDT.map({ (d) -> HDTRunDataset in
                HDTRunDataset.fromDictionary(dictionary: d)
            })
        }
        if let postTrainingRR = dictionary["postTrainingRR"] as? [[String: Any]] {
            d.postTrainingRR = postTrainingRR.map({ (d) -> HRGatherDataset in
                HRGatherDataset.fromDictionary(dictionary: d)
            })
        }
        if let postTrainingHDT = dictionary["postTrainingHDT"] as? [[String: Any]] {
            d.postTrainingHDT = postTrainingHDT.map({ (d) -> HDTRunDataset in
                HDTRunDataset.fromDictionary(dictionary: d)
            })
        }
        
        if let baselines = dictionary["baselines"] as? [[String: Any]] {
            d.baselines = baselines.map({ (d) -> BaseLineDataset in
                BaseLineDataset.fromDictionary(dictionary: d)
            })
        }
        
        if let syncroTraining = dictionary["syncroTraining"] as? [[String: Any]] {
            d.syncroTraining = syncroTraining.map({ (d) -> SyncroTrialDataset in
                SyncroTrialDataset.fromDictionary(dictionary: d)
            })
        }
        
        

        if let numRuns = dictionary["numRuns"] as? Int {
            d.numRuns = numRuns
        }

        
        if let date = dictionary["endDate"] as? Date {
            d.endDate = date
        }
        return d
    }

    func toFirebaseDictionary() -> [String: Any] {
        
        var d = [ "participantID": participantID,
                  "startDate": startDate.toISO() ] as [String : Any]

        if let ed = endDate {
            d["endDate"] = ed.toISO()
        }
        
        d["numRuns"] = numRuns
        
        d["uuid"] = self.uuid
        
        d["baselineRR"] = baselineRR.map({ (t) -> [String: Any] in
            t.toFirebaseDictionary()
        })
        d["baselineHDT"] = baselineHDT.map({ (t) -> [String: Any] in
            t.toFirebaseDictionary()
        })
        d["postTrainingRR"] = postTrainingRR.map({ (t) -> [String: Any] in
            t.toFirebaseDictionary()
        })
        d["postTrainingHDT"] = postTrainingHDT.map({ (t) -> [String: Any] in
            t.toFirebaseDictionary()
        })
        
        d["baselines"] = baselines.map({ (t) -> [String: Any] in
            t.toFirebaseDictionary()
        })
        
        d["syncroTraining"] = syncroTraining.map({ (t) -> [String: Any] in
            t.toFirebaseDictionary()
        })
        
        // Logging.JLog(message: "d : \(d)")
        
        return d
        
    }

    
    func toDictionary() -> [String: Any] {
        
        // Logging.JLog(message: "participantID : \(self.participantID)")
        
        var d = [ "participantID": participantID,
                  "startDate": startDate ] as [String : Any]

        if let ed = endDate {
            d["endDate"] = ed
        }
        
        d["numRuns"] = numRuns
        
        d["baselineRR"] = baselineRR.map({ (t) -> [String: Any] in
            t.toDictionary()
        })
        d["baselineHDT"] = baselineHDT.map({ (t) -> [String: Any] in
            t.toDictionary()
        })
        d["postTrainingRR"] = postTrainingRR.map({ (t) -> [String: Any] in
            t.toDictionary()
        })
        d["postTrainingHDT"] = postTrainingHDT.map({ (t) -> [String: Any] in
            t.toDictionary()
        })
        
        d["baselines"] = baselines.map({ (t) -> [String: Any] in
            t.toDictionary()
        })
        
        d["syncroTraining"] = syncroTraining.map({ (t) -> [String: Any] in
            t.toDictionary()
        })
        
        // Logging.JLog(message: "d : \(d)")
        
        return d
    }
}
