//
//  ExportScreen.swift
//  InteroceptionProto
//
//  Created by Joel Barker on 17/01/2020.
//  Copyright © 2020 BioBeats. All rights reserved.
//

import SwiftUI
import MessageUI

final class ExportModel: NSObject, ObservableObject {
    
    @Published var partiId = ""
    
}

struct ExportScreen<Content, NextScreen>: View where Content: View, NextScreen: View {
    let content: Content
    let nextScreen: NextScreen
    
    /// The delegate required by `MFMailComposeViewController`
    private let mailComposeDelegate = MailDelegate()

    /// The delegate required by `MFMessageComposeViewController`
    private let messageComposeDelegate = MessageDelegate()
    
    init(@ViewBuilder content: () -> Content, @ViewBuilder nextScreen: () -> NextScreen) {
        self.content = content()
        self.nextScreen = nextScreen()
    }
    
    var body: some View {
        ZStack {
            Color.bgColor
                .edgesIgnoringSafeArea(.all)
            VStack {
                Spacer ().frame(height: 50.0)
                Spacer ()
                    .frame(height: 150.0)
                Button(action: {
                    //self.showDetails.toggle()
                    // Logging.JLog(message: "pressed")
                    self.presentMailCompose()
                }) {
                    Text("Email Data")
                }
                .padding()
                .background(Color.green)
                    .font(.title)
                    .foregroundColor(.white)
                //.frame (width: 100, height: 50)
                
                Spacer ()
                
                PushView(nextScreen){
                    Text("_exportStartOver")
                }
                .modifier(UIUtils.ButtonLabelStyle())
                .padding(.bottom, UIUtils.defaultVPadding)

            
                
            }
        }
        .foregroundColor(Color.mainFgColor)
    }
}

struct ExportScreen_Previews: PreviewProvider {
    static var previews: some View {
        
        ExportScreen(content: {
            Text("_participantId")
        }, nextScreen: {
            HowToScreen()
        })
        
    }
}

// MARK: The mail part
extension ExportScreen {

    /// Delegate for view controller as `MFMailComposeViewControllerDelegate`
    private class MailDelegate: NSObject, MFMailComposeViewControllerDelegate {

        func mailComposeController(_ controller: MFMailComposeViewController,
                                   didFinishWith result: MFMailComposeResult,
                                   error: Error?) {
            
            controller.dismiss(animated: true)
        }

    }

    /// Present an mail compose view controller modally in UIKit environment
    private func presentMailCompose() {
        guard MFMailComposeViewController.canSendMail() else {
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
extension ExportScreen {

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
