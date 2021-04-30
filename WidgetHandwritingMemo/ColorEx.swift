//
//  ColorEx.swift
//  MemoUI
//
//  Created by 松中誉生 on 2020/09/04.
//

import Foundation
import SwiftUI

extension Color {
   init(hex: String) {
       let scanner = Scanner(string: hex)
       scanner.scanLocation = 0
       var rgbValue: UInt64 = 0
       scanner.scanHexInt64(&rgbValue)

       let r = (rgbValue & 0xff0000) >> 16
       let g = (rgbValue & 0xff00) >> 8
       let b = rgbValue & 0xff


       self.init(red: Double(r) / 0xff, green: Double(g) / 0xff, blue: Double(b) / 0xff)

   }
    
    func getHex() -> String {
        let components = self.cgColor?.components
        let r: CGFloat = components?[0] ?? 0.0
        let g: CGFloat = components?[1] ?? 0.0
        let b: CGFloat = components?[2] ?? 0.0
        return String(NSString(format: "%02X%02X%02X", Int(r*255), Int(g*255), Int(b*255)))
    }
}
