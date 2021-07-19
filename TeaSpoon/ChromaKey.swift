//
//  ChromaKey.swift
//  TeaSpoon
//
//  Created by user on 2021/07/19.
//

import Foundation
import CoreImage

enum ChromaKey: String, CaseIterable {
    case cute
    case cool
    case passion
    
    var name: String {
        switch self {
        case .cute:
            return "Cute"
        case .cool:
            return "Cool"
        case .passion:
            return "Passion"
        }
    }
    
    func filter() -> CIFilter {
        switch self {
        case .cute:
            return ChromaKeyFilter.filter(1, green: 3/255.0, blue: 102/255.0, threshold: 0.3)
        case .cool:
            return ChromaKeyFilter.filter(0.15, green: 0.48, blue: 1, threshold: 0.4)
        case .passion:
            return ChromaKeyFilter.filter(251/255.0, green: 179/255.0, blue: 2/255.0, threshold: 0.3)
        }
    }
}
