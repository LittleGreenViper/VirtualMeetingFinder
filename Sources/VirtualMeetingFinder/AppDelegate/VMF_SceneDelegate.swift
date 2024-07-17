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

/* ###################################################################################################################################### */
// MARK: - Main Scene Delegate -
/* ###################################################################################################################################### */
/**
 This class has the Scene Delegate functionality.
 */
class VMF_SceneDelegate: UIResponder, UIWindowSceneDelegate {
    /* ################################################################## */
    /**
     If it's been over this many seconds since our last load, we force a new load, the next time we open.
     */
    static let forceReloadDelayInSeconds = TimeInterval(60 * 60 * 4)
    
    /* ################################################################## */
    /**
     This is set to the last time we loaded.
     While the app is up in the foreground, we won't be forcing a reload, but we will, if it enters the background, then comes back.
     */
    static var lastReloadTime = Date.distantPast
    
    /* ################################################################## */
    /**
     */
    static var urlMeetingID = Int(0)
    
    /* ################################################################## */
    /**
     The window object for this scene.
     */
    var window: UIWindow?
    
    /* ################################################################## */
    /**
     Called after the scene is entering into the foreground.
     
     We use this to set the search screen to today/now.
     
     - parameter: The scene instance (ignored).
     */
    func sceneWillEnterForeground(_: UIScene) {
        if nil == VMF_AppDelegate.openMeeting {
            VMF_AppDelegate.searchController?.isThrobbing = true
            VMF_AppDelegate.virtualService?.refreshCaches() { _ in
                VMF_AppDelegate.searchController?.isThrobbing = false
                VMF_AppDelegate.searchController?.openTo()
                self.window?.setNeedsLayout()
            }
        } else {
            self.window?.setNeedsLayout()
        }
    }
    
    /* ################################################################## */
    /**
     Called when the app is foregrounded via a URL.
     
     - parameter: The scene instance (ignored).
     - parameter openURLContexts: The Opening URL contexts (as a set).
     */
    func scene(_: UIScene, openURLContexts inURLContexts: Set<UIOpenURLContext>) {
        inURLContexts.forEach { resolveURL($0.url) }
    }
    
    /* ################################################################## */
    /**
     Called when the app is opened via a URL from a "cold start."
     - parameter: The scene instance.
     - parameter willConnectTo: The session being connected (ignored).
     - parameter options: This contains the options, among which, is the URL context.
     */
    func scene(_ inScene: UIScene, willConnectTo: UISceneSession, options inConnectionOptions: UIScene.ConnectionOptions) {
        if let url = inConnectionOptions.userActivities.first?.webpageURL ?? inConnectionOptions.urlContexts.first?.url {
            resolveURL(url)
        }
    }
    
    /* ################################################################## */
    /**
     Called when the app is opened via a URL (and launched).
     - parameter: The scene instance (ignored).
     - parameter continue: The activity being continued.
     */
    func scene(_: UIScene, continue inUserActivity: NSUserActivity) {
        guard let url = inUserActivity.webpageURL else { return }
        
        resolveURL(url)
    }
}

/* ###################################################################################################################################### */
// MARK: Instance Methods
/* ###################################################################################################################################### */
extension VMF_SceneDelegate {
    /* ################################################################## */
    /**
     This will set the static property to a given meeting ID, if it is provided in the URI.
     
     - parameter inURL: The URL to resolve.
     */
    func resolveURL(_ inURL: URL) {
        if let statusString = inURL.query(),
           let meetingID = Int(statusString),
           0 < meetingID {
            Self.urlMeetingID = meetingID
        }
    }
}

