//
//  SetPathView.swift
//  ARNavigation
//
//  Created by Matteo Seragiotto.
//  Copyright © 2020 Matteo Seragiotto. All rights reserved.
//

import SwiftUI

/*
 View che rappresenta la pagina dove si carica il file del percorso.
 Premuto il pulsante di scelta, viene aperto il file manager nel quale
 sono evidenziati esclusivamente i file JSON. Se il file è conforme
 al caricamento verrà notificato, altrimenti verrà mostrato un errore.
 */
struct SetPathView: View {
    
    @EnvironmentObject var model: Model
    @EnvironmentObject var settings: UserSettings
    
    /*
     Stato con cui viene gestito il messaggio di errore in caso di .json non conforme.
     */
    @State private var showErrorAlert: Bool = false
    
    var body: some View {
        VStack {
            /*
             Se non è già stato selezionato un file di percorso viene reso
             possibile il caricamento di file .json conformi.
             */
            if !settings.fileSetted {
                
                Text("Route file not selected")
                    .font(.title)
                    Spacer()
                Button("Choose file") {
                    
                    /*
                     Picker per caricare documenti dall'esterno dell'app.
                     onPick prende il .json e lo utilizza per costruire il model. Se la costruzione
                     viene correttamente eseguita, vengono impostate le variabili di stato che
                     permettono la successiva navigazione, altrimenti viene mostrato un alert di errore.
                     */
                    let picker = DocumentPickerViewController(
                        supportedTypes: ["public.json"],
                        onPick: {   url in
                                //print("[DEBUG] Getting file url : \(url)")
                            if let fileContents = try? String(contentsOf: url) {
                                if self.model.setRoute(jsonString: fileContents) {
                                    self.settings.fileSetted = true
                                    self.settings.allowNavigation = true
                                    self.settings.fileName = url.lastPathComponent
                                } else {

                                    self.showErrorAlert = true
                                }

                            }
                        },
                        onDismiss: {
                            /*
                             Se si annulla la selezione, non viene fatto nulla.
                             */
                            //print("\n[DEBUG]: File picker dismissed\n")
                        }
                    )
                    UIApplication.shared.windows.first?.rootViewController?.present(picker, animated: true)
                }
                .padding()
                .background(Color(settings.backgroundColor!))
                .foregroundColor(Color(settings.foregroundColor!))
                .font(.title)
                .cornerRadius(30)
                .alert(isPresented: $showErrorAlert) {
                    Alert(title: Text("Error on loading").font(.title), message: Text("The selected JSON file is not a navigation path. Select another file.").font(.title), dismissButton: .default(Text("Continue")))
                }
                Spacer()
                
            /*
             Se è già stato selezionato un file .json viene autorizzata la navigazione,
             ed è possibile anche cambiare il percorso caricando un nuovo file.
            */
            } else {
                Text("File selected:")
                .font(.title)
                
                Text("\(settings.fileName)")
                    .italic()
                    .font(.title)
                    .padding()
                Spacer()
                
                /*
                 Pulsante che porta alla view adibita alla visualizzazione AR
                 */
                Button(action: {}) {
                    NavigationLink("CREATE AR ROUTE", destination: ARNavView())
                }.padding()
                .background(Color(settings.backgroundColor!))
                .foregroundColor(Color(settings.foregroundColor!))
                .font(.title)
                .cornerRadius(30)
                .accessibility(hint: Text("Tap three times to select the button."))
                Spacer()
            }
        }.navigationBarItems(trailing:
            HStack {
                if(settings.fileSetted) {
                    /*
                     Pulsante che permette di cambiare file del percorso
                     */
                    Button("Change file") {
                        let picker = DocumentPickerViewController(
                            supportedTypes: ["public.json"],
                            onPick: {   url in
                                    //print("[DEBUG] Getting file url : \(url)")
                                if let fileContents = try? String(contentsOf: url) {
                                    if self.model.setRoute(jsonString: fileContents) {
                                        self.settings.allowNavigation = true
                                        self.settings.fileName = url.lastPathComponent
                                    } else {
                                        self.showErrorAlert = true
                                    }
                                }
                            },
                            onDismiss: {
                                //print("\n[DEBUG]: File picker dismissed\n")
                            }
                        )
                        UIApplication.shared.windows.first?.rootViewController?.present(picker, animated: true)
                        
                    }
                }
            }
            
        )
    }
}

struct SetPathView_Previews: PreviewProvider {
    static var previews: some View {
        SetPathView()
    }
}

