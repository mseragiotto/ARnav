//
//  StartARView.swift
//  ARNavigation
//
//  Created by Matteo Seragiotto.
//  Copyright © 2020 Matteo Seragiotto. All rights reserved.
//

import SwiftUI

/*
 View visualizzata quando il file del percorso è stato correttamente processato
 e la scena AR è pronta ad essere mostrata.
 La view mostra il pulsante da premere per avviare la navigazione e un'avviso di
 sicurezza.
 Il pulsante viene mostrato quando il valore condiviso preparingSceneProgress viene
 settato a 1, da parte della view preposta alla costruzione della scena AR.
 Il setting del valore a 1 indica quindi il via alla visualizzazione della ARView,
 che risulta essere pronta a permettere la navigazione.
 */

struct StartARView: View {
    
    @EnvironmentObject var settings: UserSettings
    @EnvironmentObject var model: Model
    
    @State var showAlert = false
    @State var showInfo = false

    
    var body: some View {
        VStack {
            if(!settings.preparingSceneProgress) {
                ActivityIndicator(isAnimating: true)
            } else {
                Button(action: {self.showAlert = true} ) {
                    Text("START").font(.title)
                }
                .padding()
                .background(Color(self.settings.backgroundColor!))
                .foregroundColor(Color(self.settings.foregroundColor!))
                .cornerRadius(30)
                .font(.title)
                .opacity(self.settings.preparingSceneProgress ? 1 : 0)
                .alert(isPresented: self.$showAlert){
                    Alert(title: Text("WARNING").font(.title), message: Text("Please pay attention: the virtual route may not perfectly match the real road layout.\nDo not take the journey if you are not fully sure that you can recognize any dangers.").font(.title), dismissButton: .default(Text("Got it!")){
                        self.settings.allowAugmentedReality = true
                        } )
                }
            }
        }
    }
}


struct StartARView_Previews: PreviewProvider {
    static var previews: some View {
        StartARView()
    }
}

