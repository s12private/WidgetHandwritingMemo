//
//  Memo.swift
//  MemoUI
//
//  Created by 松中誉生 on 2020/09/06.
//

import Foundation
import SwiftUI

struct Memo: Codable, Identifiable, Equatable{
    var id:UUID = UUID()
    var name:String = "memo"
    var backColorHex: String = "ffffff"
    var canvasData: Data = Data()
    var width:Double = 0
    var height:Double = 0
    
    //なんかこーするとうまくいく。こうしないとColorをCodableで使用できない。
    //直接Colorを定義するとエンコードできないが、ColorではなくbackColorHexをエンコードしているためうまくいく？
    //https://stackoverflow.com/questions/50928153/make-uicolor-codable
    var backColor : Color {
        get {
            //print("get")
            return Color(hex: backColorHex)
        }
        set {
            backColorHex = newValue.getHex()
            //print("set")
            //print(backColorHex)
        }
    }
    
    //index(of: )でインデックスを返すようにするためのEquatable。lhs.idとrhs.idが一致したindexを返す
    static func ==(lhs:Memo, rhs:Memo) -> Bool {
        return lhs.id == rhs.id
    }
}
