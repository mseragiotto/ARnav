//
//  SettingsView.swift
//  ARNavigation
//
//  Created by Matteo Seragiotto.
//  Copyright © 2020 Matteo Seragiotto. All rights reserved.
//

import SwiftUI


/*
 View che mostra le impostazioni dell'applicazione.
 */
struct SettingsView: View {
    
    @EnvironmentObject var settings: UserSettings
    
    var body: some View {

        /*
         Costruisco delle costanti Binding per poter modificare la colorazione dei pulsanti, delle
         informazioni, del tipo di output, dell'audio spazializzato, in base ai valori scelti con
         i picker/toggle nella View.
         Questo è dovuto al fatto che SwiftUI non fornisce un modo nativo per effettuare azioni
         in base alle selezioni di picker e toggle.
         */
        
        /*
         Binding per modificare e salvare la scelta della palette di colori dei pulsanti.
         */
        let modifier = Binding<Int>(get: {
            return self.settings.paletteValue
        }, set: {
            self.settings.paletteValue = $0
            switch (self.settings.paletteValue) {
                case 0:
                    self.settings.backgroundColor = UIColor.black
                    UserDefaults.standard.set(self.settings.backgroundColor, forKey: "backgroundColor")
                    self.settings.foregroundColor = UIColor.white
                    UserDefaults.standard.set(self.settings.foregroundColor, forKey: "foregroundColor")
                    UserDefaults.standard.set(0, forKey: "paletteValue")
                case 1:
                    self.settings.backgroundColor = UIColor.orange
                    UserDefaults.standard.set(self.settings.backgroundColor, forKey: "backgroundColor")
                    self.settings.foregroundColor = UIColor.black
                    UserDefaults.standard.set(self.settings.foregroundColor, forKey: "foregroundColor")
                    UserDefaults.standard.set(1, forKey: "paletteValue")
                case 2:
                    self.settings.backgroundColor = UIColor.lightGray
                    UserDefaults.standard.set(self.settings.backgroundColor, forKey: "backgroundColor")
                    self.settings.foregroundColor = UIColor.black
                    UserDefaults.standard.set(self.settings.foregroundColor, forKey: "foregroundColor")
                    UserDefaults.standard.set(2, forKey: "paletteValue")
                case 3:
                    self.settings.backgroundColor = UIColor.systemBlue
                    UserDefaults.standard.set(self.settings.backgroundColor, forKey: "backgroundColor")
                    self.settings.foregroundColor = UIColor.white
                    UserDefaults.standard.set(self.settings.foregroundColor, forKey: "foregroundColor")
                    UserDefaults.standard.set(3, forKey: "paletteValue")
                case 4:
                    self.settings.backgroundColor = UIColor.green
                    UserDefaults.standard.set(self.settings.backgroundColor, forKey: "backgroundColor")
                    self.settings.foregroundColor = UIColor.black
                    UserDefaults.standard.set(self.settings.foregroundColor, forKey: "foregroundColor")
                    UserDefaults.standard.set(4, forKey: "paletteValue")
            default:
                self.settings.backgroundColor = UIColor.systemBlue
                UserDefaults.standard.set(self.settings.backgroundColor, forKey: "backgroundColor")
                self.settings.foregroundColor = UIColor.white
                UserDefaults.standard.set(self.settings.foregroundColor, forKey: "foregroundColor")
                UserDefaults.standard.set(3, forKey: "paletteValue")
            }
            
        } )
        
        /*
         Binding per modificare e salvare la scelta della palette di colori del riquadro informazioni.
         */
        let modifier1 = Binding<Int>(get: {
            return self.settings.paletteInfoValue
        }, set: {
            self.settings.paletteInfoValue = $0
            switch (self.settings.paletteInfoValue) {
                case 0:
                    self.settings.backgroundInfoColor = UIColor.black
                    UserDefaults.standard.set(self.settings.backgroundInfoColor, forKey: "backgroundInfoColor")
                    self.settings.foregroundInfoColor = UIColor.white
                    UserDefaults.standard.set(self.settings.foregroundInfoColor, forKey: "foregroundInfoColor")
                    self.settings.arrow_image = "blackwhite"
                    UserDefaults.standard.set(self.settings.arrow_image, forKey: "arrow_image")
                    self.settings.speaker_image = "sblackwhite"
                    UserDefaults.standard.set(self.settings.speaker_image, forKey: "speaker_image")
                    UserDefaults.standard.set(0, forKey: "paletteInfoValue")
                case 1:
                    self.settings.backgroundInfoColor = UIColor.orange
                    UserDefaults.standard.set(self.settings.backgroundInfoColor, forKey: "backgroundInfoColor")
                    self.settings.foregroundInfoColor = UIColor.black
                    UserDefaults.standard.set(self.settings.foregroundInfoColor, forKey: "foregroundInfoColor")
                    self.settings.arrow_image = "orangeblack"
                    UserDefaults.standard.set(self.settings.arrow_image, forKey: "arrow_image")
                    self.settings.speaker_image = "sorangeblack"
                    UserDefaults.standard.set(self.settings.speaker_image, forKey: "speaker_image")
                    UserDefaults.standard.set(1, forKey: "paletteInfoValue")
                case 2:
                    self.settings.backgroundInfoColor = UIColor.lightGray
                    UserDefaults.standard.set(self.settings.backgroundInfoColor, forKey: "backgroundInfoColor")
                    self.settings.foregroundInfoColor = UIColor.black
                    UserDefaults.standard.set(self.settings.foregroundInfoColor, forKey: "foregroundInfoColor")
                    self.settings.arrow_image = "grayblack"
                    UserDefaults.standard.set(self.settings.arrow_image, forKey: "arrow_image")
                    self.settings.speaker_image = "sgrayblack"
                    UserDefaults.standard.set(self.settings.speaker_image, forKey: "speaker_image")
                    UserDefaults.standard.set(2, forKey: "paletteInfoValue")
                case 3:
                    self.settings.backgroundInfoColor = UIColor.green
                    UserDefaults.standard.set(self.settings.backgroundInfoColor, forKey: "backgroundInfoColor")
                    self.settings.foregroundInfoColor = UIColor.black
                    UserDefaults.standard.set(self.settings.foregroundInfoColor, forKey: "foregroundInfoColor")
                    self.settings.arrow_image = "greenblack"
                    UserDefaults.standard.set(self.settings.arrow_image, forKey: "arrow_image")
                    self.settings.speaker_image = "sgreenblack"
                    UserDefaults.standard.set(self.settings.speaker_image, forKey: "speaker_image")
                    UserDefaults.standard.set(3, forKey: "paletteInfoValue")
            default:
                self.settings.backgroundInfoColor = UIColor.orange
                UserDefaults.standard.set(self.settings.backgroundInfoColor, forKey: "backgroundInfoColor")
                self.settings.foregroundInfoColor = UIColor.black
                UserDefaults.standard.set(self.settings.foregroundInfoColor, forKey: "foregroundInfoColor")
                self.settings.arrow_image = "orangeblack"
                UserDefaults.standard.set(self.settings.arrow_image, forKey: "arrow_image")
                self.settings.speaker_image = "sorangeblack"
                UserDefaults.standard.set(self.settings.speaker_image, forKey: "speaker_image")
                UserDefaults.standard.set(1, forKey: "paletteInfoValue")
            }
            
        } )
        
        /*
         Binding per modificare e salvare la scelta del tipo di output delle informazioni.
         */
        let modifier2 = Binding<Int>(get: {
            return self.settings.outputValue
        }, set: {
            self.settings.outputValue = $0
            switch (self.settings.outputValue) {
                case 0://text
                    UserDefaults.standard.set(0, forKey: "outputValue")
                case 1://speech
                    UserDefaults.standard.set(1, forKey: "outputValue")
                case 2://both text and speech
                    UserDefaults.standard.set(2, forKey: "outputValue")
            default:
                UserDefaults.standard.set(0, forKey: "outputValue")
            }
            
        } )
        
        /*
         Binding per modificare e salvare la scelta sull'audio spazializzato
         */
        let modifier3 = Binding<Bool>(get: {
            return self.settings.spatialSound
        }, set: {
            self.settings.spatialSound = $0
            switch (self.settings.spatialSound) {
                case true://spatialSound on
                    UserDefaults.standard.set(true, forKey: "spatialSound")
                case false://spatialSound off
                    UserDefaults.standard.set(false, forKey: "spatialSound")
            }
            
        } )
        
        /*
         La dichiarazione di costanti all'interno del body della View necessita di forzare la restituzione
         della View costruita con i metodi SwiftUI
         */
        return Form {
            Section(header: Text("Route Informations") .font(.headline).fontWeight(.heavy)) {
                Picker(selection: modifier2, label: Text("Mode").font(.subheadline)) {
                    ForEach(0 ..< settings.outputValues.count, id: \.self) {
                        Text(self.settings.outputValues[$0])
                    }
                }
            }
                    
            Section(header: Text("Buttons Palettes") .font(.headline).fontWeight(.heavy)) {
                Picker(selection: modifier, label: Text("Combination").font(.subheadline)) {
                    ForEach(0 ..< settings.paletteValues.count, id: \.self) {
                        Text(self.settings.paletteValues[$0])
                    }
                }
            }
            
            Section(header: Text("Navigation interface Palettes") .font(.headline).fontWeight(.heavy)) {
                Picker(selection: modifier1, label: Text("Combination").font(.subheadline)) {
                    ForEach(0 ..< settings.paletteInfoValues.count, id: \.self) {
                        Text(self.settings.paletteInfoValues[$0])
                    }
                }
            }
            
            Section(header: Text("Additional settings") .font(.headline).fontWeight(.heavy)) {
                Toggle(isOn: modifier3) {
                    Text("Spatialized audio on points").font(.subheadline)
                }
            }
                
            }.navigationBarTitle("Settings", displayMode: .inline)
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
