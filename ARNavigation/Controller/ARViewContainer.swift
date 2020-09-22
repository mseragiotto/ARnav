//
//  ARViewContainer.swift
//  ARNavigation
//
//  Created by Matteo Seragiotto.
//  Copyright © 2020 Matteo Seragiotto. All rights reserved.
//

import SwiftUI
import RealityKit
import ARKit
import CoreLocation
import AVFoundation

/*
 View contenente la ARView di RealityKit e ARKit, costruita implementando il protocollo UIViewRepresentable.
 Il metodo makeUIView crea la ARView e gestisce la costruzione dinamica del percorso.
 Il metodo updateUIView gestisce gli elementi di interfaccia sulla schermata AR.
 */

struct ARViewContainer: UIViewRepresentable {
    
    
    @EnvironmentObject var model: Model
    @EnvironmentObject var settings: UserSettings
    @EnvironmentObject var arViewHandler: ARViewHandler
    
    /*
     Proprietà calcolata che restituisce in tempo reale la posizione del dispositivo nell'ambiente virtuale.
     */
    var userCameraPosition: SIMD3<Float> {
        return arViewHandler.currentPosition
    }
    
    /*
     Proprietà calcolata che restituisce in tempo reale la trasformata del dispositivo (la matrice di trasformazione)
     */
    var userTransform: simd_float4x4 {
        return arViewHandler.currentTransform
    }
    
    /*
     Metodo con cui viene impostata e costruita la ARView, che istanzia una sessione ARKit + RealityKit.
     La configurazione permette il tracking completo del movimento ed il riconoscimento del piano orizzontale a terra,
     per potervi piazzare i punti del percorso. L'allineamento è legato solamente alla gravità, in quanto l'orientamento
     dipende sempre dal posizionamento dell'utente sul primo punto del percorso secondo le istruzioni.
     */
    func makeUIView(context: Context) -> ARView {
        
        /*
         Configurazione ARView
         */
        let arView = ARView(frame: .zero)
        
        /*
         Impostazioni per disattivare VoiceOver durante la sessione AR
         */
        arView.accessibilityTraits = UIAccessibilityTraits.allowsDirectInteraction
        arView.accessibilityElementsHidden = true
        
        /*
         View che istruisce l'utente a riconoscere il piano orizzontale a terra.
         */
        arView.addCoaching()
        
        let config = ARWorldTrackingConfiguration()
        arView.session.delegate = context.coordinator
        config.planeDetection = .horizontal
        config.worldAlignment = .gravity
        
        /*
         Se il dispositivo in uso possiede il sensore LIDAR, viene attivata la ricostruzione
         della scena. [NON TESTATO]
        
         Questa caratteristica dovrebbe rendere il tracking ed il posizionamento dei punti più
         preciso, in quanto nella scena AR viene aggiunta la riproduzione tridimensionale dell'
         ambiente circostante, rendendo il calcolo della posizione non più dipendente dalla sola
         analisi delle immagini della camera, ma anche delle profondità e delle distanze.
         */
        if ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) {
            config.sceneReconstruction = .mesh
            /*
             Le seguenti impostazioni dovrebbero (in quanto non testato) permettere di nascondere
             il percorso se ci sono degli ostacoli visivi, e di aggiungere la fisica reale nel caso
             in cui si voglia succcessivamente implementare delle animazioni sulle sfere della scena.
             */
            arView.environment.sceneUnderstanding.options.insert(.occlusion)
            arView.environment.sceneUnderstanding.options.insert(.physics)
        }
        
        /*
         Disabilitazione degli effetti grafici più "pesanti". [NECESSARIO PER SOLA DISPONIBILITA' DI IPHONE 7]
         La sessione AR viene avviata, con le impostazioni di reset in caso di chiusura della view.
         */
        arView.renderOptions.insert([.disableMotionBlur, .disableHDR, .disableCameraGrain, .disableAREnvironmentLighting])
            //arView.debugOptions.insert([/*.showStatistics,*/ .showWorldOrigin])
        arView.session.run(config, options: [.resetTracking, .removeExistingAnchors, .resetSceneReconstruction])
        
        /*
         Utilizzo del piano orizzontale (che deve essere riconosciuto da ARKit) come base su cui
         ancorare i punti del percorso.
         
         La view di coaching permette all'utente di muovere correttamente il dispositivo per facilitare
         il riconoscimento del piano orizzontale del terreno. Solo quando è riconosciuto viene istanziato
         nella costante plane.
         */
        let plane = AnchorEntity(plane: .horizontal)
        arView.scene.addAnchor(plane)
        
        /*
         Carico il punto di partenza e lo aggancio al piano (nel momento in cui verrà riconosciuto).
         */
        let startPoint = CustomSphere(color: .orange, position: [0, -1, 0])
        model.sphereList.append(startPoint)
        plane.addChild(startPoint)
        
