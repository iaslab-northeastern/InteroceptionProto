//
//  ActivityIndicator.swift
//  InteroceptionProto
//
//  Created by Joel Barker on 11/02/2020.
//  Copyright © 2020 BioBeats. All rights reserved.
//

import SwiftUI

struct ActivityIndicator: UIViewRepresentable {

    typealias UIViewType = UIActivityIndicatorView

    let style: UIActivityIndicatorView.Style

    @available(iOS 13.0, *)
    func makeUIView(context: UIViewRepresentableContext<ActivityIndicator>) -> ActivityIndicator.UIViewType {
        return UIActivityIndicatorView(style: style)
    }

    @available(iOS 13.0, *)
    func updateUIView(_ uiView: ActivityIndicator.UIViewType, context: UIViewRepresentableContext<ActivityIndicator>) {
        uiView.startAnimating()
    }
}
