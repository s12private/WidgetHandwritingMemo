//
//  ImageManager.swift
//  WidgetHandwritingMemo
//
//  Created by 松中誉生 on 2020/09/10.
//

import Foundation

struct ImageManager: Codable {
    var selected:UUID? = nil
    
    var images:[MemoImage] = []
}

struct MemoImage: Codable {
    var id:UUID = UUID()
    var image:Data = Data()
    var name:String = ""
}
