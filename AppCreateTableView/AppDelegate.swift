//
//  AppDelegate.swift
//  AppCreateTableView
//
//  Created by mac on 01.07.2021.
//

import UIKit
import RealmSwift
import CoreLocation

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        let schemaVersion: UInt64 = 4
        
        let config = Realm.Configuration(
            schemaVersion: schemaVersion, // Set the new schema version.
            migrationBlock: { migration, oldSchemaVersion in
                if (oldSchemaVersion < schemaVersion) {
                   
                }
            }
        )
        
        // Tell Realm to use this new configuration object for the default Realm
        Realm.Configuration.defaultConfiguration = config
        
        CLLocationManager().requestAlwaysAuthorization()
        
        return true
    }

    // MARK: - UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }

}
