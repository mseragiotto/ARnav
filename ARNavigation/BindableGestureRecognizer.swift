//
//  BindableGestureRecognizer.swift
//  ARNavigation
//
//  Created by Matteo Seragiotto.
//  Copyright © 2020 Matteo Seragiotto. All rights reserved.
//

import Foundation
import UIKit

/*
 Classe di supporto per poter implementare la tap gesture sulle view
 nella scena AR. Necessaria per gestire i selettori Objective-C
 separatamente dal codice della ARView.
 In questo modo aggiungere una gesture risulta più "pulito"
 
 L'azione viene passata tramite closure.
 */

final class BindableGestureRecognizer: UITapGestureRecognizer {
    private var action: () -> Void
    
    init(action: @escaping () -> Void) {
        self.action = action
        super.init(target: nil, action: nil)
        self.addTarget(self, action: #selector(execute))
    }
    
    /*
     Il seguente metodo è esposto a Objective-C, per eseguire la closure al tap.
     */
    @objc private func execute() {
        action()
    }
}
