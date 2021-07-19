//
//  TeaSpoon.swift
//  TeaSpoon
//
//  Created by user on 2021/07/19.
//

import Cocoa
import Ikemen

@objc(TeaSpoon) class TeaSpoon: NSObject {
    static var chromaKeyMenuItem = { () -> NSMenuItem in
        return .init(title: "Chroma Key", action: nil, keyEquivalent: "")
    }()
    
    static func buildChromaKeyMenu() {
        chromaKeyMenuItem.state = chromaKey != nil ? .on : .off
        chromaKeyMenuItem.submenu = NSMenu() ※ {
            $0.addItem(.init(title: "Disable", action: #selector(TeaSpoon.setChromaKey(_:)), keyEquivalent: "") ※ {
                $0.target = TeaSpoon.self
                if chromaKey == nil {
                    $0.state = .on
                }
            })
            $0.addItem(.separator())
            for key in ChromaKey.allCases {
                $0.addItem(.init(title: key.name, action: #selector(TeaSpoon.setChromaKey(_:)), keyEquivalent: "") ※ {
                    $0.target = TeaSpoon.self
                    $0.identifier = .init(key.rawValue)
                    if key == chromaKey {
                        $0.state = .on
                    }
                })
            }
        }
    }
    
    static var menu = { () -> NSMenu in
        let menu = NSMenu()
        menu.title = "TeaSpoon"
        menu.addItem(chromaKeyMenuItem)
        buildChromaKeyMenu()
        return menu
    }()
    static var alreadyMenuAdded = false
    
    static var emulatorFilter: CIFilter? {
        didSet {
            if let window = emulatorWindow, let layer = window.contentView?.layer {
                if let filter = emulatorFilter {
                    layer.filters = [filter]
                    window.hasShadow = false
                } else {
                    layer.filters = []
                    window.hasShadow = true
                }
            }
        }
    }
    
    static var chromaKey: ChromaKey? {
        didSet {
            emulatorFilter = chromaKey?.filter()
            buildChromaKeyMenu()
        }
    }
    
    @objc static func setChromaKey(_ sender: NSMenuItem) {
        guard let identifier = sender.identifier?.rawValue else {
            chromaKey = nil
            return
        }
        chromaKey = .init(rawValue: identifier)
    }
    
    static var emulatorWindow: NSWindow? {
        didSet {
            if let window = emulatorWindow, let contentView = window.contentView, window != oldValue {
                window.backgroundColor = .clear
                contentView.wantsLayer = true
                if let filter = emulatorFilter {
                    contentView.layer!.filters = [filter]
                } else {
                    contentView.layer!.filters = []
                }
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
    
    static func hasEmuGLView(view: NSView) -> Bool {
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
    
    @objc static func checkWindowIsEmulatorMainWindow(_ window: NSWindow) -> Bool {
        if let view = window.contentView, hasEmuGLView(view: view) {
            emulatorWindow = window
            return true
        }
        return false
    }
}
