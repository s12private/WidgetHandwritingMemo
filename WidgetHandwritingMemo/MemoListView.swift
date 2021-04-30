//
//  MemoListView.swift
//  WidgetHandwritingMemo
//
//  Created by 松中誉生 on 2020/09/08.
//

import SwiftUI
import PencilKit

struct MemoListView: View {
    
    @Binding var isPresentedSubView:Bool
    @State private var editMode:EditMode = EditMode.inactive
    
    @State var frame: CGSize = .zero
    
    @StateObject var data:DataObservable
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    init(isPresentedSubview:Binding<Bool>, data:StateObject<DataObservable>){
        _isPresentedSubView = isPresentedSubview
        _data = data
        
        //bodyでForEachに対して.listRowBackground(Color.clear)もしないとCellの色が反映されない
        UITableView.appearance().backgroundColor = UIColor(Color(hex: "EFEFEF"))
        UITableViewCell.appearance().backgroundColor = UITableView.appearance().backgroundColor
        
        let coloredNavAppearance = UINavigationBarAppearance()
        coloredNavAppearance.configureWithOpaqueBackground()
        coloredNavAppearance.shadowColor = .clear
        coloredNavAppearance.backgroundColor = .clear
        UINavigationBar.appearance().standardAppearance = coloredNavAppearance
        
        UITableView.appearance().separatorColor = .red
        UITableView.appearance().separatorStyle = .none
    }

    var body: some View {
        GeometryReader { geometry in
            ScrollView{
                Text("長押しで削除することができます。")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.top, 20)
                LazyVGrid(columns: columns, spacing: 20){
                    ForEach(data.memos) {value in
                        Row(memo: value, data: _data, isPresentedSubView: $isPresentedSubView, editMode: $editMode)
                    }
                    Button(action: {
                        onAdd()
                    }){
                        VStack{
                            Image("add")
                                .resizable()
                                .frame(width: 140, height: 140)
                            Text(" ") //高さ調節用
                        }
                    }
                }.padding(.top, 50)
                .animation(.easeIn(duration: 0.25))
            }.onAppear(){
                frame = geometry.size
            }
        }
    }
    
    private var addButton: some View {
        switch editMode {
        case .inactive:
            return AnyView(Button(action: onAdd) { Image(systemName: "plus") })
        default:
            return AnyView(EmptyView())
        }
    }
    
    //行入れ替え
    func onMove(_ from: IndexSet, _ to: Int){
        data.memos.move(fromOffsets: from, toOffset: to)
    }
    
    //削除
    func onDelete(offsets: IndexSet){
        data.memos.remove(atOffsets: offsets)
    }
    
    //追加
    func onAdd(){
        var newMemo:Memo = Memo()
        newMemo.width = Double(frame.width)
        newMemo.height = Double(frame.width)
        newMemo.canvasData = PKDrawing().dataRepresentation()
        data.memos.append(newMemo)
    }
}

struct Row:View {
    var memo:Memo
    @StateObject var data:DataObservable
    @Binding var isPresentedSubView:Bool
    
    @Binding var editMode:EditMode
    @State var name:String
    
    @State var showingAlert:Bool = false
    
    var image:UIImage
    
    init(memo: Memo, data:StateObject<DataObservable>, isPresentedSubView: Binding<Bool>, editMode:Binding<EditMode>){
        self.memo = memo
        _data = data
        _isPresentedSubView = isPresentedSubView
        _editMode = editMode
        _name = State(initialValue: memo.name)
        
        self.image = UIImage(data: data.wrappedValue.getImageData(uuid: memo.id) ?? Data()) ?? UIImage(color: UIColor.white, size: CGSize(width: 1, height: 1))!
    }
    
    var body: some View {
        VStack(alignment: .center){
            Button(action: {
            }){
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 140, height: 140)
                    .cornerRadius(20)
                    .shadow(color:Color.black.opacity(0.2), radius: 5, x: 0, y: 6)
                    .onTapGesture {
                        //canvasData,colorは別で変更を通知する。バグ防止。
                        data.memo = memo
                        data.canvasData = memo.canvasData
                        data.color = memo.backColor
                        data.selectedUUID = memo.id
                        isPresentedSubView = false
                    }
                    .onLongPressGesture(minimumDuration: 0.1) {
                        showingAlert = true
                    }
            }.alert(isPresented: $showingAlert) {
                Alert(title: Text("削除"),
                      message: Text(memo.name + "を削除しますか？"),
                    primaryButton: .cancel(Text("キャンセル")),
                    secondaryButton: .destructive(Text("削除"), action: {
                        data.memos.remove(at: data.getMemoIndex(uuid: memo.id)!)
                    }))
            }
            TextField("", text: $name ,onEditingChanged: { begin in
                if(!begin){
                    if(data.memo == memo){
                        data.memo.name = name
                    }else{
                        //ContentViewで表示中のメモでなければmemosを直接更新する
                        data.memos[data.getMemoIndex(uuid: memo.id)!].name = name
                    }
                }
            })
                .foregroundColor(Color(hex: "#2B2B2B"))
                .multilineTextAlignment(.center)
                .modifier(PlaceholderStyle(showPlaceHolder: $name.wrappedValue.isEmpty, placeholder: "名前を入力", color: Color.gray)) //ContentViewに定義済み
        }
    }
}
