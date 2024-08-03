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
import RVS_Generic_Swift_Toolbox
import RVS_BasicGCDTimer

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
      This is our query instance. It returns a new query instance, freshly initialized to the Root Server, every time it's called.
      */
     private class var _queryInstance: SwiftBMLSDK_Query? {
          guard let bundleURIString = Bundle.main.rootServerURI,
                let rootURI = URL(string: bundleURIString)
          else { return nil }
          
          return SwiftBMLSDK_Query(serverBaseURI: rootURI)
     }
     
     /* ################################################################## */
     /**
      The number of seconds that we put aside for fetching the data.
      */
     private static let _fetchTimeoutInSeconds = TimeInterval(30)
     
     /* ################################################################## */
     /**
      The timer for fetching data.
      */
     private static var _timer: RVS_BasicGCDTimer?
     
     /* ################################################################## */
     /**
      This is set to the open meeting, if we have one we are looking at.
      */
     static var openMeeting: VMF_MeetingInspectorViewController?
     
     /* ################################################################## */
     /**
      This is set to the Main Screen controller
      */
     static var mainScreenController: VMF_MainViewController?
     
     /* ################################################################## */
     /**
      This handles the server data. This is the main container. All others reference this weakly.
      
      "There can only be one." - Connor MacLeod
      */
     static var virtualService: SwiftBMLSDK_MeetingLocalTimezoneCollection?
     
     /* ################################################################## */
     /**
      This is the singleton for the prefs.
      */
     static var prefs = VMF_Persistent_Prefs()
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
     class func findMeetings(completion inCompletion: @escaping (SwiftBMLSDK_MeetingLocalTimezoneCollection?) -> Void) {
          virtualService = nil
          
          guard let queryInstance = Self._queryInstance else {
               inCompletion(nil)
               return
          }
          
          Self._timer = RVS_BasicGCDTimer(Self._fetchTimeoutInSeconds) { inTimer, inComplete in
               Self._timer = nil
               guard inComplete else { return }
               DispatchQueue.main.async {
                    inCompletion(nil)
               }
          }
          
          Self._timer?.isRunning = true
          
          _ = SwiftBMLSDK_MeetingLocalTimezoneCollection(query: queryInstance) { inCollection in
               Self._timer?.isRunning = false
               Self._timer = nil
               DispatchQueue.main.async {
                    virtualService = inCollection
                    inCompletion(virtualService)
               }
          }
     }
     
     /* ################################################################## */
     /**
      Displays the given message and title in an alert with an "OK" button.
      
      - parameter header: a string to be displayed as the title of the alert. It is localized by this method.
      - parameter message: a string to be displayed as the message of the alert. It is localized by this method.
      - parameter presentedBy: An optional UIViewController object that is acting as the presenter context for the alert. If nil, we use the top controller of the Navigation stack.
      */
     class func displayAlert(header inHeader: String, message inMessage: String = "", presentedBy inPresentingViewController: UIViewController! = nil) {
          // This ensures that we are on the main thread.
          DispatchQueue.main.async {
               if let presentedBy = inPresentingViewController {
                    let alertController = UIAlertController(title: inHeader.localizedVariant, message: inMessage.localizedVariant, preferredStyle: .alert)
                    let okAction = UIAlertAction(title: "SLUG-OK-BUTTON-TEXT".localizedVariant, style: .cancel, handler: nil)
                    alertController.addAction(okAction)
                    presentedBy.present(alertController, animated: true, completion: nil)
               }
          }
     }
     
     /* ################################################################## */
     /**
      Quick access to the app delegate object.
      */
     class var appDelegateInstance: VMF_AppDelegate? { UIApplication.shared.delegate as? VMF_AppDelegate }
}

/* ###################################################################################################################################### */
// MARK: Instance Methods
/* ###################################################################################################################################### */
extension VMF_AppDelegate {
     /* ################################################################## */
     /**
      This opens our app settings, with the permissions shown. It is ObjC, so it can be directly referenced from a callback.
      
      - parameter: Ignored (and can be omitted).
      */
     @objc dynamic func openMainSettings(_: Any! = nil) {
         guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
         Self.open(url: url)
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
      - parameter completionHandler: The closure to be executed, upon completion of the open. It has one parameter, a Boolean, that is true, if the open was successful. This is always called in the main thread.
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
      - returns: A new instance of a default configuration for the scene.
      */
     func application(_: UIApplication, configurationForConnecting inConnectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
          UISceneConfiguration(name: "Default Configuration", sessionRole: inConnectingSceneSession.role)
     }
}
