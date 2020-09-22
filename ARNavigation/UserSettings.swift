//
//  UserSettings.swift
//  ARNavigation
//
//  Created by Matteo Seragiotto.
//  Copyright © 2020 Matteo Seragiotto. All rights reserved.
//

import Foundation
import SwiftUI
import UIKit

/*
 Classe condivisa rappresentante le variabili di stato per impostare
 l'applicazione.
 */
class UserSettings: ObservableObject {
    
    //Variabili che contengono il nome dell'immagine da utilizzare (in base al colore scelto)
    @Published var arrow_image = UserDefaults.standard.string(forKey: "arrow_image")
    @Published var speaker_image = UserDefaults.standard.string(forKey: "speaker_image")
    
    //Stato per l'attivazione dell'audio spaziale
    @Published var spatialSound = UserDefaults.standard.bool(forKey: "spatialSound")
    
    //Stato per il salvataggio del nome del file caricato.
    @Published var fileName: String = ""
    
    //Stato che indica la selezione del file del percorso.
    @Published var fileSetted: Bool = false
    
    //Stato con il quale viene permessa la navigazione solo se si è prima caricato il file del percorso.
    @Published var allowNavigation = false
    
    //Stato che indica se l'utente ha visualizzato le istruzioni preliminari del percorso.
    @Published var instructionViewed = false
    
    //Stato che indica se l'utente ha visualizzato l'avviso di sicurezza
    @Published var warningViewed = false
    
    //Stato che permette l'avvio della sessione AR solo se è stato costruito correttamente il percorso virtuale.
    @Published var allowAugmentedReality = false
    
    //Valori disponibili per l'impostazione del tipo di output informativo e il valore che lo seleziona
    @Published var outputValues = ["Text", "Speech", "Both Text and Speech"]
    @Published var outputValue: Int = UserDefaults.standard.integer(forKey: "outputValue")
    
    //Valori di default per il colore di background e foreground dei pulsanti
    @Published var backgroundColor = UserDefaults.standard.color(forKey: "backgroundColor")
    @Published var foregroundColor = UserDefaults.standard.color(forKey: "foregroundColor")
    
    //Valori disponibili per le palette di colori dei pulsanti e valore che lo seleziona
    @Published var paletteValues = ["Black - White", "Orange - Black", "Gray - Black", "Blue - White", "Green - Black"]
    @Published var paletteValue: Int = UserDefaults.standard.integer(forKey: "paletteValue")
    
    //Valori di default per il colore di background e foreground del riquadro informazioni
    @Published var backgroundInfoColor = UserDefaults.standard.color(forKey: "backgroundInfoColor")
    @Published var foregroundInfoColor = UserDefaults.standard.color(forKey: "foregroundInfoColor")
    
    //Valori disponibili per le palette di colori del riquadro informazioni e valore che lo seleziona
    @Published var paletteInfoValues = ["Black - White", "Orange - Black", "Gray - Black", "Green - Black"]
    @Published var paletteInfoValue: Int = UserDefaults.standard.integer(forKey: "paletteInfoValue")
    
    //Stato che indica se sono state fornite le informazioni
    @Published var infoViewed = false
    
    //Stato del caricamento del percorso. Quando è true viene mostrata la navigazione AR.
    @Published var preparingSceneProgress: Bool = false
    
    /*
     Stati che gestiscono:
     - fine della navigazione
     - apparizione warning se utente troppo lontano dal percorso
     - infobox disegnato
     - speaker disegnato
     - freccia disegnata
     */
    @Published var endNavigation = false
    @Published var isTooFarAway = false
    @Published var isDrawed = false
    @Published var isSpeaked = false
    @Published var arrowDrawed = false
}

/*
 Estensione della classe UserDefault per poterla utilizzare con il tipo UIColor.
 Effettuo la conversione in Data.
 */
extension UserDefaults {

    func color(forKey key: String) -> UIColor? {
        guard let colorData = data(forKey: key) else { return nil }
        do {
            return try NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: colorData)
        } catch let error {
            print("ERROR: Color conversion. \(error.localizedDescription)")
            return nil
        }
    }

    func set(_ value: UIColor?, forKey key: String) {
        guard let color = value else { return }
        do {
            let data = try NSKeyedArchiver.archivedData(withRootObject: color, requiringSecureCoding: false)
            set(data, forKey: key)
        } catch let error {
            print("ERROR: color key data not saved. \(error.localizedDescription)")
        }
    }

}
