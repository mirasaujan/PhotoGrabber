//
//  AppDelegate.swift
//  PhotoGrabber
//
//  Created by Miras Karazhigitov on 2019-02-28.
//  Copyright © 2019 Miras Karazhigitov. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.makeKeyAndVisible()
        window?.rootViewController = ViewController()
        
        return true
    }

}

