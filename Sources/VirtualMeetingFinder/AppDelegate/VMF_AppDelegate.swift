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

/* ###################################################################################################################################### */
// MARK: - Image Assignment Enum, for Meeting Access Types -
/* ###################################################################################################################################### */
extension SwiftBMLSDK_Parser.Meeting.SortableMeetingType {
    /* ################################################################## */
    /**
     Returns the correct image to use, for the type. Returns nil, if no image available.
     */
    var image: UIImage? {
        var imageName = "G" // Generic Web
        
        switch self {
        case .inPerson: // We don't do in-person, alone
            break
        case .virtual:  // Virtual, and has both video and phone
            imageName = "V-P"
        case .virtual_phone:    // Virtual, phone-only
            imageName = "P"
        case .virtual_video:    // Virtual, video-only
            imageName = "V"
        case .hybrid:           // Hybrid, with both video and phone virtual options
            imageName = "V-P-M"
        case .hybrid_phone:     // Hybrid, with only a phone dial-in option
            imageName = "P-M"
        case .hybrid_video:     // Hybrid, with only a video option
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
 This is the original app delegate part of the app (starting point). We are actually using Scene Delegate, but this is a good place to use as a "fulcrum."
 */
@main
class VMF_AppDelegate: UIResponder {
    /* ################################################################## */
    /**
     This is set to the open meeting, if we have one we are looking at.
     */
    static var openMeeting: VMF_MeetingViewController?
    
    /* ################################################################## */
    /**
     This is set to the open search tab, if it is selected.
     
     We do this, so we can exit name search mode, if we go into the background.
     */
    static var searchController: VMF_MainSearchViewController?
}

/* ###################################################################################################################################### */
// MARK: UIApplicationDelegate Conformance
/* ###################################################################################################################################### */
extension VMF_AppDelegate: UIApplicationDelegate {
    /* ################################################################## */
    /**
     This opens a URL.
     
     - parameter url: The URL to open.
     - parameter options: The URLoptions.
     - parameter completionHandler: The closure to be executed, upon completion of the open.
     */
    class func open(url inURL: URL, options inOptions: [UIApplication.OpenExternalURLOptionsKey: Any] = [:], completionHandler inClosure: ((Bool) -> Void)? = nil) {
        UIApplication.shared.open(inURL, options: inOptions, completionHandler: inClosure)
    }

    /* ################################################################## */
    /**
     Called when the app has set itself up, and is about to start.
     
     - parameter: The application (ignored)
     - parameter didFinishLaunchingWithOptions: Launch options (also ignored).
     - returns: True (always).
     */
    func application(_: UIApplication, didFinishLaunchingWithOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool { true }

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
