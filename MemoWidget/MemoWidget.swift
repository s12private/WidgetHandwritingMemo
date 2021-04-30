//
//  MemoWidget.swift
//  MemoWidget
//
//  Created by 松中誉生 on 2020/09/17.
//

import WidgetKit
import SwiftUI
import Intents

struct Provider: IntentTimelineProvider {
    @AppStorage("images", store: UserDefaults(suiteName: "group.shigeki.work.WidgetHandwritingMemo"))
    var imageManagerData:Data = Data()
    var imageData:Data = Data()
    
    func placeholder(in context: Context) -> MemoEntry {
        MemoEntry(image: imageData, configuration: ConfigurationIntent())
    }

    func getSnapshot(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (MemoEntry) -> ()) {
        let imageManager:ImageManager = (try? JSONDecoder().decode(ImageManager.self, from: imageManagerData)) ?? ImageManager()
        var imageData:Data! = Data()
        for image in imageManager.images {
            if(image.id.description == configuration.memo?.identifier){
                imageData = image.image
                break
            }
        }
        let entry = MemoEntry(image: imageData, configuration: configuration)
        completion(entry)
    }

    func getTimeline(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let imageManager:ImageManager = (try? JSONDecoder().decode(ImageManager.self, from: imageManagerData)) ?? ImageManager()
        var imageData:Data! = Data()
        for image in imageManager.images {
            if(image.id.description == configuration.memo?.identifier){
                imageData = image.image
                break
            }
        }
        let entry = MemoEntry(image: imageData, configuration: configuration)

        let timeline = Timeline(entries: [entry], policy: .atEnd)
        completion(timeline)
    }
}

struct MemoEntry: TimelineEntry {
    let date:Date = Date()
    let image:Data
    let configuration: ConfigurationIntent
}

struct MemoWidgetEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        if(entry.configuration.memo != nil){
            if let image:UIImage =  UIImage(data: entry.image) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .widgetURL(URL(string: (entry.configuration.memo?.identifier)!))
            }else{
                Text("")
            }
        }else{
            VStack{
                Text("メモが選択されていません。")
                    .font(.caption)
                Text("ウィジェットを長押しして、「ウィジェットを編集」を押してメモを選択してください。")
                    .font(.caption)
            }.padding()
        }
    }
}

@main
struct MemoWidget: Widget {
    let kind: String = "MemoWidget"

    var body: some WidgetConfiguration {
        IntentConfiguration(kind: kind, intent: ConfigurationIntent.self, provider: Provider()) { entry in
            MemoWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("手書きメモ")
        .description("手書きのメモをウィジェットとしてホーム画面に配置することができます。")
    }
}
