//
//  DocumentPickerViewController.swift
//  ARNavigation
//
//  Created by Matteo Seragiotto.
//  Copyright © 2020 Matteo Seragiotto. All rights reserved.
//

import UIKit

/*
 Classe che gestisce l'importazione di documenti esterni al bundle dell'app.
 Eredita la classe UIDocumentPickerViewController in modo da gestire l'evento di
 apertura del file manager e la sua chiusura.
 Viene chiamato l'inizializzatore della superclasse che filtra i file caricabili
 in base all'estensione, importandone una copia.
 */
class DocumentPickerViewController: UIDocumentPickerViewController {
    
    private let onDismiss: () -> Void
    private let onPick: (URL) -> ()
    
    /*
     Inizializzo le closure onDismiss e onPick con quelle ottenute in input,
     poi chiamo l'inizializzatore della classe superiore.
     */
    init(supportedTypes: [String], onPick: @escaping (URL) -> Void, onDismiss: @escaping () -> Void) {
        self.onDismiss = onDismiss
        self.onPick = onPick
        
        super.init(documentTypes: supportedTypes, in: .import)

        allowsMultipleSelection = false
        delegate = self
    }
    
    /*
     Richiesta l'implementazione dalla classe.
     */
    required init?(coder: NSCoder) {
        fatalError("ERROR: init(coder:) has not been implemented")
    }
}

/*
 Estensione che adotta il protocollo UIDocumentPickerDelegate, per ricevere gli eventi
 della classe principale.
 Chiamo le funzioni precedentemente inizializzate quando scelgo un file oppure torno indietro.
 */
extension DocumentPickerViewController: UIDocumentPickerDelegate {
    /*
     Funzione chiamata quando viene scelto un documento.
     */
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        onPick(urls.first!)
    }

    /*
     Funzione chiamata quando si annulla la scelta di un documento.
     */
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        onDismiss()
    }
}

