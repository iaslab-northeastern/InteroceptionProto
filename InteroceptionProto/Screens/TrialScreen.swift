//
//  TrialScreen.swift
//  InteroceptionProto
//
//  Created by Matteo Puccinelli on 02/12/2019.
//  Copyright © 2019 BioBeats. All rights reserved.
//

import SwiftUI
import AVFoundation
import Combine

final class TrialScreenViewModel: NSObject, ObservableObject {
    static let shortestDelay = Double(60.0/140.0)
    
    private static let baselineDuration = Int32(10)
    private static let pollingInterval = TimeInterval(0.001) //50Hz
    
    //private let engine = HeartDetectorEngine()
    private var player: AVAudioPlayer?
    private var secondPlayer: AVAudioPlayer?
    private var fakeBpmTimerCanc: AnyCancellable!
    private var motionDetector: MotionDetector!
    
    var averageBpm = Float(0)
    var simHRTimer = Timer ()
    
    @Published var practiceLabelTxt = String ("")
    
    @Published var debugViewHidden = true
    
    // Min/Max output from knob is -1 / 1 (1 period)
    let knobValueRange = 1.0
    @Published var currentKnobValue = Double(0)
    
    @Published var instantBpm = Float(0)
    @Published var averagePeriod = Double(0)
    @Published var instantPeriod = Double(0)
    private var isFingerPresent = true
    private var isMovingTooMuch = false
    @Published var instantErr = Double(0)
    @Published var measureNotValid = false
    
    //var averageBpms = [Float] ()
    //var instantBpms = [Float] ()

    @Published var currentDelays = [Double] ()
    @Published var averagePeriods = [Double] ()
    @Published var instantPeriods = [Double] ()
    @Published var knobScales = [Double] ()
    @Published var instantErrs = [Double] ()
    
    @Published var flashNotWorking = false
    
    var device:AVCaptureDevice?
    
    var secsTimer = Timer ()
    
    override init() {
        super.init()
        initAudioPlayer()
        initSecondAudioPlayer()
    }
    
    @objc func start() {
        currentKnobValue = .random(in: -knobValueRange ... knobValueRange)
        
//        // Logging.JLog(message: "startMotionDetection")
        self.motionDetector = MotionDetector()
        self.motionDetector.start()
        
        self.measureNotValid = false
        self.isFingerPresent = true
        self.isMovingTooMuch = false
        
        if SyncroTaskManager.shared.isSimulator() {
            self.isFingerPresent = true
        }
        
        self.secsTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.secsTimerFinished), userInfo: nil, repeats: true)
        
        SyncroTaskManager.shared.taskDelegate = nil
        SyncroTaskManager.shared.taskDelegate = self
        
        //self.instantBpms.removeAll()
        self.instantPeriods.removeAll()
        self.averagePeriods.removeAll()
        //self.averageBpms.removeAll()
        self.knobScales.removeAll()
        self.instantErrs.removeAll()
        self.currentDelays.removeAll()
        
        // @David: Decomment the following to switch to real HR
        SyncroTaskManager.shared.start()
        // @David: Comment the following to switch to real HR
//        startFakeBpmTimer()
    }
    
    @objc func stop() {
        SyncroTaskManager.shared.stop()
        if Platform.isSimulator {
            //self.simHRTimer.invalidate()
            
        } else {
            //engine.stop()
            //engine.hrDelegate = nil
        }
        
        // @David: Comment the following to switch to real HR
        //self.fakeBpmTimerCanc.cancel()
        
        
        self.secsTimer.invalidate()
        
        
//        // Logging.JLog(message: "stopMotionDetector")
        motionDetector.stop()
    }
    
    @objc
    func secsTimerFinished () {
        
        if device != nil {
//            // Logging.JLog(message: "device?.isTorchActive : \(String(describing: device?.isTorchActive))")
            
            if !device!.isTorchActive {
                self.flashNotWorking = true
            }
        }
        
    }
    
    func registerForNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(start), name: UIApplication.willEnterForegroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(stop), name: UIApplication.willResignActiveNotification, object: nil)
    }
    
    func unregisterForNotifications() {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func initAudioPlayer() {
        guard let url = Bundle.main.url(forResource: "lowBeep", withExtension: "mp3") else { return }
        
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            
            /* The following line is required for the player to work on iOS 11. Change the file type accordingly*/
            player = try AVAudioPlayer(contentsOf: url, fileTypeHint: AVFileType.mp3.rawValue)
        } catch let error {
            print(error.localizedDescription)
        }
    }
    
    private func initSecondAudioPlayer() {
        guard let url = Bundle.main.url(forResource: "highBeep", withExtension: "mp3") else { return }
        
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            
            /* The following line is required for the player to work on iOS 11. Change the file type accordingly*/
            secondPlayer = try AVAudioPlayer(contentsOf: url, fileTypeHint: AVFileType.mp3.rawValue)
        } catch let error {
            print(error.localizedDescription)
        }
    }
        
    private func startFakeBpmTimer() {
        fakeBpmTimerCanc = Timer.publish(every: 1, on: .main, in: .default)
        .autoconnect()
        .sink { _ in
            self.beatDetected(withInstantBPM: 60, andAverageBPM: 60)
        }
    }
    
    private func playDelayedSound() {
        guard !measureNotValid, let player = player else { return }
        player.play()
    }
    
    private func playHRSound() {
        //// Logging.JLog(message: "playHRSound : measureNotValid : \(measureNotValid)")
        if measureNotValid {
            return
        }
        guard !measureNotValid, let secondPlayer = secondPlayer else { return }
        secondPlayer.play()
    }
}