        /*
         Precaricamento del file audio da utilizzare per l'audio spazializzato sui punti,
         se selezionato.
        */
        let resource = preloadSpatialAudio()
        
        /*
         L'intera costruzione dinamica del percorso avviene in background, con l'unica eccezione della creazione
         dei punti nella scena, che richiede l'esecuzione nel main thread (in maniera sincrona).
         La sincronicità delle costruzioni grafiche genera dei piccoli freeze (su iPhone 7), e lo stesso avviene
         con la creazione dei punti ed il loro inserimento nel model.
         L'attesa di 4 secondi è necessaria in modo che ARViewHandler inizi a processare i dati della camera, cosa
         che richiede un breve lasso di tempo dall'avvio della sessione AR. [CREDO DIPENDA DAL MODELLO DI IPHONE USATO].
         */
        DispatchQueue.global().asyncAfter(deadline: .now() + 4.0) {
            var audioController: AudioPlaybackController
            let startCoordinate: CLLocation = CLLocation(latitude: self.model.route[0].getLat(), longitude: self.model.route[0].getLon())
            var coordinate: CLLocation
            var bearing, distance: Double
            var firstBearing = 0.0
            
            for item in 1...self.model.route.count-1 {
                coordinate = CLLocation(latitude: self.model.route[item].getLat(), longitude: self.model.route[item].getLon())
                if(item == 1) {
                    /*
                     Correzione necessaria affichè il percorso venga generato frontalmente al dispositivo.
                     Utilizzando l'allineamento .gravity, non vi sono riferimenti ai punti cardinali, di default l'angolo di orientamento
                     è perfettamente di fronte al dispositivo a 270°.
                     */
                    firstBearing = 270 - self.getBearingBetweenTwoPoints(point1: startCoordinate, point2: coordinate)
                    
                }
                bearing = self.getBearingBetweenTwoPoints(point1: startCoordinate, point2: coordinate) + firstBearing
                    //print("[DEBUG]: bearing angle from 0 and \(item): \(bearing) ")
                distance = startCoordinate.distance(from: coordinate)
                DispatchQueue.main.sync {
                    self.model.sphereList.append(CustomSphere(color: .yellow, position: self.getNextPoint(distance: distance, bearing: bearing)))
                }
                
                /*
                 Il precedente ciclo costruisce ogni singola sfera con relativa posizione del punto che rappresenta.
                 Queste sfere, raccolte nel model, verranno inserite nella scena man mano che l'utente si muove lungo il percorso.
                 */
            }
                //print("[DEBUG]: Sphere count: \(self.model.sphereList.count)")
            
            /*
             Imposto il valore di preparazione della scena a true, così che appaia il pulsante start per avviare
             la navigazione.
             */
            DispatchQueue.main.sync {
                self.settings.preparingSceneProgress = true
            }
            
            /*
             Aggancio il primo punto al piano
             */
            plane.addChild(self.model.sphereList[1])
            
            /*
             Se l'impostazione "spatial sound" è selezionata, viene riprodotto un suono spazializzato che proviene dal punto
             successivo da raggiungere.
             */
            if (self.settings.spatialSound) {
                if (resource != nil) {
                    audioController = self.model.sphereList[1].prepareAudio(resource!)
                    audioController.play()
                } else {
                    print("\nERROR: spatial audio file not loaded properly")
                }
            }

            /*
             Le operazioni grafiche necessitano di essere eseguite nel thread principale.
             Disegno il tratteggio.
             */
            DispatchQueue.main.sync {
                self.drawLine(startPoint: self.model.sphereList[0].getPosition(), endPoint: self.model.sphereList[1].getPosition(), anchor: plane)
            }
            
            /*
             Ciclo per il numero di punti del percorso:
             Ad eccezione del punto di partenza e del primo punto, i successivi vengono disegnati su schermo quando l'utente
             si trova a meno di un metro dal punto verso cui sta camminando. In questo modo a chi naviga vengono indicate le singole
             traiettorie punto-punto fino ad arrivare alla fine del percorso. Ogni nuovo punto disegnato elimina l'ultimo
             tra i precedenti.
             
             ALGORITMO CREAZIONE E RIMOZIONE DINAMICA DEI PUNTI
             
             - HO UNO STATO CHE INDICA A QUALE PUNTO MI TROVO PIU' VICINO (CURRENTROUTEPOINT)
             - FINO A QUANDO NON TERMINO IL PERCORSO
             - - CONTROLLO IL NEXTPOINT CHE RESTITUISCE LA MIA POSIZIONE (SE E' VICINO SARA' CURRENTROUTEPOINT+1, ALTRIMENTI è CURRENTROUTEPOINT)
             [FUNZIONE NEARESTPOINT CON DATO RAGGIO DI DISTANZA MINIMO CONSIDERATO]
             - - - SE è UGUALE AL CURRENTROUTEPOINT, NON FACCIO NULLA (SIGNIFICA CHE DEVO AVVICINARMI DI PIU' AL CURRENTROUTEPOINT)
             - - - SE è MAGGIORE DI UNO DEL CURRENTROUTEPOINT, SIGNIFICA CHE DEVO FAR APPARIRE IL PUNTO SUCCESSIVO AL NEXTPOINT
             - - - - DISEGNO IL NEXTPOINT + 1
             - - - - DISEGNO IL TRATTEGGIO TRA IL NEXTPOINT ED IL NEXTPOINT+1
             - - - - AGGIORNO LO STATO CURRENTROUTEPOINT AL NEXTPOINT
             - IL CICLO RIPARTE
             */
            
            while(self.model.currentRoutePoint < self.model.sphereList.count-1) {
                let nextPoint = self.nearestPoint(radius: 1.0)
                if (nextPoint == self.model.currentRoutePoint) {
                        //print("[DRAWING POINTS DEBUG] -> NOTHING APPEAR, USER HAVE TO WALK TO THE NEXT POINT.")
                } else if (nextPoint == self.model.currentRoutePoint + 1)  {
                        //print("[DRAWING POINTS DEBUG] -> CHANGING NEXTPOINT TO SHOW NEW POINT.")
                    if (nextPoint+1 < self.model.sphereList.count) {
                        if(nextPoint >= 3) {
                            self.removePreviousPoint(anchor: plane)
                        }
                        plane.addChild(self.model.sphereList[nextPoint+1])
                    
                        /*
                         Gestione dell'audio spaziale all'apparizione dei nuovi punti
                         */
                        if (self.settings.spatialSound) {
                            if (resource != nil) {
                                self.model.sphereList[nextPoint].stopAllAudio()
                                audioController = self.model.sphereList[nextPoint+1].prepareAudio(resource!)
                                audioController.play()
                            } else {
                                print("\nERROR: spatial audio file not loaded properly")
                            }
                        }
                                                
                        DispatchQueue.main.sync {
                            self.drawLine(startPoint: self.model.sphereList[nextPoint].getPosition(), endPoint: self.model.sphereList[nextPoint+1].getPosition(), anchor: plane)
                            self.model.incrementCurrentRoutePoint()
                            self.settings.infoViewed = false
                        }
                    } else {
                            //print("[DRAWING POINTS DEBUG] -> ENDING TO DRAW POINTS")
                        DispatchQueue.main.sync {
                            self.model.incrementCurrentRoutePoint()
                            /*
                             Modifico lo stato che gestisce la visualizzazione delle informazioni.
                             Aggiunto il nuovo punto, devo visualizzare la sua informazione.
                             */
                            self.settings.infoViewed = false
                        }
                    }
                } else if (nextPoint == -1) {
                        //print("[DRAWING POINTS DEBUG] -> FORCING END")
                    /*
                     Caso in cui il punto successivo non esiste (punto finale)
                     */
                    DispatchQueue.main.sync {
                        //print("[DEBUG]: End of navigation")
                        self.model.endingGenerationOfPoints()
                    }
                }
                    //print("[DRAWING POINTS DEBUG]: currentRoutePoint = \(self.model.currentRoutePoint) ; nearestPoint = \(nextPoint) ; cameraPosition: \(self.userCameraPosition)")
            }
                //print("\n\nROUTE COUNT: \(self.model.route.count)")
        }
        return arView
    }
    
    /*
     Impostazione del coordinatore della View, in questo caso la classe ARViewHandler, che implementa il
     protocollo ARSessionDelegate, con il quale ottengo l'aggiornamento in tempo reale della posizione della camera.
     */
    func makeCoordinator() -> ARViewHandler {
        arViewHandler
    }
    
    /*
     Funzione che aggiorna la scena durante la navigazione, frame per frame.
     All'interno viene gestita la visualizzazione delle informazioni sul percorso, viene mostrata
     la freccia indicatrice della direzione da seguire e l'eventuale tasto per ripetere l'audio.
     */
    func updateUIView(_ uiView: ARView, context: Context) {

        /*
         Definisco i limiti dello schermo, per poter posizionare correttamente il riquadro delle informazioni
         e la freccia
         */
        let bounds = UIScreen.main.bounds
        let width = bounds.size.width
        let height = bounds.size.height
        
        /*
         Il riquadro informativo appare contestualmente all'apparizione del nuovo punto del percorso, se l'informazione
         non è vuota.
         Quando viene riconosciuto il piano stradale da ARKit, con conseguente visualizzazione del primo tratto del percorso,
         apparirà la freccia indicatrice.
         */
        if(uiView.scene.anchors.first != nil && uiView.scene.anchors.first!.isAnchored && uiView.scene.anchors.first!.isActive) {
            
            /*
             L'aggiornamento dell'orientamento della freccia avviene se è stata effettivamente inserita come view e se sono presenti
             punti ancorati al piano, il quale viene istanziato una volta riconosciuto da ARKit.
            */
            if(uiView.subviews.count == 2 && model.currentRoutePoint == 0 && !settings.arrowDrawed) {
                let imageView = UIImageView(image: UIImage(named: settings.arrow_image!)!)
                
                /*
                 Impostazioni che centrano in basso la freccia [testate solo con iPhone 7]
                 */
                imageView.frame = CGRect(x: width/2.7, y: height/1.2, width: 100, height: 100)
                uiView.addSubview(imageView)
                uiView.bringSubviewToFront(imageView)
                settings.arrowDrawed = true
            }
            
            if(uiView.subviews.count > 2  && uiView.scene.anchors.count != 0 && uiView.scene.anchors[0].children.count > 1) {
                
                /*
                 Gestione visualizzazione riquadro informazioni e icona speaker, in base all'impostazione di output scelta.
                 Per prima cosa viene aggiornata l'informazione corrente, poi in base all'opzione viene gestita la
                 visualizzazione dei relativi elementi grafici.
                 */
                if(!settings.infoViewed && model.currentRoutePoint != 0) {
                    model.setInfo(info: model.currentRoutePoint)

                    /*
                     Caso opzione solo testo.
                     -  Se l'informazione non è vuota ed è stato precedentemente disegnato l'infobox,
                        cancello e ridisegno il nuovo riquadro.
                     -  Se al punto precedente non ho disegnato il riquadro, allora lo disegno.
                     -  Se al punto precedente ho disegnato il riquadro, ma ora non ho testo da
                        visualizzare, cancello il precedente.
                     */
                    if(settings.outputValue == 0) {
                        if(model.currentInfo != "" && settings.isDrawed) {
                            uiView.subviews[uiView.subviews.count-2].removeFromSuperview()
                            if(createAndInsertInfoBox(rootView: uiView, width: width)) {
                                print("[DEBUG]: Infobox correctly added to ARView")
                            } else {
                                print("\nERROR: Infobox unavailable")
                            }
                            
                        } else if(model.currentInfo != "" && !settings.isDrawed) {
                            if(createAndInsertInfoBox(rootView: uiView, width: width)) {
                                print("[DEBUG]: Infobox correctly added to ARView")
                                settings.isDrawed = true
                            } else {
                                print("\nERROR: Infobox unavailable")
                            }
                            
                        } else if(model.currentInfo == "" && settings.isDrawed) {
                            uiView.subviews[uiView.subviews.count-2].removeFromSuperview()
                            settings.isDrawed = false
                        }
                    }
                    
                    /*
                     Caso opzione solo audio.
                     -  Se l'informazione non è vuota ed è stato precedentemente disegnato lo speaker,
                        cancello e ridisegno il nuovo speaker (che riprodurrà la nuova informazione).
                     -  Se al punto precedente non ho disegnato lo speaker, allora lo disegno.
                     -  Se al punto precedente ho disegnato lo speaker, ma ora non ho testo da
                        riprodurre, cancello il precedente.
                     */
                    if(settings.outputValue == 1) {
                    
                        if(model.currentInfo != "" && settings.isSpeaked) {
                            uiView.subviews[uiView.subviews.count-2].removeFromSuperview()
                            if(createAndInsertSpeaker(rootView: uiView, width: width, height: height)) {
                                print("[DEBUG]: Speaker correctly added to ARView")
                            } else {
                                print("\nERROR: Speaker unavailable")
                            }
                            
                        } else if(model.currentInfo != "" && !settings.isSpeaked) {
                            if(createAndInsertSpeaker(rootView: uiView, width: width, height: height)) {
                                print("[DEBUG]: Speaker correctly added to ARView")
                                settings.isSpeaked = true
                            } else {
                                print("\nERROR: Speaker unavailable")
                            }
                        } else if(model.currentInfo == "" && settings.isSpeaked) {
                            uiView.subviews[uiView.subviews.count-2].removeFromSuperview()
                            settings.isSpeaked = false
                        }
                        /*
                         Sintesi vocale dell'informazione.
                         */
                        speechInfo()
                    }
                    
                    /*
                     Caso opzione testo e audio. Vengono gestiti le stesse situazioni dei casi
                     precedenti.
                     */
                    if(settings.outputValue == 2) {
                                
                        if(model.currentInfo != "" && settings.isDrawed && settings.isSpeaked) {
                            uiView.subviews[uiView.subviews.count-2].removeFromSuperview()
                            uiView.subviews[uiView.subviews.count-2].removeFromSuperview()
 
                            if(createAndInsertInfoBox(rootView: uiView, width: width)) {
                                print("[DEBUG]: Infobox correctly added to ARView")
                            } else {
                                print("\nERROR: Infobox unavailable")
                            }
                            if(createAndInsertSpeaker(rootView: uiView, width: width, height: height)) {
                                print("[DEBUG]: Speaker correctly added to ARView")
                            } else {
                                print("\nERROR: Speaker unavailable")
                            }
                            
                        } else if(model.currentInfo != "" && !settings.isDrawed && !settings.isSpeaked) {
      
                            if(createAndInsertInfoBox(rootView: uiView, width: width)) {
                                print("[DEBUG]: Infobox correctly added to ARView")
                                settings.isDrawed = true
                            } else {
                                print("\nERROR: Infobox unavailable")
                            }
                            if(createAndInsertSpeaker(rootView: uiView, width: width, height: height)) {
                                print("[DEBUG]: Speaker correctly added to ARView")
                                settings.isSpeaked = true
                            } else {
                                print("\nERROR: Speaker unavailable")
                            }
 
                        } else if(model.currentInfo == "" && settings.isDrawed && settings.isSpeaked) {
                            uiView.subviews[uiView.subviews.count-2].removeFromSuperview()
                            uiView.subviews[uiView.subviews.count-2].removeFromSuperview()
                            settings.isDrawed = false
                            settings.isSpeaked = false
                        }
                        /*
                         Sintesi vocale dell'informazione.
                         */
                        speechInfo()
                    }
                    /*
                     Quando infoViewed è true, non vado a ricostruire il riquadro e/o lo speaker.
                     */
                    settings.infoViewed = true
                }
                
                /*
                 Messaggio di allerta se l'utente si sta allontanando troppo dal percorso. Il messaggio appare superati
                 15 metri di distanza dal percorso (inteso come il currentRoutePoint), e scompare una volta ritornati
                 nel raggio di 15 metri.
                */
                if(distanceFromPoint(point: model.sphereList[model.currentRoutePoint].getPosition()) > 15 && settings.isTooFarAway == false) {
                    let alertView = UITextView(frame: CGRect(x: width/12, y: height/3, width: width/1.2, height: 150))
                    alertView.backgroundColor = settings.backgroundInfoColor
                    alertView.textColor = settings.foregroundInfoColor
                    alertView.isEditable = false
                    alertView.isSelectable = false
                    alertView.textAlignment = NSTextAlignment.center
                    alertView.font = UIFont.preferredFont(forTextStyle: .title1)
                    alertView.layer.cornerRadius = 20
                    alertView.text = "WARNING, YOU ARE GOING AWAY FROM THE PATH"
                    
                    /*
                     Inserendo la UIView all'indice 1, è semplice poterla eliminare quando l'utente ritorna nel raggio di 15 metri.
                     */
                    if(uiView.subviews.first != nil) {
                        uiView.insertSubview(alertView, aboveSubview: uiView.subviews.first!)
                    } else {
                        print("\nERROR: first subview is nil. AlertView unavailable.")
                    }
                    settings.isTooFarAway = true
                }
                if(settings.isTooFarAway) {
                    if(distanceFromPoint(point: model.sphereList[model.currentRoutePoint].getPosition()) < 15) {
                        uiView.subviews[1].removeFromSuperview()
                        settings.isTooFarAway = false
                    }
                }
                
                /*
                 La freccia è orientata verso currentRoutePoint, aggiornata ad ogni frame. E' inserita come ultima
                 subview.
                 */
                if(model.currentRoutePoint+1 < model.sphereList.count && model.currentRoutePoint != model.sphereList.count-1 && uiView.subviews.last != nil) {
                    uiView.subviews.last!.transform = CGAffineTransform(rotationAngle: CGFloat(getAngleFrom(target: model.sphereList[model.currentRoutePoint+1].transform.matrix)))
                }
                
                /*
                 Quando l'utente arriva a destinazione, l'app viene chiusa tramite pressione del pulsante "EXIT".
                 */
                if(model.currentRoutePoint == model.sphereList.count-1 && !settings.endNavigation && settings.infoViewed) {
                        //print("[DEBUG]: navigation end")
                    if(settings.spatialSound){
                        model.sphereList[model.currentRoutePoint].stopAllAudio()
                    }
                    
                    /*
                     Rimuovo la freccia, che rappresenta sempre l'ultima subview della lista.
                     Non eseguo il controllo se la subview della freccia è nil in quanto a questo punto verrebbe ugualmente eliminata.
                     */
                    uiView.subviews.last!.removeFromSuperview()
                            //print("[DEBUG]: Removed arrow")
                    /*
                     Creo il pulsante EXIT.
                     */
                    let endView = UITextView(frame: CGRect(x: width/4, y: height-75, width: width/2, height: 50))
                    endView.backgroundColor = settings.backgroundInfoColor
                    endView.textColor = settings.foregroundInfoColor
                    endView.layer.cornerRadius = 20
                    endView.isEditable = false
                    endView.isSelectable = false
                    endView.textAlignment = NSTextAlignment.center
                    endView.font = UIFont.preferredFont(forTextStyle: .largeTitle)
                    endView.text = "EXIT"
                    
                    /*
                     Vi applico l'azione di uscita dall'applicazione al tap.
                     */
                    let exitGestureRecognizer = BindableGestureRecognizer {
                        endView.isUserInteractionEnabled = false
                        endView.backgroundColor = self.settings.backgroundInfoColor?.withAlphaComponent(0.5)
                        endView.textColor = self.settings.foregroundInfoColor?.withAlphaComponent(0.5)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            self.exitFromApplication()
                        }
                    }
                    endView.isUserInteractionEnabled = true
                    endView.addGestureRecognizer(exitGestureRecognizer)
                    
                    if(uiView.subviews.last != nil) {
                        uiView.insertSubview(endView, aboveSubview: uiView.subviews.last!)
                    } else {
                        print("\nERROR: last subview is nil. EndView unavailable.")
                    }
                    
                    settings.endNavigation = true
                }
            }
        }
    }
    
    /*
     Funzione che effettua la sintesi vocale delle informazioni sul percorso correnti.
     */
    func speechInfo() {
        let synthesizer = AVSpeechSynthesizer()
        let utterance = AVSpeechUtterance(string: model.currentInfo)
        //utterance.voice = AVSpeechSynthesisVoice(language: "it_IT")
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate
        utterance.volume = 1
        synthesizer.speak(utterance)
    }
    
    /*
     Funzione che effettua il calcolo della distanza tra la posizione dell'utente ed il punto in input,
     nel piano bidimensionale (si considera sempre la terza coordinata Y fissa).
     */
    func distanceFromPoint(point: SIMD3<Float>) -> Float {
        return sqrt((point.x - userCameraPosition.x)*(point.x - userCameraPosition.x) + (point.z - userCameraPosition.z)*(point.z - userCameraPosition.z))
    }
    
    /*
     Funzione che restituisce il punto più vicino all'utente, considerandolo vicino quando esso si
     trova entro un raggio dato in input. Quando non ci sono punti successivi del percorso, viene
     restituito -1.
     */
    func nearestPoint(radius: Float) -> Int {
        if(model.currentRoutePoint+1 < model.sphereList.count) {
            if(distanceFromPoint(point: model.sphereList[model.currentRoutePoint+1].getPosition()) < radius ) {
                //print("\n[DEBUG]: DISTANCE FROM POINT \(model.currentRoutePoint+1) \(distanceFromPoint(point: model.sphereList[model.currentRoutePoint+1].getPosition()))\n")
                return model.currentRoutePoint + 1
            } else {
                //print("\n[DEBUG]: DISTANCE FROM POINT \(model.currentRoutePoint+1) \(distanceFromPoint(point: model.sphereList[model.currentRoutePoint+1].getPosition()))\n")
                return model.currentRoutePoint
            }
        } else {
            return -1
        }
    }

    /*
     Funzioni di conversione utili per il calcolo del bearing.
     */
    func degreesToRadians(degrees: Double) -> Double {
        return degrees * .pi / 180.0
    }
    
    func radiansToDegrees(radians: Double) -> Double {
        return radians * 180.0 / .pi
    }

    /*
     Funzione che restituisce il bearing, l'angolo fra due coordinate geografiche, in modo da
     replicare gli angoli tra i punti reali del percorso.
     */
    func getBearingBetweenTwoPoints(point1 : CLLocation, point2 : CLLocation) -> Double {
        
        let lat1 = degreesToRadians(degrees: point1.coordinate.latitude)
        let lon1 = degreesToRadians(degrees: point1.coordinate.longitude)

        let lat2 = degreesToRadians(degrees: point2.coordinate.latitude)
        let lon2 = degreesToRadians(degrees: point2.coordinate.longitude)

        let dLon = lon2 - lon1

        let y = sin(dLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)
        let radiansBearing = atan2(y, x)

        return ((radiansToDegrees(radians: radiansBearing) + 360.0).truncatingRemainder(dividingBy: 360.0))
    }
    
    /*
     Funzione che restituisce le coordinate tridimensionali di un punto del percorso, data
     la distanza dal precedente ed il suo angolo di bearing. Il calcolo è semplificato in quanto
     si tiene conto esclusivamente degli angoli tra X e Z.
     
     Si considera come altezza Y sempre -1, in quanto consideriamo percorsi senza variazione di altitudine.
     Una possibile evoluzione consiste nell'aggiungere l'altitudine alle coordinate del percorso, in modo
     da essere sfruttata in caso di percorsi che implicano discese o salite. In questo caso andrebbe cambiata
     la formula utlizzata per il calcolo delle nuove coordinate, in modo che tenga conto dell'altitudine.
     */
    func getNextPoint(distance: CLLocationDistance, bearing:  Double) -> SIMD3<Float> {
        let newX = Float(distance * cos(degreesToRadians(degrees: bearing)))
        let newZ = Float(distance * sin(degreesToRadians(degrees: bearing)))
        return SIMD3<Float>(newX, -1, newZ)
    }

    /*
     Funzione che effettua il calcolo del punto medio tra due coordinate (considerando sempre solo due dimensioni).
     */
    func midPoint(startPoint: SIMD3<Float>, endPoint: SIMD3<Float>) -> SIMD3<Float>{
        return SIMD3<Float>((startPoint.x + endPoint.x)/2, startPoint.y, (startPoint.z + endPoint.z)/2)
    }
    
    /*
     RealityKit permette la sola generazione di cubi, sfere o piani. Non avendo possibilità di sfruttare
     il software Reality Composer per costruire un modello custom, in questo contesto sono usate esclusivamente
     sfere di diverso colore e grandezza.
     Questa funzione costruisce il "tratteggio" tra due punti, in modo da capire la traiettoria da seguire.
     Ricorsivamente si calcola il punto medio tra i due estremi, richiamando la funzione che disegnerà il
     punto. Il tratteggio è realizzato disegnando punti ogni 95 cm.
     */
    func drawLine(startPoint: SIMD3<Float>, endPoint: SIMD3<Float>, anchor: AnchorEntity) {
        let distance = sqrt((endPoint.x - startPoint.x)*(endPoint.x - startPoint.x) + (endPoint.z - startPoint.z)*(endPoint.z - startPoint.z))
        let rep = Int(distance/0.95)
        let middlePoint = midPoint(startPoint: startPoint, endPoint: endPoint)
        anchor.addChild(CustomPoint(color: .systemBlue, position: middlePoint))
        drawPoints(startPoint: startPoint, endPoint: middlePoint, distance: rep/2, anchor: anchor)
        drawPoints(startPoint: middlePoint, endPoint: endPoint, distance: rep/2, anchor: anchor)
    }
    
    /*
     Funzione ricorsiva che disegna il punto medio tra due estremi fino a quando la distanza tra essi ed il
     punto medio non è inferiore ad un metro.
     */
    func drawPoints(startPoint: SIMD3<Float>, endPoint: SIMD3<Float>, distance: Int, anchor: AnchorEntity) {
        if (distance < 1) {
            return
        } else {
            let middlePoint = midPoint(startPoint: startPoint, endPoint: endPoint)
            anchor.addChild(CustomPoint(color: .systemBlue, position: middlePoint))
            if( (startPoint.x != middlePoint.x || startPoint.z != middlePoint.z) && (endPoint.x != middlePoint.x || endPoint.z != middlePoint.z) ) {
                drawPoints(startPoint: startPoint, endPoint: middlePoint, distance: distance/2, anchor: anchor)
                drawPoints(startPoint: middlePoint, endPoint: endPoint, distance: distance/2, anchor: anchor)
            }
        }
    }
    
    /*
     Funzione che calcola l'angolo tra il dispositivo ed il punto più vicino all'utente.
     Si sfrutta lo stesso principio del calcolo del bearing, ma viene eseguito tramite
     trasformazioni sulle matrici della camera e del punto target.
     */
    func getAngleFrom(target: simd_float4x4) -> Float {
        let newTransform =  simd_mul(userTransform.inverse, target).columns.3
        return atan2(newTransform.z, newTransform.y) + (.pi / 2)
    }
    
    /*
     Funzione che rimuove dal piano orizzontale i punti del percorso già superati dall'utente.
     La rimozione dei punti precedenti avviene tramite visita della lista delle Entity
     agganciate al piano orizzontale: conoscendo lo schema di inserimento dei punti e
     dei tratteggi, vengono rimossi gli elementi dalla lista.
     */
    func removePreviousPoint(anchor: AnchorEntity) {
        /*
         Il punto da eliminare è sempre il primo della lista, in ordine.
         Il secondo in lista è il successivo, poi ci sono i punti del tratteggio.
         Dato che il numero di punti del tratteggio dipende dalla distanza,
         visito la lista fino a che non trovo il successivo punto. A partire dall'
         indice del successivo, rimuovo tutti i precedenti punti del tratteggio,
         eliminando sempre l'elemento di indice 1.
         */
        anchor.children.remove(at: 0, preservingWorldTransform: true)
        var firstSphere: Int = 0
        for i in 1...anchor.children.count-1 {
            if(type(of: anchor.children[i]) == CustomSphere.self) {
                firstSphere = i
                break
            }
        }
        while(firstSphere != 1) {
            anchor.children.remove(at: 1, preservingWorldTransform: true)
            firstSphere -= 1
        }
    }
    
    /*
     Funzione che crea e visualizza il riquadro informazioni.
     Viene creata una UITextView, che contiene il testo dell'informazione.
     Viene inserita sempre sotto l'ultimo elemento della lista delle
     subview.
     */
    func createAndInsertInfoBox(rootView: ARView, width: CGFloat) -> Bool {
        let textView = UITextView(frame: CGRect(x: 0, y: 25, width: width, height: 100))
        textView.backgroundColor = settings.backgroundInfoColor
        textView.textColor = settings.foregroundInfoColor
        textView.isEditable = false
        textView.isSelectable = false
        textView.textAlignment = NSTextAlignment.center
        textView.font = UIFont.preferredFont(forTextStyle: .headline)
        textView.text = model.currentInfo
        if(rootView.subviews.last != nil) {
            rootView.insertSubview(textView, belowSubview: rootView.subviews.last!)
            return true
        } else {
            print("\nERROR: last subview is nil. TextView unavailable.")
            return false
        }
    }
    
    /*
     Funzione che crea e visualizza l'icona dello speaker, in maniera analoga
     a quella del riquadro informazioni.
     All'icona è connessa la gesture del tap, che permette di riascoltare il
     messaggio vocale.
     */
    func createAndInsertSpeaker(rootView: ARView, width: CGFloat, height: CGFloat) -> Bool {
        let speakerView = UIImageView(image: UIImage(named: settings.speaker_image!)!)
        speakerView.frame = CGRect(x: width-75, y: height-75, width: 50, height: 50)
        let tapGestureRecognizer = BindableGestureRecognizer {
            speakerView.alpha = 0.5
            self.speechInfo()
            speakerView.isUserInteractionEnabled = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0){
                speakerView.alpha = 1
                speakerView.isUserInteractionEnabled = true
            }
        }
        speakerView.isUserInteractionEnabled = true
        speakerView.addGestureRecognizer(tapGestureRecognizer)
        if(rootView.subviews.last != nil) {
            rootView.insertSubview(speakerView, belowSubview: rootView.subviews.last!)
            return true
        } else {
            print("\nERROR: last subview is nil. SpeakerView unavailable.")
            return false
        }
    }
    
    /*
     Funzione che precarica il file per l'audio spaziale sui punti
     */
    func preloadSpatialAudio() -> AudioFileResource? {
        return try? AudioFileResource.load(named: "Tink.wav", in: nil, inputMode: .spatial, loadingStrategy: .preload, shouldLoop: true)
    }
    
    /*
     Funzione che permette l'uscita dall'app a fine navigazione.
     L'app è forzatamente sospesa (come se venisse premuto il tasto Home) e
     successivamente viene terminata.
     
     Questa soluzione è risultata l'unica funzionante, in quanto se si torna indietro dalla
     visualizzazione del percorso e si ricarica un altro percorso, la ARView pur eliminando i
     vecchi punti, utilizza sempre la stessa sessione. Non esiste un metodo che esegue il "kill",
     permettendo così di ricostruire da zero la scena.
     */
    func exitFromApplication() {
        UIControl().sendAction(#selector(URLSessionTask.suspend), to: UIApplication.shared, for: nil)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            exit(EXIT_SUCCESS)
        }
    }
}

