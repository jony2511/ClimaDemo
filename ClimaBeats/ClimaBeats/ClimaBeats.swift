//
//  ClimaBeats.swift
//  ClimaBeats
//
//

import UIKit
import FirebaseCore

@main
class ClimaBeats: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // App entry point for non-scene lifecycle.
        FirebaseApp.configure()
        return true
    }

}

