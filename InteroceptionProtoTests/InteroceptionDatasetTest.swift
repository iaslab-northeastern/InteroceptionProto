//
//  InteroceptionDatasetTest.swift
//  InteroceptionProtoTests
//
//  Created by Joel Barker on 11/02/2020.
//  Copyright © 2020 BioBeats. All rights reserved.
//

import XCTest

class InteroceptionDatasetTest: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        
        let dataSet = InteroceptionDataset ()
        
        InteroceptionDataset.wipePreviousData ()
        XCTAssert(!InteroceptionDataset.hasPreviousData())
        
        let runNum = Int.random(in: 0 ..< 100)
        
        dataSet.participantID = "joel" + runNum.description
        
        
        let numValues = 1
        let numItems = 5
        
        // Syncro
        for _ in 0...numValues {
            
            let recordedHR = self.makeRandomFloatArray(numValues: numItems)
            let instantBpms = self.makeRandomFloatArray(numValues: numItems)
            let instantPeriods = self.makeRandomDoubleArray(numValues: numItems)
            let averagePeriods = self.makeRandomDoubleArray(numValues: numItems)
            let instantErrs = self.makeRandomDoubleArray(numValues: numItems)
            let knobScales = self.makeRandomDoubleArray(numValues: numItems)
            let currentDelays = self.makeRandomDoubleArray(numValues: numItems)
            
            let syncroSet = SyncroTrialDataset ()
            
            syncroSet.date = Date ()
            
            syncroSet.confidence = Int.random(in: 0 ..< 100)
            syncroSet.bodyPos = Int.random(in: 0 ..< 100)

            syncroSet.recordedHR = recordedHR
            syncroSet.instantBpms = instantBpms
            syncroSet.instantPeriods = instantPeriods
            syncroSet.averagePeriods = averagePeriods
            syncroSet.instantErrs = instantErrs
            syncroSet.knobScales = knobScales
            syncroSet.currentDelays = currentDelays
            
            dataSet.syncroTraining.append(syncroSet)
        }
        
        // Baseline
        for _ in 0...numValues {
            
            let baselineSet = BaseLineDataset ()
            
            baselineSet.date = Date ()

            let instantBpms = self.makeRandomFloatArray(numValues: numItems)
            let recordedHR = self.makeRandomFloatArray(numValues: numItems)

            baselineSet.recordedHR = recordedHR
            baselineSet.instantBpms = instantBpms

            
            dataSet.baselines.append(baselineSet)
        }
        
        dataSet.endDate = Date ()
        
        dataSet.store()
        
        XCTAssert(InteroceptionDataset.hasPreviousData())
        
        let newSet = InteroceptionDataset.load()
        
        XCTAssert(newSet?.participantID == dataSet.participantID)
        XCTAssert(newSet?.startDate == dataSet.startDate)
        
        XCTAssert(newSet?.endDate == dataSet.endDate)
        
        // Logging.JLog(message: "newSet?.syncroTraining.count : \(String(describing: newSet?.syncroTraining.count))")
        
        XCTAssert(newSet?.syncroTraining.count == dataSet.syncroTraining.count)
        XCTAssert(newSet?.syncroTraining.count == (numValues + 1))
        
        for i in 1...numValues {
            
            // Logging.JLog(message: "run : \(i)")
            
            let newTrial = newSet?.syncroTraining [i]
            let oldTrial = dataSet.syncroTraining [i]

            let isEqual = newTrial!.equals (other: oldTrial)
            
            XCTAssert(isEqual)
        }
        
        XCTAssert(newSet?.baselines.count == dataSet.baselines.count)
        XCTAssert(newSet?.baselines.count == (numValues + 1))
        
        for i in 1...numValues {
        
            // Logging.JLog(message: "run : \(i)")
            
            let newTrial = newSet?.baselines [i]
            let oldTrial = dataSet.baselines [i]

            let isEqual = newTrial!.equals (other: oldTrial)
         
            XCTAssert(isEqual)
        }
        
        let newSyncro = newSet?.syncroTraining.first
        let oldSyncro = dataSet.syncroTraining.first

        newSyncro?.averagePeriods.removeAll()
        
        XCTAssert(!(newSyncro?.equals(other: oldSyncro!))!)

        
        let newBase = newSet?.baselines.first
        let oldBase = dataSet.baselines.first

        newBase?.recordedHR.removeAll()
        
        XCTAssert(!(newBase?.equals(other: oldBase!))!)

        
        print ("newSet : \(newSet)")
        
        
    }

    func makeRandomDoubleArray (numValues: Int) -> [Double] {
        
        var rnds = [Double] ()
        
        for _ in 0...numValues {
         
            let flt = Double.random(in: 0 ..< 100)
            
            rnds.append(flt)
        }
        
        return rnds
    }
    
    func makeRandomFloatArray (numValues: Int) -> [Float] {
        
        var rnds = [Float] ()
        
        for _ in 1...numValues {
         
            let flt = Float.random(in: 0 ..< 100)
            
            rnds.append(flt)
        }
        
        return rnds
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
