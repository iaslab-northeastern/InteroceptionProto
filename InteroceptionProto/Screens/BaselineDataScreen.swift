//
//  BaselineDataScreen.swift
//  InteroceptionProto
//
//  Created by Joel Barker on 23/01/2020.
//  Copyright © 2020 BioBeats. All rights reserved.
//

import SwiftUI
import AVFoundation

@available(iOS 13.0, *)
final class BaselineDataModel: ObservableObject {
    
    // this is one way to decide how long a baseline to capture
    @Published var maxSeconds = 120

    @Published var maxSecondsDo = Double (120)

    var elapsedSecs = 0
    
    @Published public var showNext: Int? = nil
    
    @Published public var goForward = false
    
    @Published var measureNotValid = true
    
    @Published var chartWidth = CGFloat (0)
    
    @Published var secondsRemainingText = String ("0 seconds remaining")
    
    @Published var flashNotWorking = false
    
    private var motionDetector: MotionDetector!
    
    private var isFingerPresent = false
    private var isMovingTooMuch = false
    
    var secsTimer = Timer ()
    
    var startTimer = Timer ()
    
    var device:AVCaptureDevice?
    
    
    
    init() {
        SyncroTaskManager.shared.taskDelegate = self
        
        /*
        self.startTimer = Timer.scheduledTimer(timeInterval: 2, target: self, selector: #selector(self.startTimerFinished), userInfo: nil, repeats: true)*/
        
        self.device = AVCaptureDevice.DiscoverySession.init(deviceTypes: [AVCaptureDevice.DeviceType.builtInTelephotoCamera], mediaType: .video, position: .back).devices.first
        
        // Logging.JLog(message: "device?.isTorchActive : \(device?.isTorchActive)")
        
        
        if SyncroTaskManager.shared.isSimulator() {
            self.isFingerPresent = true
            self.maxSeconds = 12
            self.maxSecondsDo = 12.0
        }
        
        SyncroTaskManager.shared.torchCheck()
        
    }
    
    func startCountDown () {
        
        SyncroTaskManager.shared.start()
        
        self.motionDetector = MotionDetector()
        self.motionDetector.start()
        
        self.secsTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.secsTimerFinished), userInfo: nil, repeats: true)
        
        self.elapsedSecs = maxSeconds
        
        
        
    }
    
    func stop () {
        
        motionDetector.stop()
        
        SyncroTaskManager.shared.taskDelegate = nil
        SyncroTaskManager.shared.stopAndRecordBaseline()
    }
    
    @objc
    func startTimerFinished () {
        self.chartWidth = CGFloat(330.0)
        self.startCountDown()
    }
    
    @objc
    func secsTimerFinished () {
        
        self.elapsedSecs -= 1
        
        self.secondsRemainingText = "\(elapsedSecs.description) seconds left"
        
        if self.elapsedSecs == 0 {
            self.secsTimer.invalidate()
            //self.showNext = 1
            self.goForward = true
            self.stop()
        }
        
        //let device = AVCaptureDevice.init(uniqueID: <#T##String#>)
        
        if device != nil {
            // Logging.JLog(message: "device?.isTorchActive : \(device?.isTorchActive)")
            
            if !device!.isTorchActive {
                self.flashNotWorking = true
            }
        }
    }
    
    
}

// PRAGMA MARK: SyncroTaskManagerDelegate
@available(iOS 13.0, *)
extension BaselineDataModel: SyncroTaskManagerDelegate {

    func torchError () {
        // Logging.JLog(message: "torchError")
        self.flashNotWorking = true
    }
    
    func fingerPresentChanged(_ isPresent: Bool) {
        
        print("Finger is present: \(isPresent)")
        DispatchQueue.main.async {
            self.isFingerPresent = isPresent
            self.measureNotValid = !self.isFingerPresent || self.isMovingTooMuch
        }
    }
    
