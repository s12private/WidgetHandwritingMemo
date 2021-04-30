//
//  IntentHandler.swift
//  MemoIntentExtension
//
//  Created by 松中誉生 on 2020/09/17.
//

import Intents

class IntentHandler: INExtension, ConfigurationIntentHandling{
    let groupId = "group.shigeki.work.WidgetHandwritingMemo"
    
    func provideMemoOptionsCollection(for intent: ConfigurationIntent, with completion: @escaping (INObjectCollection<MemoType>?, Error?) -> Void) {
        let userDefaults:UserDefaults! = UserDefaults(suiteName: groupId)
        
        let memoManagerData:Data! = userDefaults.data(forKey: "memos") ?? Data()
        let memoManager:MemoManager! = (try? JSONDecoder().decode(MemoManager.self, from: memoManagerData)) ?? MemoManager()
        
        var memoTypes:[MemoType]! = []
        for memo in memoManager.memos {
            let memoType:MemoType! = MemoType(identifier: memo.id.description, display: memo.name)
            memoTypes.append(memoType)
        }
        let collection = INObjectCollection(items: memoTypes)
        completion(collection, nil)
    }
    
    
    override func handler(for intent: INIntent) -> Any {
        // This is the default implementation.  If you want different objects to handle different intents,
        // you can override this and return the handler you want for that particular intent.
        
        return self
    }
    
}