// PRAGMA MARK: SyncroTaskManagerDelegate
extension TrialScreenViewModel: SyncroTaskManagerDelegate {
    
    func torchError () {
    }
    
    func fingerPresentChanged(_ isPresent: Bool) {
        print("Finger is present: \(isPresent)")
        DispatchQueue.main.async {
            self.isFingerPresent = isPresent
            //self.measureNotValid = !self.isFingerPresent || self.isMovingTooMuch
            self.measureNotValid = !self.isFingerPresent
        }
    }
    
    func beatDetected(withInstantBPM instantBPM: Float, andAverageBPM averageBPM: Float) {
        // Check movement
        DispatchQueue.main.async {
            // Play HR sound
//            /self.playHRSound()
            
            // Update some info
            let currentInstantPeriod = self.instantPeriod
            self.instantBpm = instantBPM
            self.instantPeriod = Double(60.0/self.instantBpm)
            self.instantErr = currentInstantPeriod - self.instantPeriod
            
            self.averageBpm = averageBPM
            self.averagePeriod = Double(60.0/self.averageBpm)
            
            //self.instantBpms.append(self.instantBpm)
            self.instantPeriods.append(self.instantPeriod)
            self.averagePeriods.append(self.averagePeriod)
            //self.averageBpms.append(self.averageBpm)
            self.knobScales.append(self.currentKnobValue)
            self.instantErrs.append (self.instantErr)
            self.currentDelays.append(self.currentDelay())
            
            // Schedule delayed sound based on current know value (aka the delay) and current time
            // If knob < 0, e.g. -1, then the delay in second from now is period + delay (e.g. 1s - 0.5s), otherwise it's just delay
            // @David if you prefer average period intead of instant, change it in the following line
            let delayFromNow = self.currentDelay() < 0 ? self.instantPeriod + self.currentDelay() : self.currentDelay()
            Timer.scheduledTimer(withTimeInterval: delayFromNow, repeats: false, block: { (t) in
                self.playDelayedSound()
            })
        
            self.motionDetector.checkIsMovingTooMuch { isMovingTooMuch in
                DispatchQueue.main.async {
                    self.isMovingTooMuch = isMovingTooMuch
                    //self.measureNotValid = !self.isFingerPresent || self.isMovingTooMuch
//                    self.measureNotValid = !self.isFingerPresent
                }
            }
        }
    }
    func newPPGSampleReady(_ sample: Float) {
        //nothing to do
    }
    func reportHRVActivation(_ activation: Float, withMaxPeriod max: Float, andMinPeriod min: Float) {
        //nothing to do
    }
    
    func currentDelay() -> Double {
        // If an average period is set and the period is X (e.g. 1 second if 60bpm)
        // Then the current delay from the beat to the follow up sound is X/2 * knobValue, cause
        // knob goes from -1 to 1
        guard averagePeriod != 0 else {
            // If not set, just the shortest delay (60bpm/140bpm)
            return TrialScreenViewModel.shortestDelay
        }
        // here we can decide whether we use half the period (averagePeriod/2) or whole
        return averagePeriod/2 * currentKnobValue
    }
}

struct DebugScreen: View {
    
