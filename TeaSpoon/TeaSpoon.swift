//
//  TeaSpoon.swift
//  TeaSpoon
//
//  Created by user on 2021/07/19.
//

import Cocoa
import Ikemen

@objc(TeaSpoon) class TeaSpoon: NSObject {
    @objc static let shared = TeaSpoon()
    
    var menu = NSMenu() ※ {
        $0.title = "TeaSpoon"
        $0.addItem(ChromaKeyManager.shared.menuItem)
        ChromaKeyManager.shared.refreshChromaKeyMenu()
    }
    
    var alreadyMenuAdded = false
    var mainWindow: NSWindow? {
        didSet {
            if let window = mainWindow, window != oldValue {
                ChromaKeyManager.shared.targetWindow = window
                if !alreadyMenuAdded {
                    alreadyMenuAdded = true
                    let item = NSMenuItem()
                    item.submenu = menu
                    item.title = menu.title
                    NSApplication.shared.mainMenu?.addItem(item)
                }
            }
        }
    }
    
    func hasEmuGLView(view: NSView) -> Bool {
        if view.className == "EmuGLView" {
            return true
        }
        for view in view.subviews {
            if hasEmuGLView(view: view) {
                return true
            }
        }
        return false
    }
    
    @objc func checkWindowIsEmulatorMainWindow(_ window: NSWindow) -> Bool {
        if let view = window.contentView, hasEmuGLView(view: view) {
            mainWindow = window
            return true
        }
        return false
    }
}
