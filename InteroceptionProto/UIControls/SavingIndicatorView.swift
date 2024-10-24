//
//  SavingIndicatorView.swift
//  InteroceptionProto
//
//  Created by Joel Barker on 29/04/2020.
//  Copyright © 2020 BioBeats. All rights reserved.
//

import SwiftUI


struct SavingIndicatorView<Content>: View where Content: View {
    @Binding var isShowing: Bool
    var content: () -> Content

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .center) {
                if (!self.isShowing) {
                    self.content()
                } else {
                    self.content()
                        .disabled(true)
                        .blur(radius: 3)

                    VStack {
                        Text("Saving ...")
                        ActivityIndicator(style: .large)
                    }
                    .frame(width: geometry.size.width / 2.0, height: 200.0)
                    .background(Color.secondary.colorInvert())
                    .foregroundColor(Color.primary)
                    .cornerRadius(20)
                }
            }
        }
    }
}