    @ObservedObject var trialViewModel: TrialScreenViewModel
    
    var body: some View {
        VStack {
            HStack {
                VStack(alignment: .leading, spacing: nil){
                    Text("instantBpm: \(trialViewModel.instantBpm)")
                    Text("averageBpm: \(trialViewModel.averageBpm)")
                    Text("instantPeriod: \(trialViewModel.instantPeriod)")
                    Text("averagePeriod: \(trialViewModel.averagePeriod)")
                    Text("instantErr: \(trialViewModel.instantErr)")
                }
                
                Spacer()
            }
            .background(Color.black.opacity(0.5))
            .foregroundColor(Color.green)
            
            Spacer()
        }
        .padding(.top)
    }
}

struct TrialScreen: View {
    private static let knobSize = CGFloat(200)
    
    @ObservedObject var interoceptionSettings = InteroceptionSettings(numberOfTrials: 20, numberOfBodyParts: 5)
    @ObservedObject var trialViewModel = TrialScreenViewModel()
    @State var goToConfidenceScreen = false
    
    var body: some View {
        ZStack {
            Color.bgColor
                .edgesIgnoringSafeArea(.all)
            
            if trialViewModel.measureNotValid {
                FingerOverlay().transition(AnyTransition.opacity.animation(.easeOut(duration: 0.2)))
            }
            
            if !trialViewModel.debugViewHidden {
                DebugScreen(trialViewModel: trialViewModel)
                    .transition(AnyTransition.opacity.animation(.easeOut(duration: 0.2)))
                    .zIndex(10)
            }
            
            

            
            VStack {
                
                //if InteroceptionSettings.practicesToGo > 0 {
//                if InteroceptionSettings.isPracticeRun {
                    TextField("", text: $trialViewModel.practiceLabelTxt).frame(width: CGFloat (330.0), alignment: .leading).multilineTextAlignment(.center)
                //}
                
                Text("_trial_instruction").multilineTextAlignment(.center)
                
                Spacer()
                
                HStack {
                    VStack(alignment: .leading) {
                        Text(".")
                            .multilineTextAlignment(.trailing)
                        .foregroundColor(Color.white)
                        .frame(width: 60, height: /*@START_MENU_TOKEN@*/100.0/*@END_MENU_TOKEN@*/)
                        .font(Font.system(size: 12, design: .default))
                        Path {
                            path in
                            path.move (to: CGPoint (x: 55, y: 0))
                            path.addQuadCurve(to: CGPoint(x: 45, y: 50), control: CGPoint(x: 45, y: 20))
                            path.addQuadCurve(to: CGPoint(x: 55, y: 100), control: CGPoint(x: 45, y: 75))
                            path.addLine(to: CGPoint(x: 45, y: 95))
                            path.move (to: CGPoint (x: 55, y: 100))
                            path.addLine(to: CGPoint(x: 60, y: 91))

                        }.stroke(lineWidth: 2).frame(width: 50, height: /*@START_MENU_TOKEN@*/100.0/*@END_MENU_TOKEN@*/)
                        Spacer()
                            .frame(width: 30, height: /*@START_MENU_TOKEN@*/100.0/*@END_MENU_TOKEN@*/)
                        
                    }
                    .padding(1.0)

                    
                    KnobView(value: $trialViewModel.currentKnobValue, rang: trialViewModel.knobValueRange)
                        .padding(.leading, 6.0)
                        .frame(width: Self.knobSize, height: Self.knobSize)
                    VStack(alignment: .leading) {
                        Text(".")
                        .foregroundColor(Color.white)
                        .frame(width: 60, height: /*@START_MENU_TOKEN@*/100.0/*@END_MENU_TOKEN@*/)
                        .font(Font.system(size: 12, design: .default))
                        Path {
                            path in
                            path.move (to: CGPoint (x: 5, y: 0))
                            path.addQuadCurve(to: CGPoint(x: 15, y: 50), control: CGPoint(x: 15, y: 20))
                            path.addQuadCurve(to: CGPoint(x: 5, y: 100), control: CGPoint(x: 15, y: 75))
                            path.addLine(to: CGPoint(x: 15, y: 95))
                            path.move (to: CGPoint (x: 5, y: 100))
                            path.addLine(to: CGPoint(x: 0, y: 90))

                        }.stroke(lineWidth: 2).frame(width: 30, height: /*@START_MENU_TOKEN@*/100.0/*@END_MENU_TOKEN@*/)
                        Spacer()
                                                   .frame(width: 30, height: /*@START_MENU_TOKEN@*/100.0/*@END_MENU_TOKEN@*/)
                        
                    }
                    .padding(6.0)
                }
                
                Spacer()
                
                Button(action: {
                    self.trialViewModel.stop()
                    self.trialViewModel.unregisterForNotifications()
                    self.goToConfidenceScreen = true
                }, label: {
                    Text("_button_confirm_label")
                })
                .buttonStyle(UIUtils.MyButtonStyle())
                
                PushView(ConfidenceRatingScreen(interoceptionSettings: interoceptionSettings), isActive: $goToConfidenceScreen) {
                    Text("")
                }
            }
            .padding(.all, UIUtils.defaultVPadding)
        }
        .alert(isPresented: $trialViewModel.flashNotWorking) {
            Alert(title: Text("Flash not working"), message: Text("The Flash doesn't appear to be working. Maybe the phone has over-heated...?"), dismissButton: .default(Text("Ok"), action: {
                self.$trialViewModel.flashNotWorking.wrappedValue = false
            })
            )
        }
        .foregroundColor(.mainFgColor)
        .onAppear {
            
            //// Logging.JLog(message: "trialViewModel appear : \(self.interoceptionSettings.currentIndex)")
            
            if InteroceptionSettings.practicesToGo > 0 {
                
                // Logging.JLog(message: "InteroceptionSettings.practicesToGo : \(InteroceptionSettings.practicesToGo)")
                
                if self.interoceptionSettings.currentIndex == -2 {
                    self.trialViewModel.practiceLabelTxt = "PRACTICE TRIAL 1:"
                } else {
                    self.trialViewModel.practiceLabelTxt = "PRACTICE TRIAL 2:"
                }
            } else {
                
                let indxDisplay = self.interoceptionSettings.currentIndex + 1
                
                self.trialViewModel.practiceLabelTxt = "TRIAL " + indxDisplay.description + ":"
            }

            
            self.trialViewModel.registerForNotifications()
            self.trialViewModel.start()
        }
        .onTapGesture {
            //self.trialViewModel.debugViewHidden.toggle()
        }
        .onDisappear {
//            // Logging.JLog(message: "recordingInfo : isPracticeRun : \(InteroceptionSettings.isPracticeRun)")
//            // Logging.JLog(message: "recordingInfo : practicesToGo : \(InteroceptionSettings.practicesToGo)")

            //if InteroceptionSettings.practicesToGo > 0 {
            
            // only record if not practice run
            //if !InteroceptionSettings.isPracticeRun {

                let taskData = SyncroTrialDataset ()
                
                taskData.date = Date ()
                
                //taskData.recordedHR = self.trialViewModel.averageBpms
                //taskData.instantBpms = self.trialViewModel.averageBpms
                taskData.instantPeriods = self.trialViewModel.instantPeriods
                taskData.averagePeriods = self.trialViewModel.averagePeriods
            
                taskData.instantErrs = self.trialViewModel.instantErrs
                taskData.knobScales = self.trialViewModel.knobScales
                taskData.currentDelays = self.trialViewModel.currentDelays
                
                
            
                (UIApplication.shared.delegate as! AppDelegate).dataset?.syncroTraining.append(taskData)
                (UIApplication.shared.delegate as! AppDelegate).dataset?.store()
                
                (UIApplication.shared.delegate as! AppDelegate).dataset?.storeWithCompletion () { (errorStr: String) in
                    
                    SyncroTaskManager.shared.stopAndRecordSyncro()
                    
//                    // Logging.JLog(message: "saveFinished")
                }
            //}
            
            SyncroTaskManager.shared.taskDelegate = nil
            
            
        }
    }
    
    
}





fileprivate struct FingerOverlay: View {
    var body: some View {
        ZStack {
            Color.bgColor
            VStack {
                Image("FingerOnCameraStandard")
                Text("_readjust_your_grip_title")
                    .font(.headline)
                Text("_readjust_your_grip_body")
                    .font(.footnote)
                    .padding()
            }
        }
        .zIndex(1)
    }
}

struct TrialScreen_Previews: PreviewProvider {
    
    static var previews: some View {
        let trialViewModel = TrialScreenViewModel()
        trialViewModel.measureNotValid = false
        return TrialScreen(trialViewModel: trialViewModel)
    }
}