/*
 Estensione alla view principale che permette di istruire l'utente a muovere l'iPhone
 in modo da facilitare il riconoscimento del piano stradale.
 */
extension ARView: ARCoachingOverlayViewDelegate {
    func addCoaching() {
        let coachingOverlay = ARCoachingOverlayView()
        coachingOverlay.delegate = self
        coachingOverlay.session = self.session
        coachingOverlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        coachingOverlay.goal = .horizontalPlane

        self.addSubview(coachingOverlay)
    }
    
    public func coachingOverlayViewWillActivate(_ coachingOverlayView: ARCoachingOverlayView) {
        print("[DEBUG]: coachingOverlay actived")
    }
    
    public func coachingOverlayViewDidDeactivate(_ coachingOverlayView: ARCoachingOverlayView) {
        print("[DEBUG]: coachingOverlay dismissed")
        /*
         Quando il piano è riconosciuto viene riprodotto un suono (con vibrazione) che indica
         all'utente che la navigazione è iniziata.
         */
        let systemSoundID: SystemSoundID = 1052
        AudioServicesPlaySystemSound(systemSoundID)
        /*
         Dopo il primo riconoscimento del piano, il tutorial non è più necessario.
         
         Una possibile evoluzione è quella di permettere il suo riavvio nel caso in cui
         venga perso il tracking del piano (necessario introdurre il ricalcolo a partire
         dall'ultimo punto attraversato), oppure nel momento in cui si vuole calcolare
         il successivo segmento di percorso, per eliminare il drift in percorsi lunghi.
         */
        coachingOverlayView.activatesAutomatically = false
    }
}
