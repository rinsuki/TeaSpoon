//
//  NativeFunctionOverrideHelper.swift
//  TeaSpoon
//
//  Created by user on 2021/07/20.
//

import Foundation

class NativeFunctionOverrideHelper: NSObject {
    @objc static let shared = NativeFunctionOverrideHelper()
    
    @objc func isLibraryIsLoaded(suffix: String) -> Int32 {
        for i in 0..<_dyld_image_count() {
            if let name = String(cString: _dyld_get_image_name(i), encoding: .utf8) {
                if name.hasSuffix(suffix) {
                    return Int32(i)
                }
            }
        }
        return -1
    }
    
    @objc func checkShouldOverrideOpenGLRendererString() -> Bool {
        guard ProcessInfo.processInfo.environment["TEASPOON_ENABLE_OVERRIDE_GL_RENDERER"] == "YES" else {
            print("[TeaSpoon] for enable override of GL Renderer, please set TEASPOON_ENABLE_OVERRIDE_GL_RENDERER to YES.")
            print("[TeaSpoon] NOTE: Please use at YOUR OWN RISK. It uses a really tricky method, which maybe breaks something permanently.")
            return false
        }
        return true
    }
    
    @objc func address(imageIndex: UInt32, symbolName: String) -> UInt64 {
        guard let name = String(cString: _dyld_get_image_name(imageIndex), encoding: .utf8) else {
            return 0
        }
        let nm = Process()
        nm.executableURL = URL(fileURLWithPath: "/usr/bin/nm")
        #if arch(x86_64)
        nm.arguments = ["--arch=x86_64", name]
        #elseif arch(arm64)
        nm.arguments = ["--arch=arm64", name]
        #else
        #error("unknown arch")
        #endif
        let stdout = Pipe()
        print("[TeaSpoon]", stdout.fileHandleForReading.fileDescriptor)
        nm.standardOutput = stdout.fileHandleForWriting
        var chunks: [Data] = []
        nm.launch()
        // TODO: improve handling of stdout
        while nm.isRunning {
            stdout.fileHandleForReading.waitForDataInBackgroundAndNotify()
            chunks.append(try! stdout.fileHandleForReading.read(upToCount: 1024)!)
        }
        let data = Data(chunks.joined())
        guard let str = String(data: data, encoding: .utf8) else {
            return 0
        }
        var address: UInt64 = 0
        let d = dlopen(name, RTLD_NOW)
        defer {
            dlclose(d)
        }
        for line in str.split(separator: "\n") {
            let columns = line.trimmingCharacters(in: .whitespacesAndNewlines).split(separator: " ")
            if columns.count != 3 {
                continue
            }
            if address == 0 { // finding symbol
                if columns[2] != symbolName {
                    continue
                }
                address = .init(columns[0], radix: 16)!
            } else { // finding relative public symbol
                if columns[1] != "T" {
                    continue
                }
                let addr = UInt64(columns[0], radix: 16)!
                var name = columns[2]
                name = name[(name.index(after: name.startIndex))..<name.endIndex]
                guard let realPointer = dlsym(d, String(name)) else {
                    continue
                }
                // 同じライブラリ内だったらオフセットも同じになるはず
                let realAddress = UInt64(UInt(bitPattern: realPointer))
                let diff = realAddress - addr
                return address + diff
            }
        }
        return 0
    }
}
