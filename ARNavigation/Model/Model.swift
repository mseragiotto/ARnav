//
//  Model.swift
//  ARNavigation
//
//  Created by Matteo Seragiotto.
//  Copyright © 2020 Matteo Seragiotto. All rights reserved.
//

import UIKit
import AVFoundation

/*
 Struct rappresentante un singolo punto del percorso:
 - latitudine
 - longitudine
 - informazione
 
 Una possibile evoluzione consiste nel rendere l'informazione costituita
 da tre livelli informativi, ai quali corrisponde un'informazione più o meno
 dettagliata, in base alla conoscenza dell'utente.
 */
struct Point: Decodable {
    
    private let latitude: Double
    private let longitude: Double
    private let information: String
    
    init(latitude: Double, longitude: Double){
        self.latitude = latitude
        self.longitude = longitude
        self.information = ""
    }
    
    init(latitude: Double, longitude: Double, information: String){
        self.latitude = latitude
        self.longitude = longitude
        self.information = information
    }
    
    func getLat() -> Double {
        return self.latitude
    }
    
    func getLon() -> Double {
        return self.longitude
    }

    func getInfo() -> String {
        return self.information
    }

}

/*
 Classe model condivisa che rende pubblico l'array di punti del percorso,
 l'array di sfere, il testo dell'informazione corrente e il punto corrente.
 L'array viene riempito a partire dal file JSON costruito appositamente
 */
class Model: ObservableObject {
    @Published var route: [Point] = []
    @Published var currentInfo: String = ""
    @Published var sphereList: [CustomSphere] = []

    /*
     Intero rappresentante l'indice dell'array di sfere corrispondente al
     punto successivo più vicino all'utente, per la costruzione del percorso visivo.
     */
    @Published var currentRoutePoint: Int = 0
    
    init(){}
    
    /*
     Funzione che imposta il testo corrente da visualizzare. L'intero rappresenta
     l'indice del punto.
     */
    func setInfo(info: Int) {
        self.currentInfo = route[info].getInfo()
    }
    
    /*
     Tramite JSONDecoder viene automaticamente mappato il contenuto del file .json all'array
     di oggetti Point.
     */
    func setRoute(jsonString: String) -> Bool {
        let jsonData = jsonString.data(using: .utf8)!
        do {
            try route = JSONDecoder().decode([Point].self, from: jsonData)
            return true
        } catch let error {
            print("ERROE: loading of JSON file failed: \(error)")
        }
        return false
    }
    
    func incrementCurrentRoutePoint() {
        self.currentRoutePoint += 1
    }
    
    func endingGenerationOfPoints() {
        self.currentRoutePoint = self.sphereList.count
    }
    
}
