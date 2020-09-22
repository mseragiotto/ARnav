//
//  CustomSphere.swift
//  ARNavigation
//
//  Created by Matteo Seragiotto.
//  Copyright © 2020 Matteo Seragiotto. All rights reserved.

import UIKit
import RealityKit
import Foundation

/*
 Classe rappresentante un punto del tracciato virtuale.
 Estende le classi Entity (entità di RealityKit), HasModel (in quanto modello 3d)
 e HasAnchoring (in quanto ancorato nella scena ARKit).
 Utilizza il mesh .generateSphere, che genera sfere semplici.
 Viene inizializzato tramite colore e posizionamento nella scena virtuale.
*/
class CustomSphere: Entity, HasModel, HasAnchoring {
    
    required init(color: UIColor) {
        super.init()
        self.components[ModelComponent] = ModelComponent(
            mesh: .generateSphere(radius: 0.2),
            materials: [UnlitMaterial(
                color: color)
                
                /*
                 //Materiale che riflette la luce. Da testare su device più nuovi.
                 materials: [SimpleMaterial(
                     color: color,
                     isMetallic: false)
                 */
            ]
        )
    }
    
    /*
     Inizializzatore secondario utilizzato per aggiungere l'inizializzazione
     della posizione
     */
    convenience init(color: UIColor, position: SIMD3<Float>) {
        self.init(color: color)
        self.position = position
    }
    
    /*
     Implementazione "vuota" dell'inizializzatore init().
     Inserita in quanto richiesta dalla superclasse Entity.
     */
    required init() {
        fatalError("[ERROR]: init() has not been implemented")
    }
    
    func getPosition() -> SIMD3<Float> {
        return self.position
    }
}
