//
//  MainView.swift
//  ARNavigation
//
//  Created by Matteo Seragiotto.
//  Copyright © 2020 Matteo Seragiotto. All rights reserved.
//

import SwiftUI
import RealityKit

/*
 View principale dell'app. Mostra i due pulsanti.
 */
struct MainView : View {
    
    @EnvironmentObject var settings: UserSettings
    
    var body: some View {
        NavigationView {
            VStack {
                Spacer()
                Button(action:{}){
                    NavigationLink((!settings.fileSetted ? "LOAD PATH" : "START NAVIGATION"), destination: SetPathView())
                }.padding()
                .background(Color(settings.backgroundColor!))
                .foregroundColor(Color(settings.foregroundColor!))
                .font(.title)
                .cornerRadius(30)
                .accessibility(hint: Text("Tap three times to select the button."))
                Spacer()
                Button(action: {}) {
                    NavigationLink("SETTINGS", destination: SettingsView())
                }.padding()
                .background(Color(settings.backgroundColor!))
                .foregroundColor(Color(settings.foregroundColor!))
                .font(.title)
                .cornerRadius(30)
                .accessibility(hint: Text("Tap three times to select the button."))
                Spacer()
                }.navigationBarTitle("AR Navigation")
        }
    }
}

struct MainView_Previews : PreviewProvider {
    static var previews: some View {
        MainView()
    }
}


