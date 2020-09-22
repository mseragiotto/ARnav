//
//  CustomPoint.swift
//  ARNavigation
//
//  Created by Matteo Seragiotto.
//  Copyright © 2020 Matteo Seragiotto. All rights reserved.
//

import UIKit
import RealityKit
import Foundation

/*
 Classe rappresentante un punto intermedio del tracciato virtuale.
 Istanzia una sfera di raggio ridotto rispetto ai punti del tracciato.
 Estende le classi Entity (entità di RealityKit), HasModel (in quanto modello 3d)
 e HasAnchoring (in quanto ancorato nella scena ARKit.
 Viene inizializzato tramite colore e posizionamento nella scena virtuale.
 */
class CustomPoint: Entity, HasModel, HasAnchoring {
    
    /*
     L'implementazione è analoga a quella delle sfere, ma vengono usate dimensioni inferiori.
     */
    required init(color: UIColor) {
        super.init()
        self.components[ModelComponent] = ModelComponent(
            mesh: .generateSphere(radius: 0.05),
            materials: [UnlitMaterial(
                color: color)
            ]
        )
    }
    
    convenience init(color: UIColor, position: SIMD3<Float>) {
        self.init(color: color)
        self.position = position
    }
    
    required init() {
        fatalError("ERROR: init() has not been implemented")
    }
    
    func getPosition() -> SIMD3<Float> {
        return self.position
    }
}