    func beatDetected(withInstantBPM instantBPM: Float, andAverageBPM averageBPM: Float) {
        
        self.motionDetector.checkIsMovingTooMuch {
            
            isMovingTooMuch in
            DispatchQueue.main.async {
                self.isMovingTooMuch = isMovingTooMuch
                self.measureNotValid = !self.isFingerPresent || self.isMovingTooMuch
                //self.measureNotValid = self.isMovingTooMuch
            }
        }
        
    }
    
    func newPPGSampleReady(_ sample: Float) {
        
    }
    
    func reportHRVActivation(_ activation: Float, withMaxPeriod max: Float, andMinPeriod min: Float) {
        
    }
    
    
}

@available(iOS 13.0, *)
struct BaselineDataScreen<NextScreen>: View where NextScreen: View {
    
    @State private var chartWidth: CGFloat = 10
    
    @ObservedObject var baselineDataModel = BaselineDataModel()
    
    @State private var gotoNext: Int? = nil
    
    let nextScreen: NextScreen
    
    init(@ViewBuilder nextScreen: () -> NextScreen) {

        self.nextScreen = nextScreen()
    }
    
    var body: some View {
        NavigationView {
            ZStack (alignment: .leading) {
                
                Color.bgColor
                    .edgesIgnoringSafeArea(.all)
                
                if baselineDataModel.measureNotValid {
                    FingerOverlay().transition(AnyTransition.opacity.animation(.easeOut(duration: 0.2)))
                }
                
                VStack (alignment: .center) {
                    
                    Spacer ()
                    Text ("Checking your heartbeat")
                    Spacer ()
                    
                    Image("FingerOnCameraStandard")
                    Spacer ()
                    
                    PushView(nextScreen, isActive: $baselineDataModel.goForward){
                                   Text("")
                               }
                    
                    VStack (alignment: .leading) {
                        
                        
                        TextField("", text: $baselineDataModel.secondsRemainingText, onCommit: {() in
                        }).font(Font.system(size: 12, design: .default))
                            .frame(width: CGFloat (330.0), alignment: .leading)
                        
                        
                        
                    }.frame(width: 330, alignment: .leading)
                    
                    VStack (alignment: .leading) {
                        
                        HStack {
                            MyRectangle()
                                .position(CGPoint(x: 0, y: 0))
                                .frame(width: $baselineDataModel.chartWidth.wrappedValue, height: CGFloat (5),
                                       alignment: .trailing)
                                .padding(.leading, 30)
                                .animation(Animation.linear(duration: $baselineDataModel.maxSecondsDo.wrappedValue).delay(0))
                        }
                        .frame(width: CGFloat (330.0), alignment: .leading)
                        
                        
                        
                    //}
                    }.frame(width: CGFloat (330.0), alignment: .leading)
                    //.position(CGPoint(x: 300, y: 0))
                    //.position(CGPoint(x: 0, y: 0))
                    
                    Spacer ()
                    
                    
                    
                }
            }.alert(isPresented: $baselineDataModel.flashNotWorking) {
                Alert(title: Text("Flash not working"), message: Text("The Flash doesn't appear to be working. Maybe the phone has over-heated...?"), dismissButton: .default(Text("Ok"), action: {
                    self.$baselineDataModel.flashNotWorking.wrappedValue = false
                })
                )
            }.onAppear {
                self.baselineDataModel.startTimerFinished()
            }.frame(width: CGFloat (330.0), alignment: .leading)
                
        }.navigationBarBackButtonHidden(true)
    }
}




fileprivate struct FingerOverlay: View {
    @available(iOS 13.0.0, *)
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

struct MyRectangle: View {
    @available(iOS 13.0.0, *)
    var body: some View {
        Rectangle().fill(Color.blue)
    }
}

struct BaselineDataScreen_Previews: PreviewProvider {
    @available(iOS 13.0.0, *)
    static var previews: some View {
        BaselineDataScreen(nextScreen: {
//            PracticeInstructionsScreen ()
            OnboardingScreen3()
        })
    }
}

struct BaselineDataUseScreen: View {
    @available(iOS 13.0.0, *)
    var body: some View {
        BaselineDataScreen(nextScreen: {
//            PracticeInstructionsScreen ()
            OnboardingScreen3()
        })
    }
}



