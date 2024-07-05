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
 */
class VMF_SceneDelegate: UIResponder, UIWindowSceneDelegate {
    /* ################################################################## */
    /**
     The window object for this scene.
     */
    var window: UIWindow?

    /* ################################################################## */
    /**
     Called before a connection is made to this scene.
     
     - parameter inScene: The scene being connected.
     - parameter willConnectTo: The session being connected (ignored).
     - parameter options: The connection options (also ignored).
     */
    func scene(_ inScene: UIScene, willConnectTo: UISceneSession, options: UIScene.ConnectionOptions) {
        _ = (inScene as? UIWindowScene) // Forces the window to be set.
    }
    
    /* ################################################################## */
    /**
     Called after the scene is entering into the foreground.
     
     We use this to set the search screen to today/now.
     
     - parameter: The scene instance (ignored).
     */
    func sceneWillEnterForeground(_: UIScene) {
        if nil == VMF_AppDelegate.openMeeting {
            VMF_AppDelegate.searchController?.isThrobbing = true
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + DispatchTimeInterval.milliseconds(20)) {
                VMF_AppDelegate.virtualService?.refreshCaches() { _ in
                    VMF_AppDelegate.searchController?.isThrobbing = false
                    VMF_AppDelegate.searchController?.openTo()
                    self.window?.setNeedsLayout()
                }
            }
        } else {
            self.window?.setNeedsLayout()
        }
    }
}

