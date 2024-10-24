//
//  FinalScreen.swift
//  InteroceptionProto
//
//  Created by Matteo Puccinelli on 06/12/2019.
//  Copyright © 2019 BioBeats. All rights reserved.
//

import SwiftUI
import MessageUI

class FinalScreenModel: NSObject, ObservableObject {

    @Published var showAlert = false
    
    @Published public var showNext: Int? = nil
    
    override init() {
        super.init()
        
        self.setupNotis()
    }
    
    func setupNotis () {
        
        let nc = NotificationCenter.default
        
        nc.addObserver(
            self,
            selector: #selector(gotoExitScreen(noti:)),
            name: Notification.Name(rawValue:"gotoExitScreen"), object: nil
        )
        
    }
    
    @objc func gotoExitScreen (noti: Notification) {
        self.showNext = 1
    }
    
}

struct FinalScreen: View {
    
    /// The delegate required by `MFMailComposeViewController`
    private let mailComposeDelegate = MailDelegate()

    /// The delegate required by `MFMessageComposeViewController`
    private let messageComposeDelegate = MessageDelegate()
    
    @ObservedObject var finalScreenModal = FinalScreenModel()
    
    var body: some View {
        NavigationView {
        ZStack {
            Color.bgColor
                .edgesIgnoringSafeArea(.all)
//            VStack {
//                Text("_final_body")
//                .padding([.horizontal], UIUtils.defaultVPadding)
//                .multilineTextAlignment(.center)
//
//                Spacer().frame (height: CGFloat (50.0))
//
////                Button(action: {
////                    //self.showDetails.toggle()
////                    // Logging.JLog(message: "pressed")
////                    //let csvStr = (UIApplication.shared.delegate as! AppDelegate).dataset!.toCSV()
////
////                    // Logging.JLog(message: "csvStr")
////                    //print (csvStr)
////                    //self.presentMailCompose()
////                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
////                        UIApplication.shared.perform(#selector(NSXPCConnection.suspend))
////                         DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
////                          exit(0)
////                         }
////                    }
////
////                }) {
////                    Text("Exit")
////                }
//
//
//
//                NavigationLink(destination: ExitScreen(), tag: 1, selection: $finalScreenModal.showNext) {
//                    return Text("Login")
//                        .font(.title)
//                        .foregroundColor(Color.white)
//                        .multilineTextAlignment(.center)
//                        .frame(width: 300.0, height: 50.0)
//                        .background(Color(UIColor.blue))
//
//                }
//
//
//
//
//
//            }
            VStack {
                
                Text("Thank you for your time - please tap the button below to finish. Your Prolific pay code is: 5B5FCD4B")
                .padding([.horizontal], UIUtils.defaultVPadding)
                .multilineTextAlignment(.center)
                
                Spacer().frame (height: 50)
                
                
                Spacer().frame (height: 50)
                Button(action: {
                    //self.showDetails.toggle()
                    // Logging.JLog(message: "pressed")
                   
                    
//                    guard let url = URL(string: "https://aruspsych.eu.qualtrics.com/jfe/form/SV_6txBm9IdA5IcTVs") else { return }
//                    UIApplication.shared.open(url)
//
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        UIApplication.shared.perform(#selector(NSXPCConnection.suspend))
                         DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                          exit(0)
                         }
                    }
                    
                    
                }) {
                    Text("Exit")
                }
                .padding()
                .background(Color.red)
                    .font(.title)
                    .foregroundColor(.white)
                //.frame (width: 100, height: 50)
                Spacer().frame (height: 40)
                
            }
            .padding(.all, UIUtils.defaultVPadding)
            
        }.onAppear {
            
            (UIApplication.shared.delegate as! AppDelegate).dataset?.endDate = Date ()
            (UIApplication.shared.delegate as! AppDelegate).dataset?.store()
            
            (UIApplication.shared.delegate as! AppDelegate).dataset?.storeWithCompletion () { (errorStr: String) in
                
                // Logging.JLog(message: "saveFinished")
            }
            
        }
        
    }
        .foregroundColor(.mainFgColor)
        
        .alert(isPresented: $finalScreenModal.showAlert) {
                Alert(title: Text("Important"), message: Text("There is no email address setup. Please setup an email address then try and send."), dismissButton: .default(Text("OK"), action: {
                    
                    self.finalScreenModal.showAlert = false

                    
                }))
        }
    }
}

struct FinalScreen_Previews: PreviewProvider {
    static var previews: some View {
        FinalScreen()
    }
}

// MARK: The mail part
extension FinalScreen {

    /// Delegate for view controller as `MFMailComposeViewControllerDelegate`
    private class MailDelegate: NSObject, MFMailComposeViewControllerDelegate {

        func mailComposeController(_ controller: MFMailComposeViewController,
                                   didFinishWith result: MFMailComposeResult,
                                   error: Error?) {
            
            controller.dismiss(animated: true)
            
            // Logging.JLog(message: "mailFinished")
            
            if result == .sent {
                NotificationCenter.default.post(name:Notification.Name(rawValue:"gotoExitScreen"), object: nil, userInfo: [:])
            }
            
            if result == .saved {
                NotificationCenter.default.post(name:Notification.Name(rawValue:"gotoExitScreen"), object: nil, userInfo: [:])
            }
            
        }

    }

    /// Present an mail compose view controller modally in UIKit environment
    private func presentMailCompose() {
        
        // Logging.JLog(message: "presentMailCompose")
        
         guard MFMailComposeViewController.canSendMail() else {
            // Logging.JLog(message: "cantSendMail")
            self.finalScreenModal.showAlert = true
            return
        }
        
        let vc = UIApplication.shared.keyWindow?.rootViewController

        // Logging.JLog(message: "mailer")
        
        //let dataset = InteroceptionDataset(participant: "test")
        //dataset.store()
        //(UIApplication.shared.delegate as! AppDelegate).dataset = dataset;
        
        let composeVC = MFMailComposeViewController()
        composeVC.mailComposeDelegate = mailComposeDelegate

        let partId = (UIApplication.shared.delegate as! AppDelegate).dataset!.participantID
        
        composeVC.setSubject("Interoception data from " + partId)
        composeVC.setToRecipients(["sonia@biobeats.com"])
        
        let csvStr = (UIApplication.shared.delegate as! AppDelegate).dataset!.toCSV()
        
        // Logging.JLog(message: "csvStr")
        print (csvStr)

        let csvData = csvStr.data(using: .utf8)
        
        if csvData != nil {
            composeVC.setMessageBody("CSV with data attached", isHTML: false)
            composeVC.addAttachmentData(csvData!, mimeType: "text/csv", fileName: partId + ".csv")
        }


        
        
        vc?.present(composeVC, animated: true)
    }
}



// MARK: The message part
extension FinalScreen {

    /// Delegate for view controller as `MFMessageComposeViewControllerDelegate`
    private class MessageDelegate: NSObject, MFMessageComposeViewControllerDelegate {
        func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
            // Customize here
            controller.dismiss(animated: true)
            
            
        }

    }

    /// Present an message compose view controller modally in UIKit environment
    private func presentMessageCompose() {
        guard MFMessageComposeViewController.canSendText() else {
            return
        }
        let vc = UIApplication.shared.keyWindow?.rootViewController

        let composeVC = MFMailComposeViewController()
        
        
        composeVC.mailComposeDelegate = mailComposeDelegate

        

        vc?.present(composeVC, animated: true)
    }
}
