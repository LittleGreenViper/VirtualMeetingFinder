/*
 © Copyright 2024, Little Green Viper Software Development LLC
 LICENSE:
 
 MIT License
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation
 files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy,
 modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the
 Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
 IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF
 CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

import UIKit
import SwiftBMLSDK

extension SwiftBMLSDK_Parser.Meeting.SortableMeetingType {
    var image: UIImage? {
        var imageName = "G"
        
        switch self {
        case .inPerson:
            break
        case .virtual:
            imageName = "V-P"
        case .virtual_phone:
            imageName = "P"
        case .virtual_video:
            imageName = "V"
        case .hybrid:
            imageName = "V-P-M"
        case .hybrid_phone:
            imageName = "P-M"
        case .hybrid_video:
            imageName = "V-M"
        }
        
        return UIImage(named: imageName)
    }
}

/* ###################################################################################################################################### */
// MARK: - Date Extension for Localized Strings -
/* ###################################################################################################################################### */
extension Date {
    /* ################################################################## */
    /**
     Localizes the time (not the date).
     */
    var localizedTime: String {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale.current
        dateFormatter.timeStyle = .short
        dateFormatter.dateStyle = .none

        var ret = ""
        
        let hour = Calendar.current.component(.hour, from: self)
        let minute = Calendar.current.component(.minute, from: self)

        if let am = dateFormatter.amSymbol {
            if 23 == hour {
                if 59 == minute {
                    ret = "SLUG-MIDNIGHT-TIME".localizedVariant
                } else {
                    ret = String(format: "12:%02d %@", minute, am)
                }
            } else if 12 == hour,
                      0 == minute {
                ret = "SLUG-NOON-TIME".localizedVariant
            } else {
                ret = dateFormatter.string(from: self)
            }
        } else {
            if 12 == hour,
               0 == minute {
                ret = "SLUG-NOON-TIME".localizedVariant
            } else if 23 == hour,
                      59 == minute {
                ret = "SLUG-MIDNIGHT-TIME".localizedVariant
            } else {
                ret = String(format: "%d:%02d", hour, minute)
            }
        }
        
        return ret
    }
}

/* ###################################################################################################################################### */
// MARK: - Main App Delegate -
/* ###################################################################################################################################### */
/**
 */
@main
class VMF_AppDelegate: UIResponder, UIApplicationDelegate {
    /* ################################################################## */
    /**
     Called when the app has set itself up, and is about to start.
     
     - parameter: The application (ignored)
     - parameter didFinishLaunchingWithOptions: Launch options (also ignored).
     - returns: True (always).
     */
    func application(_: UIApplication, didFinishLaunchingWithOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool { true }

    // MARK: UISceneSession Lifecycle

    /* ################################################################## */
    /**
     Called to deliver the scene configuration for the connection.
     
     - parameter: The application (ignored)
     - parameter configurationForConnecting: The session being connected.
     - parameter options: Launch options (also ignored).
     - returns: The default configuration for the scene.
     */
    func application(_: UIApplication, configurationForConnecting inConnectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: inConnectingSceneSession.role)
    }
}
