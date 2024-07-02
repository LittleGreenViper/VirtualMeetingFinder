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
// MARK: - Main App Delegate -
/* ###################################################################################################################################### */
/**
 This is the original app delegate part of the app (starting point). We are actually using Scene Delegate, but this is a good place to use as a "fulcrum."
 */
@main
class VMF_AppDelegate: UIResponder {
    /* ################################################################## */
    /**
     This is our query instance.
     */
    private static var _queryInstance = SwiftBMLSDK_Query(serverBaseURI: URL(string: "https://littlegreenviper.com/LGV_MeetingServer/Tests/entrypoint.php"))

    /* ################################################################## */
    /**
     This is set to the open meeting, if we have one we are looking at.
     */
    static var openMeeting: VMF_MeetingViewController?
    
    /* ################################################################## */
    /**
     This handles the server data. This is the main container. All others reference this weakly.
     
     "There can only be one." - Connor MacLeod
     */
    static var virtualService: SwiftBMLSDK_MeetingLocalTimezoneCollection?
}

/* ###################################################################################################################################### */
// MARK: Static Functions
/* ###################################################################################################################################### */
extension VMF_AppDelegate {
    /* ################################################################## */
    /**
     Fetches all of the virtual meetings (hybrid and pure virtual).
     
     - parameter completion: A tail completion handler. One parameter, with the virtual service (nil, if error). May be called in any thread.
     */
    static func findMeetings(completion inCompletion: @escaping (SwiftBMLSDK_MeetingLocalTimezoneCollection?) -> Void) {
        virtualService = nil
        
        _ = SwiftBMLSDK_MeetingLocalTimezoneCollection(query: _queryInstance) { inCollection in
            DispatchQueue.main.async {
                virtualService = inCollection
                inCompletion(virtualService)
            }
        }
    }
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
