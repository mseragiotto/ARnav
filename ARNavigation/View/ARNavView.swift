//
//  ARNavView.swift
//  ARNavigation
//
//  Created by Matteo Seragiotto.
//  Copyright © 2020 Matteo Seragiotto. All rights reserved.
//

import SwiftUI
import RealityKit
import ARKit

/*
 View che mostra la scena AR. Prima di caricare completamente il percorso virtuale
 viene mostrata la schermata di caricamento, poi successivamente viene mostrata la scena.
 */

struct ARNavView : View {
    
    @EnvironmentObject var settings: UserSettings
    @EnvironmentObject var model: Model
    @State private var showInfo = true

    var body: some View {
        VStack {
            if !settings.instructionViewed {
                /*
                 Animazione di caricamento
                 */
                ActivityIndicator(isAnimating: true)
            }
            if (settings.allowNavigation) {
                ZStack{
                    if(!settings.instructionViewed) {
                        /*
                         Primo alert che mostra la prima informazione del percorso, la quale fornisce indicazioni
                         testuali per posizionarsi correttamente all'inizio del tragitto.
                         */
                        Text("")
                        .alert(isPresented: self.$showInfo) {
                            Alert(title: Text("BEFORE STARTING").font(.title), message: Text("Position yourself on the first point of the route according to the following instructions:\n\n\(self.model.route[0].getInfo())"), dismissButton: .default(Text("Continue")) {self.settings.instructionViewed = true })
                        }
                    }
                    /*
                     Una volta chiuso il primo alert, viene mostrato il pulsante START solo quando viene notificato il completamento del
                     caricamento del percorso, tramite la variabile di stato allowAugmentedReality. In questo caso viene nascosto dalla
                     visualizzazione e mostrata solamente la schermata AR.
                     */
                    if(settings.instructionViewed) {
                        StartARView().disabled(settings.allowAugmentedReality ? true : false).accessibility(hidden: settings.allowAugmentedReality ? true : false)
                        ZStack(alignment: .bottom) {
                            ARViewContainer().edgesIgnoringSafeArea(.all).opacity(settings.allowAugmentedReality ? 1 : 0).onDisappear() {
                                //print("\n[DEBUG]: ARVIEWCONTAINER DISAPPEARED\n")
                            }
                        }
                        .accessibilityElement(children: .ignore)
                        .accessibility(hidden: true)
                        /*
                         La disattivazione dell'accessibilità è dovuta al fatto che un ipotetico utente completamente cieco (che usa solo voice over) non può interagire con
                         la scena AR, che richiede la visione del percorso virtuale. Un utente ipovedente può interagire tramite le informazioni testuali/vocali
                         e tramite i pochi pulsanti a schermo appositamente adattati per essere riconoscibili.
                         */
                    }
                }
            }
            else {
                Text("You have to set a route before start navigation")
                .font(.title)
                .padding(60)
            }
        }.navigationBarBackButtonHidden(true)
    }
}

struct ARNavView_Previews: PreviewProvider {
    static var previews: some View {
       ARNavView()
    }
}
