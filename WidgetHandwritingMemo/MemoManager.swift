//
//  MemoDictionary.swift
//  WidgetHandwritingMemo
//
//  Created by 松中誉生 on 2020/09/08.
//

import Foundation

struct MemoManager: Codable{
    var selected:UUID? = nil
    var memos:[Memo] = []
    
    //選択されたメモを返す
    var selectedMemo:Memo? {
        get{
            for memo in memos {
                if(memo.id == selected){
                    return memo
                }
            }
            return nil
        }
        set{
            //値が代入された時
            selected = newValue!.id
            if(getMemoIndex(uuid: selected!) == nil){
                //メモが存在しなければ追加
                memos.append(newValue!)
            }else{
                //メモが存在すればmemosを書き換え
                memos[getMemoIndex(uuid: selected!)!] = newValue!
            }
        }
    }
    
    //メモのindexを返す
    func getMemoIndex(uuid:UUID) -> Int?{
        for i in 0..<memos.count {
            if(uuid == memos[i].id){
                return i
            }
        }
        return nil
    }
    
    
}
