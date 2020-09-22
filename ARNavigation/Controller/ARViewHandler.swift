//
//  ARViewDelegate.swift
//  ARNavigation
//
//  Created by Matteo Seragiotto.
//  Copyright © 2020 Matteo Seragiotto. All rights reserved.
//

import ARKit

/*
 Classe che fornisce le informazioni sulla posizione e orientamento della camera rispetto
 alla scena AR di RealityKit.
 Vengono fornite due variabili rappresentanti il vettore della posizione e la matrice della trasformazione.
 Le informazioni sulla camera vengono ottenute estendendo la classe all'implementazione del
 protocollo ARSessionDelegate, che fornisce i metodi utili a tener traccia in real time
 delle informazioni sul tracking e sulla trasformata ad ogni frame.
 */

class ARViewHandler: NSObject, ObservableObject {
    
    @Published var currentPosition: SIMD3<Float>
    @Published var currentTransform: simd_float4x4
    
    override init() {
        self.currentPosition = [0.0,0.0,0.0]
        self.currentTransform = simd_float4x4()
    }
}

extension ARViewHandler: ARSessionDelegate {
    
    /*
     Funzione che informa il delegato di cambiamenti sulla qualità del tracking di ARKit.
     */
    func session(_ session: ARSession, cameraDidChangeTrackingState: ARCamera) {
        print("\nTRACKING STATUS: \(cameraDidChangeTrackingState.trackingState)\n")
    }
    
    /*
     Funzione che informa il delegato delle informazioni su posizione e orientamento della camera.
     */
    func session(_ session: ARSession, didUpdate: ARFrame) {
        guard (session.currentFrame?.camera) != nil else { return }
        self.currentPosition = [(didUpdate.camera.transform.columns.3.x), (didUpdate.camera.transform.columns.3.y), (didUpdate.camera.transform.columns.3.z)]
        self.currentTransform = didUpdate.camera.transform
            //print("[DEBUG] CAMERA POSITION: [\(didUpdate.camera.transform.columns.3.x), \(didUpdate.camera.transform.columns.3.y), \(didUpdate.camera.transform.columns.3.z)]")
    }
       
    func sessionWasInterrupted(_ session: ARSession) {
            //print("\n[DEBUG]: SESSION INTERRUPTED\n")
    }

}
