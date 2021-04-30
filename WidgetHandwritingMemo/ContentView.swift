//
//  ContentView.swift
//  MemoUI
//
//  Created by 松中誉生 on 2020/09/03.
//

import SwiftUI
import PencilKit
import WidgetKit
import GoogleMobileAds

class DataObservable: ObservableObject {
    var selectedUUID:UUID
    
    @Binding var memoManagerData:Data {
        didSet{
            print("data")
        }
    }
    
    @Binding var imageManagerData:Data {
        didSet{
            print("image")
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
    
    var memoManager:MemoManager {
        didSet{
            print("memo manager")
            memoManager.selected = selectedUUID
            save()
        }
    }
    
    var imageManager:ImageManager {
        didSet{
            print("image manager saved")
            imageManagerData = try! JSONEncoder().encode(imageManager)
        }
    }
    
    @Published var memos:[Memo] {
        didSet{
            print("memos")
            memoManager.memos = memos
            deleteMemos()
        }
    }
    
    @Published var memo:Memo {
        didSet{
            print("memo")
            selectedUUID = memo.id
            if let index:Int = getMemoIndex(uuid: memo.id) {
                memos[index] = memo
            }else{
                memos.append(memo)
            }
            
            var imageData:Data = Data()
            //pngデータ
            let pkDrawing:PKDrawing = (try? PKDrawing(data: memo.canvasData)) ?? PKDrawing()
            let width:Double = memo.width
            let height:Double = memo.height
            if(width != 0 && height != 0){
                let image = pkDrawing.image(from: CGRect(x: 0, y: 0, width: width, height: height), scale: 0.0)
                let back:UIImage = UIImage(color: UIColor(Color(hex: memo.backColorHex)), size: CGSize(width: width, height: height))!
                //canvasと背景を合成, 倍率を0.0にすることでscaleを動的に計算してくれる。これをしないと解像度が低下してしまう
                UIGraphicsBeginImageContextWithOptions(image.size, false, 0.0)
                back.draw(in: CGRect(x: 0, y: 0, width: width, height: width))
                image.draw(in: CGRect(x: 0, y: 0, width: width, height: width))
                imageData = UIGraphicsGetImageFromCurrentImageContext()!.pngData()!
            }else{
                imageData = UIImage(color: UIColor.white, size: CGSize(width: 1, height: 1))!.pngData()!
            }
            
            for i in 0..<imageManager.images.count{
                if(imageManager.images[i].id == memo.id){
                    imageManager.images[i].image = imageData
                    imageManager.images[i].name = memo.name
                    return
                }
            }
            imageManager.images.append(MemoImage(id: memo.id, image: imageData, name: memo.name))
            print(memo.name)
        }
    }
    
    //canvasDataは別で変更を通知しないと、memoが変更->CanvasViewのsave()が呼ばれる->memoに、
    //CanvasViewが保持していたPKDrawing(変更前のキャンバスデータ)が読み込まれてしまう。
    @Published var canvasData:Data {
        didSet{
            print("canvas")
            memo.canvasData = canvasData
        }
    }
    
    //$data.memo.backColorをColorPickerのselectionに設定すると挙動が怪しくなるため、別で更新を通知する。
    @Published var color:Color{
        didSet{
            print("color")
            memo.backColor = color
        }
    }
    
    init(memoManagerData: Binding<Data>, imageManagerData: Binding<Data>){
        self._memoManagerData = memoManagerData
        self._imageManagerData = imageManagerData
        self.memoManager = (try? JSONDecoder().decode(MemoManager.self, from: memoManagerData.wrappedValue)) ?? MemoManager()
        self.imageManager = (try? JSONDecoder().decode(ImageManager.self, from: imageManagerData.wrappedValue)) ?? ImageManager()
        self.memos = memoManager.memos
        if(memoManager.selectedMemo == nil){
            memoManager.selectedMemo = Memo()
        }
        selectedUUID = memoManager.selectedMemo!.id
        self.memo = memoManager.selectedMemo!
        self.canvasData = memoManager.selectedMemo!.canvasData
        self.color = memoManager.selectedMemo!.backColor
        print("init--------------------------------")
        
        do {
            let fileManager = FileManager.default
            let docs = try fileManager.url(for: .documentDirectory,
                                           in: .userDomainMask,
                                           appropriateFor: nil, create: true)
            let path = docs.appendingPathComponent("myFile.json")
            let data = try! JSONEncoder().encode(memo.canvasData)

            fileManager.createFile(atPath: path.path,
                                   contents: data, attributes: nil)
        } catch {
            print(error)
        }
    }
    
    func save(){
        //memoManager.memos[memoManager.selected] = memo
        memoManagerData = try! JSONEncoder().encode(memoManager)
        print("memoSaved")
    }
    
    func getMemo(uuid:UUID) -> Memo?{
        for memo in memos {
            return memo
        }
        return nil
    }
    
    func getMemoIndex(uuid: UUID) -> Int?{
        for i in 0..<memos.count {
            if(memos[i].id == uuid){
                return i
            }
        }
        return nil
    }
    
    func getImageData(uuid:UUID) -> Data? {
        for memoImage in imageManager.images {
            if(memoImage.id == uuid){
                return memoImage.image
            }
        }
        return nil
    }
    
    //不要な画像を削除
    func deleteMemos(){
        var i=0
        while(i < imageManager.images.count){
            var flag:Bool = false
            for memo in memos {
                if(imageManager.images[i].id == memo.id){
                    flag = true
                    break
                }
            }
            if(!flag){
                imageManager.images.remove(at: i)
                i -= 1
            }
            i += 1
        }
    }
}

struct ContentView: View {
    @State var pkCanvasView:PKCanvasView = PKCanvasView()
    @State var backView:Rectangle = Rectangle()
    @State private var showingAlert:Bool = false
    @State var keyboardHeight:CGFloat = 0

    @Binding var memoManagerData:Data
    
    @State var isPresentedSubView = false
    
    @StateObject var data:DataObservable
    
    var body: some View {
        GeometryReader { geometry in
            let width: CGFloat = geometry.size.width
            let height: CGFloat = geometry.size.height
            let navHeight: CGFloat = 65
            ZStack{
                Rectangle().fill(Color.blue).onAppear()
                    .ignoresSafeArea(.all)
                
                //Admob
                VStack(){
                    AdView(width: width)
                        .frame(width: width, height: 50)
                    Spacer()
                }
                
                //ペンツールが隠れてしまった時のボタン
                VStack{
                    Spacer()
                    Button(action:{
                        pkCanvasView.becomeFirstResponder()
                    }){
                        Text("ペンツールを表示")
                            .padding()
                            .foregroundColor(Color(hex: "222222"))
                            .background(Color.white)
                            .cornerRadius(20)
                    }
                    .padding()
                }.ignoresSafeArea(.all)
                
                
                VStack(alignment: .leading, spacing: 0){
                    ZStack(alignment: .top){
                        Rectangle()
                            .foregroundColor(Color(hex: "393939"))
                            .cornerRadius(radius: 20, corners: [.topLeft, .topRight, .bottomRight])
                        VStack(spacing: 0){
                            HStack{
                                Button(action: {pkCanvasView.undoManager?.undo()}){
                                    buttonImage(name: "undo")
                                }.padding(.trailing, 10)
                                Button(action: {pkCanvasView.undoManager?.redo()}){
                                    buttonImage(name: "redo")
                                }
                                Spacer()
                                ColorPicker("picker", selection: $data.color)
                                    .frame(width: 25, height: 25)   //frameを指定しないと左に謎の領域が生まれる
                                    .padding(.trailing, 10)
                                Button(action: {
                                    self.showingAlert = true
                                }){
                                    buttonImage(name: "clear")
                                }.alert(isPresented: $showingAlert) {
                                    Alert(title: Text("削除"),
                                        message: Text("この操作は戻すことができません。削除しますか？"),
                                        primaryButton: .cancel(Text("キャンセル")),
                                        secondaryButton: .destructive(Text("削除"), action: {
                                            pkCanvasView.drawing = PKDrawing()
                                        }))
                                }
                            }
                            .padding(.horizontal, 20)
                            .frame(width: width, height: navHeight)
                            
                            ZStack{
                                BackView(cornerRadius: 20, color: $data.color)
                                CanvasView(pkCanvasView: $pkCanvasView, canvasData: $data.canvasData)
                                    .onAppear(){
                                        $data.memo.wrappedValue.width = Double(width)
                                        $data.memo.wrappedValue.height = Double(width)
                                    }
                            }
                            .cornerRadius(20)
                            .frame(width: width, height: width)
                            .shadow(color:Color.black.opacity(0.2), radius: 6, x: 0, y: 3)
                        }
                    }
                    .frame(width: width, height: width+navHeight)
                    //下部Nav
                    ZStack{
                        Rectangle()
                            .foregroundColor(Color(hex: "393939"))
                            .cornerRadius(radius: 20, corners: [.bottomLeft, .bottomRight])
                        HStack{
                            Button(action: {
                                    isPresentedSubView.toggle()
                            }){
                                buttonImage(name: "list", height: 13)
                            }.sheet(isPresented: $isPresentedSubView) {
                                //遷移
                                MemoListView(isPresentedSubview: $isPresentedSubView, data: _data)
                            }
                            TextField("", text: $data.memo.name,
                                onEditingChanged: { begin in
                                    if(!begin){
                                        pkCanvasView.becomeFirstResponder() //バグ防止
                                    }
                                }
                            )
                                .foregroundColor(Color.white)
                            .modifier(PlaceholderStyle(showPlaceHolder: $data.memo.name.wrappedValue.isEmpty, placeholder: "名前を入力", color: Color.gray))
                        }
                        .padding(.horizontal, 20)
                    }
                    .frame(width: width*2/3.0, height: 50)
                }
                .position(x: width/2, y: height/2-20)
                //.position(x: width/2, y: height/2-keyboardHeight/2-20)//キーボードの高さに合わせてviewを上に。なぜか何もしなくても上に行くようになった。
                .animation(.easeOut(duration: 0.3))
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            //広告をタップした時にfirstResponderが外れてしまう
            pkCanvasView.becomeFirstResponder()
        }
        .onAppear(){
            /*
            //キーボードの高さ
            NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: .main) { key in
                //let value = key.userInfo![UIResponder.keyboardFrameEndUserInfoKey] as! CGRect
                //subView表示中の時は無視
                if(!self.isPresentedSubView){
                    //self.keyboardHeight = value.height
                }
            }

            NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main) { key in
                self.keyboardHeight = 0
            }
            */
        }
        /*
        .onTapGesture {
            //キーボードを閉じる。ColorPickerより上の階層でonTapGestureを付与するとColorPickerが反応しなくなる。対処待ち。
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
         */
        .onOpenURL { (url) in
            changeMemo(uuid: url.description)
        }
    }
    
    func changeMemo(uuid:String){
        for m in data.memos {
            if(m.id.description == uuid){
                //canvasData,colorは別で変更を通知する。バグ防止。
                data.memo = m
                data.canvasData = m.canvasData
                data.color = m.backColor
                break
            }
        }
    }
}

//placeholderの色を変更できるTextField
public struct PlaceholderStyle: ViewModifier {
    var showPlaceHolder: Bool
    var placeholder: String
    var color: Color

    public func body(content: Content) -> some View {
        ZStack(alignment: .leading) {
            if showPlaceHolder {
                Text(placeholder)
                    .foregroundColor(color)
            }
            content
                .foregroundColor(Color.white)
        }
    }
}

struct BackView: View{
    @State var cornerRadius:CGFloat
    
    @Binding var color:Color
    
    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(color)
    }
}

struct buttonImage: View{
    let name: String
    var width: CGFloat = 25
    var height: CGFloat = 25
    
    var body: some View {
        Image(name)
            .resizable()
            .renderingMode(.template)
            .foregroundColor(Color(hex: "f7f7f7"))
            .scaledToFit()
            .frame(width: width, height: height)
    }
}

//一部のみ角丸にする.cornerRadius(radius: ,corners: )
struct CornerRadiusStyle: ViewModifier {
    var radius: CGFloat
    var corners: UIRectCorner

    struct CornerRadiusShape: Shape {

        var radius:CGFloat = CGFloat.infinity
        var corners:UIRectCorner = UIRectCorner.allCorners

        func path(in rect: CGRect) -> Path {
            let path:UIBezierPath = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
            return Path(path.cgPath)
        }
    }

    func body(content: Content) -> some View {
        content
            .clipShape(CornerRadiusShape(radius: radius, corners: corners))
    }
}

struct AdView: UIViewRepresentable {
    @State var width:CGFloat
    
    func makeUIView(context: Context) -> GADBannerView {
        let banner = GADBannerView()
        //banner.adUnitID = "ca-app-pub-3940256099942544/2934735716" //テスト
        banner.rootViewController = UIApplication.shared.windows.first?.rootViewController
        banner.load(GADRequest())
        banner.adSize = GADPortraitAnchoredAdaptiveBannerAdSizeWithWidth(width)
        return banner
    }

    func updateUIView(_ uiView: GADBannerView, context: Context) {
    }
}

class SingleTouchDownGestureRecognizer: UIGestureRecognizer {
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        if self.state == .possible {
            self.state = .recognized
        }
    }
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        self.state = .failed
    }
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        self.state = .failed
    }
}

extension View {
    func cornerRadius(radius: CGFloat, corners: UIRectCorner) -> some View {
        ModifiedContent(content: self, modifier: CornerRadiusStyle(radius: radius, corners: corners))
    }
}
