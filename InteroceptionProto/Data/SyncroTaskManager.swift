//
//  SyncroTaskManager.swift
//  InteroceptionProto
//
//  Created by Joel Barker on 23/01/2020.
//  Copyright © 2020 BioBeats. All rights reserved.
//

import UIKit
import HeartDetectorEngine

protocol SyncroTaskManagerDelegate: class {
    
    func fingerPresentChanged(_ isPresent: Bool)
    
    func torchError ()
    
    func beatDetected(withInstantBPM instantBPM: Float, andAverageBPM averageBPM: Float)
    
    func newPPGSampleReady(_ sample: Float)
    
    func reportHRVActivation(_ activation: Float, withMaxPeriod max: Float, andMinPeriod min: Float)

}

class SyncroTaskManager: NSObject {
    
    static var averageBpms:[Float]?
    static var instantBpms:[Float]?
    
    private static let baselineDuration = Int32(10)
    
    var taskDelegate:SyncroTaskManagerDelegate?
    
    private let engine = HeartDetectorEngine()
    
    private override init() {
//        // Logging.JLog(message: "SyncroTaskManager Init")
        
        SyncroTaskManager.averageBpms = [Float] ()
        SyncroTaskManager.instantBpms = [Float] ()

    }
    
    @objc
    static let shared = SyncroTaskManager ()
    
    var simHRTimer = Timer ()
    
    func start () {
        
        SyncroTaskManager.instantBpms!.removeAll()
        SyncroTaskManager.averageBpms!.removeAll()
        
        // Logging.JLog(message: "starting hr monitor")
        
        if Platform.isSimulator {
            // Logging.JLog(message: "isSimulator")
            
            self.simHRTimer.invalidate()
            
            self.simHRTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.artificialHeartBeat), userInfo: nil, repeats: true)
            
        } else {
            // Logging.JLog(message: "isDevice")
            
            engine.hrDelegate = self
            engine.startHeartEngineSavingRawCameraSamples(false, forDuration: Self.baselineDuration)
        }
        
        
        
    }
    
    func stopAndRecordBaseline () {
        
        // Logging.JLog(message: "stopping hr monitor")
        
        
        
        if Platform.isSimulator {
            self.simHRTimer.invalidate()
        } else {
            engine.stop()
            engine.hrDelegate = nil
        }
        
        let taskData = BaseLineDataset ()
        
        taskData.date = Date ()
        
        taskData.recordedHR = SyncroTaskManager.averageBpms!
        taskData.instantBpms = SyncroTaskManager.instantBpms!
        
        (UIApplication.shared.delegate as! AppDelegate).dataset?.baselines.append(taskData)
        
        (UIApplication.shared.delegate as! AppDelegate).dataset?.store()

        (UIApplication.shared.delegate as! AppDelegate).dataset?.storeWithCompletion () { (errorStr: String) in
            
            // Logging.JLog(message: "saveFinished")
        }
        
        let csvData = (UIApplication.shared.delegate as! AppDelegate).dataset?.toCSV()
        
        // Logging.JLog(message: "baseline csvData")
        print(csvData as Any)
    }
    
    func stopAndRecordSyncro () {
        
        // Logging.JLog(message: "SyncroTaskManager.instantBpms : \(String(describing: SyncroTaskManager.instantBpms))")
        // Logging.JLog(message: "SyncroTaskManager.averageBpms : \(String(describing: SyncroTaskManager.averageBpms))")

        (UIApplication.shared.delegate as! AppDelegate).dataset?.syncroTraining.last?.recordedHR = SyncroTaskManager.instantBpms!
        
        (UIApplication.shared.delegate as! AppDelegate).dataset?.syncroTraining.last?.instantBpms = SyncroTaskManager.averageBpms!
        
        (UIApplication.shared.delegate as! AppDelegate).dataset?.store()
        
        (UIApplication.shared.delegate as! AppDelegate).dataset?.storeWithCompletion () { (errorStr: String) in
            
            // Logging.JLog(message: "saveFinished")
        }
        
        let csvData = (UIApplication.shared.delegate as! AppDelegate).dataset?.toCSV()
        
        // Logging.JLog(message: "syncro csvData")
        print(csvData as Any)
    }
    
    func stop () {
        
        // Logging.JLog(message: "stopping hr monitor")
        
        if Platform.isSimulator {
            self.simHRTimer.invalidate()
        } else {
            engine.stop()
            engine.hrDelegate = nil
        }
        
        let taskData = (UIApplication.shared.delegate as! AppDelegate).dataset?.syncroTraining.last
        
        if taskData == nil {
            // Logging.JLog(message: "no task found...?")
        } else {
            //(UIApplication.shared.delegate as! AppDelegate).dataset?.syncroTraining.last!.recordedHR = SyncroTaskManager.averageBpms
            //(UIApplication.shared.delegate as! AppDelegate).dataset?.syncroTraining.last!.instantBpms = SyncroTaskManager.instantBpms
        }
    }
    
    @objc
    func artificialHeartBeat () {
        
        let instantBPM = Float (60);
        let averageBPM = Float (60);

        self.beatDetected(withInstantBPM: instantBPM, andAverageBPM: averageBPM)
        
    }
    
    func isSimulator () -> Bool {
        return Platform.isSimulator
    }
    
    func torchCheck () {
        
        if self.isSimulator() {
            // Logging.JLog(message: "isSim, noTorchCheck")
            return
        }
        
        guard let device = AVCaptureDevice.default(for: AVMediaType.video) else { return }
        guard device.hasTorch else { return }
        
        do {
            try device.lockForConfiguration()
            
            device.torchMode = AVCaptureDevice.TorchMode.on
            device.torchMode = AVCaptureDevice.TorchMode.off
            
            do {
                try device.setTorchModeOn(level: 1.0)
            } catch {
                // Logging.JLog(message: "torchError: \(error)")
                self.taskDelegate?.torchError()
            }
            
            device.unlockForConfiguration()
        } catch {
            // Logging.JLog(message: "torchError: \(error)")
            self.taskDelegate?.torchError()

        }
    }
    
}

extension SyncroTaskManager : HREventsDelegate {
    
    func beatDetected(withInstantBPM instantBPM: Float, andAverageBPM averageBPM: Float) {
        
        // Logging.JLog(message: "avg_bpm: \(averageBPM)")
        
        // Logging.JLog(message: "self.instantBpms : \(SyncroTaskManager.instantBpms!.count)")
        
        SyncroTaskManager.instantBpms!.append(instantBPM)
        SyncroTaskManager.averageBpms!.append(averageBPM)
        
        taskDelegate?.beatDetected(withInstantBPM: instantBPM, andAverageBPM: averageBPM)
    }
    
    func fingerPresentChanged(_ isPresent: Bool) {
        
        // Logging.JLog(message: "fingerPresentChanged")
        
        taskDelegate?.fingerPresentChanged(isPresent)
        
    }
    
    // nothing here...
    func newPPGSampleReady(_ sample: Float) {

        taskDelegate?.newPPGSampleReady(sample)
    }
    
    // nothing here...
    func reportHRVActivation(_ activation: Float, withMaxPeriod max: Float, andMinPeriod min: Float) {

        self.taskDelegate?.reportHRVActivation(activation, withMaxPeriod: max, andMinPeriod: min)
    }
    
    
    
    
}
