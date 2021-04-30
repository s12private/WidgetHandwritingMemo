//
//  CanvasView.swift
//  MemoUI
//
//  Created by 松中誉生 on 2020/09/03.
//

import SwiftUI
import PencilKit
import WidgetKit

struct CanvasView: UIViewRepresentable{
    //PKCanvasViewのdelegateを扱えるようにする
    class Coordinator: NSObject, PKCanvasViewDelegate {
        var canvasView:CanvasView

        init(_ canvasView:CanvasView) {
            self.canvasView = canvasView
        }
        
        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            self.canvasView.save()
        }
    }
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    @Binding var pkCanvasView:PKCanvasView
    
    //toolPickerはStateにしないと表示されないっぽい？？
    @State var toolPicker:PKToolPicker = PKToolPicker()
    
    @Binding var canvasData:Data
    
    func makeUIView(context: Context) -> PKCanvasView {
        pkCanvasView.drawingPolicy = .anyInput
        //ToolPicker
        toolPicker.setVisible(true, forFirstResponder: pkCanvasView)
        toolPicker.addObserver(pkCanvasView)
        pkCanvasView.becomeFirstResponder()
        pkCanvasView.bouncesZoom = true
        pkCanvasView.minimumZoomScale = 1.0
        pkCanvasView.maximumZoomScale = 10.0
        pkCanvasView.delegate = context.coordinator
        
        //背景色(backgroundColorを指定するとタッチした瞬間にopaqueがtrueに戻ってしまうの背景にviewを設定する)
        pkCanvasView.isOpaque = true
        pkCanvasView.backgroundColor = .clear
        
        return pkCanvasView
    }
    
    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        //State変数が変更された場合この関数で更新される
        if(canvasData != pkCanvasView.drawing.dataRepresentation()){
            pkCanvasView.drawing = (try? PKDrawing(data: canvasData)) ?? PKDrawing()
            print("updated")
        }
        //
    }
    
    //データを保存
    func save(){
        if(pkCanvasView.drawing.dataRepresentation() != canvasData){
            print("saving--")
            canvasData = pkCanvasView.drawing.dataRepresentation()
            print("saved---")
        }
    }
}
