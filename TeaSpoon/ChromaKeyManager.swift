//
//  ChromaKeyManager.swift
//  TeaSpoon
//
//  Created by user on 2021/07/19.
//

import Cocoa
import Ikemen

class ChromaKeyManager {
    static let shared = ChromaKeyManager()
    let menuItem = NSMenuItem(title: "Chroma Key", action: nil, keyEquivalent: "")

    var targetWindow: NSWindow? {
        didSet {
            if let window = targetWindow, let contentView = window.contentView, window != oldValue {
                contentView.wantsLayer = true
                updateWindowFilter()
            }
        }
    }
    
    var current: ChromaKey? {
        didSet {
            filter = current?.filter()
            refreshChromaKeyMenu()
        }
    }
    
    var filter: CIFilter? {
        didSet {
            updateWindowFilter()
        }
    }
    
    var backupWindowBackgroundColor: NSColor?
    
    func updateWindowFilter() {
        if let window = targetWindow, let layer = window.contentView?.layer {
            if backupWindowBackgroundColor != nil {
                backupWindowBackgroundColor = window.backgroundColor
            }
            if let filter = filter {
                layer.filters = [filter]
                window.backgroundColor = .clear
                window.hasShadow = false
            } else {
                layer.filters = []
                window.backgroundColor = backupWindowBackgroundColor
                window.hasShadow = true
            }
        }
    }
    
    func refreshChromaKeyMenu() {
        menuItem.state = current != nil ? .on : .off
        menuItem.submenu = NSMenu() ※ {
            $0.addItem(.init(title: "Disable", action: #selector(setChromaKey(_:)), keyEquivalent: "") ※ {
                $0.target = self
                if current == nil {
                    $0.state = .on
                }
            })
            $0.addItem(.separator())
            for key in ChromaKey.allCases {
                $0.addItem(.init(title: key.name, action: #selector(setChromaKey(_:)), keyEquivalent: "") ※ {
                    $0.target = self
                    $0.identifier = .init(key.rawValue)
                    if key == current {
                        $0.state = .on
                    }
                })
            }
        }
    }
    
    @objc func setChromaKey(_ sender: NSMenuItem) {
        guard let identifier = sender.identifier?.rawValue else {
            current = nil
            return
        }
        current = .init(rawValue: identifier)
    }
}
