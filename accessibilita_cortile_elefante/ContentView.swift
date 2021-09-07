//
//  ContentView.swift
//  accessibilita_cortile_elefante
//
//  Created by Giacomo Papaluca on 18/08/21.
//

import SwiftUI
import RealityKit

struct ContentView : View {
    var body: some View {
        return ARViewContainer().edgesIgnoringSafeArea(.all)
    }
}

struct ARViewContainer: UIViewControllerRepresentable {
    typealias UIViewControllerType = CustomARView
    
    func makeUIViewController(context: Context) -> CustomARView {
        let customView = CustomARView(nibName: "CustomARView", bundle: .main)
        return customView
    }
    
    func updateUIViewController(_ uiViewController: CustomARView, context: Context) {
        
    }
   
    
}

#if DEBUG
struct ContentView_Previews : PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
#endif
