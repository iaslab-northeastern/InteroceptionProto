//
//  SwiftUISlider.swift
//  InteroceptionProto
//
//  Created by Joel Barker on 23/01/2020.
//  Copyright © 2020 BioBeats. All rights reserved.
//

import SwiftUI
import UIKit

struct SwiftUISlider: UIViewRepresentable {

  final class Coordinator: NSObject {
    // The class property value is a binding: It’s a reference to the SwiftUISlider
    // value, which receives a reference to a @State variable value in ContentView.
    var value: Binding<Double>

    // Create the binding when you initialize the Coordinator
    init(value: Binding<Double>) {
      self.value = value
    }

    // Create a valueChanged(_:) action
    @objc func valueChanged(_ sender: UISlider) {
      self.value.wrappedValue = Double(sender.value)
    }
  }

  var thumbColor: UIColor = .white
  var minTrackColor: UIColor?
  var maxTrackColor: UIColor?

  @Binding var value: Double

  func makeUIView(context: Context) -> UISlider {
    let slider = UISlider(frame: .zero)
    slider.thumbTintColor = thumbColor
    slider.minimumTrackTintColor = minTrackColor
    slider.maximumTrackTintColor = maxTrackColor
    slider.value = Float(value)

    slider.setThumbImage(UIImage(), for: .normal)
    //slider.
    
    slider.addTarget(
      context.coordinator,
      action: #selector(Coordinator.valueChanged(_:)),
      for: .valueChanged
    )

    return slider
  }
    
    func doAnimation () {
        
        
        
        /*
        UIView.animate(withDuration: 0.2, animations: {
          self.setValue(0, animated:true)
        })
 */
    }
    
    

  func updateUIView(_ uiView: UISlider, context: Context) {
    // Coordinating data between UIView and SwiftUI view
    uiView.value = Float(self.value)
  }

  func makeCoordinator() -> SwiftUISlider.Coordinator {
    Coordinator(value: $value)
  }
}

#if DEBUG
struct SwiftUISlider_Previews: PreviewProvider {
  static var previews: some View {
    SwiftUISlider(
      thumbColor: .white,
      minTrackColor: .blue,
      maxTrackColor: .green,
      value: .constant(0.5)
    )
  }
}
#endif
