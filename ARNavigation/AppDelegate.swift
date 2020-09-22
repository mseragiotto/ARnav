//
//  AppDelegate.swift
//  ARNavigation
//
//  Created by Matteo Seragiotto.
//  Copyright © 2020 Matteo Seragiotto. All rights reserved.
//

import UIKit
import SwiftUI

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        /*
         La View SwiftUI principale istanzia come variabili di stato globali il Model, le UserSettings e le informazioni sulla posizione AR dell'utente.
         Quest'ultime sono fornite dalla classe ARViewHandler, i cui valori saranno aggiornati all'avvio della sessione AR.
         */
        let mainView = MainView().environmentObject(Model()).environmentObject(UserSettings()).environmentObject(ARViewHandler())

        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = UIHostingController(rootView: mainView)
        self.window = window
        window.makeKeyAndVisible()
        
        /*
         Registro i valori di default delle impostazioni sulle palette di colori del'interfaccia e la grandezza del font.
         */
        UserDefaults.standard.register(defaults: ["spatialSound" : false, "arrow_image" : "orangeblack", "speaker_image" : "sorangeblack", "paletteInfoValue" : 1, "paletteValue" : 3, "outputValue" : 0])
        
        /*
         La classe UserDefaults non supporta il tipo di dato UIColor, per cui è stato necessario implementarne un'estensione
         nella classe UserSettings. L'estensione non permette però l'utilizzo della funzione register() per impostare
         i valori di default non settati dei colori delle impostazioni.
         Questo significa che non verrebbero colorati gli oggetti fino a quando non si va a modificare l'impostazione
         manualmente.
         Facendo il seguente controllo forzato è possibile aggirare il problema, settando il valore iniziale che verrà mantenuto in memoria.
         Questo controllo è eseguito all'avvio dell'app e causa la modifica solamente al primo avvio sul dispositivo, i successivi
         avranno i valori correttamente salvati nella classe UserDefaults
         */
        if(UserDefaults.standard.object(forKey: "backgroundInfoColor") == nil) {
            UserDefaults.standard.set(UIColor.orange, forKey: "backgroundInfoColor")
            UserDefaults.standard.set(UIColor.black, forKey: "foregroundInfoColor")
        }
        if(UserDefaults.standard.object(forKey: "backgroundColor") == nil) {
            UserDefaults.standard.set(UIColor.blue, forKey: "backgroundColor")
            UserDefaults.standard.set(UIColor.white, forKey: "foregroundColor")
        }
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }


}

