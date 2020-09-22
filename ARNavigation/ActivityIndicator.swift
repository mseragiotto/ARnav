//
//  ActivityIndicator.swift
//  ARNavigation
//
//  Created by Matteo Seragiotto.
//  Copyright © 2020 Matteo Seragiotto. All rights reserved.
//

import SwiftUI

/*
 Struct che realizza una View SwiftUI rappresentante
 l'animazione di caricamento.
 
 Come per la ARView, si costruisce la vista e la si aggiorna
 sfruttando i due metodi del protocollo UIViewRepresentable.
 */
struct ActivityIndicator: UIViewRepresentable {
    
    var isAnimating: Bool

    func makeUIView(context: UIViewRepresentableContext<Self>) -> UIActivityIndicatorView {
        UIActivityIndicatorView(style: UIActivityIndicatorView.Style.large)
    }
    
    func updateUIView(_ uiView: UIActivityIndicatorView, context: UIViewRepresentableContext<Self>) {
        isAnimating ? uiView.startAnimating() : uiView.stopAnimating()
    }
}
