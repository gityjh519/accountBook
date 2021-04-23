//
//  PersonJson.swift
//  AccountBook
//
//  Created by yaojinhai on 2020/12/15.
//

import Foundation
import UIKit

let rootPathName = "myAccount"

class PersonManager: ObservableObject {
    @Published var persons = [PersonJson]()
    
    init() {
//        persons.append(.init(name: "abc"))
//        persons.append(.init(name: "efg"))
//        persons.append(.init(name: "hikj"))
    }
    
    func addPerson(name: String) {
        let item = PersonJson(name: name);
        persons.insert(item, at: 0)
        DataBaseManger.saveDataModel(item: item)
        DataBaseManger.saveToFileData()
    }
    
    func addPersonToList(json: PersonJson) {
        let index = persons.firstIndex { (item) -> Bool in
            item.id == json.id
        }
        if let idx = index {
            persons[idx] = json
        } else{
            persons.insert(json, at: 0)
        }
        DataBaseManger.saveDataModel(item: json)
        DataBaseManger.saveToFileData()
    }
}

struct PersonJson: Codable,Identifiable {
    var id = UUID().uuidString
    var countList: [AccountJson]?
    var name = ""
    var date = ""
    
    var copyItem: PersonJson {
        var item = PersonJson(name: name)
        item.date = date
        item.countList = countList
        return item
    }
    
    init(name: String) {
        self.name = name;
        date = Date().forrmaterDate();
        countList = [AccountJson]()
        
//        countList?.append(.init(isMyCount: true, money: 200, type: 0))
//        countList?.append(.init(isMyCount: true, money: 230, type: 1))
//        countList?.append(.init(isMyCount: true, money: 430, type: 2))
//        
//        countList?.append(.init(isMyCount: false, money: 2100, type: 0))
//        countList?.append(.init(isMyCount: false, money: 2130, type: 1))
//        countList?.append(.init(isMyCount: false, money: 4130, type: 2))


    }
    
    func getCurrentList(myCount: Bool) ->  [AccountJson]?{
        countList?.filter({ (item: AccountJson) -> Bool in
            item.isAlreadyHuan == myCount
        })
    }
    
    // 借款
    var myCountMoney: Int {
        countList?.reduce(0, { (result, item) -> Int in
            result + (item.isAlreadyHuan ? 0 : item.money)
        }) ?? 0
        
    }
    
    var leftMoney: String {
        let leftM = myCountMoney - sendOtherMony //abs(sendOtherMony - myCountMoney);
        if leftM == 0 {
            return "已经还完"
        }
        
        return "剩下：" + (leftM.description.converNumberSpellOut() ?? "")
        
    }
    
    var myCountMoneyString: String {
        myCountMoney.description
    }
    
    // 还款
    var sendOtherMony: Int {
        countList?.reduce(0, { (result, item) -> Int in
            result + (item.isAlreadyHuan ? item.money : 0)
        }) ?? 0
    }
    var sendOtherMonyString: String {
        sendOtherMony.description 
    }
    
}

enum ToolItemType: Int, CodingKey {
    case weixin = 0
    case alipay
    case bank
    
}

struct AccountJson: Codable,Identifiable {
    var id = Date().yyyyMMddHHmmss()
    var dateTime = ""
    var money = 0
    var isAlreadyHuan = false // false 已还 yes 未还
    var toolType = 0
    
    init(alreadyHuan: Bool,money: Int,type: Int) {
        self.dateTime = Date().forrmaterDate()
        self.money = money
        self.toolType = type
        self.isAlreadyHuan = alreadyHuan
    }
    var moneyString: String {
        money.description + "元"
    }
    
    
}

extension PersonManager {

    class func readMyPersonManager() -> PersonManager {

        let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] + "/\(rootPathName)/";
        let keyPath = path + "key";
        
        UIPasteboard.general.string = path
        
        let json = JSONDecoder();
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: keyPath)) else{
            return PersonManager()
        }
        
        guard let keys = try? json.decode([String].self, from: data) else{
            return PersonManager()
        }
        DataBaseManger.saveDataForKey(keys: keys);
        let allListModel = PersonManager()
        for key in keys {
            let rootPath = path + key;
            if let modelData = try? Data(contentsOf: URL(fileURLWithPath: rootPath)) {
                if let model = try? json.decode(PersonJson.self, from: modelData) {
                    allListModel.persons.append(model)
                    DataBaseManger.saveDataModel(item: model)
                }
            }
            
        }
        return allListModel
    }
    
}


class DataBaseManger: NSObject {
    
    fileprivate static var dataDict = [String: PersonJson]();
    fileprivate static var dataForKey = [String]()
    
    fileprivate static var changeKeyId = [String]()
    
    
    private override init() {
        super.init()
    }
    
    class func saveDataModel(item: PersonJson) {
        dataDict[item.id] = item;
        changeKeyId.append(item.id)
        
        
    }
    class func saveDataForKey(keys: [String]) -> Void {
        dataForKey = keys
    }
    
    class func removeDataItem(id: String) {
        dataDict.removeValue(forKey: id)
        
        dataForKey.removeAll { (subId) -> Bool in
            subId == id
        }
     
        changeKeyId.append(id)

        let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] + "/\(rootPathName)/";
        let rootPath = path + id;
        let file = FileManager.default;
        try? file.removeItem(atPath: rootPath)

    }
    
    class func saveToFileData() {
        
        
        if changeKeyId.isEmpty  {
            return;
        }
        
        let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] + "/\(rootPathName)/";
        let file = FileManager.default;
        if !file.fileExists(atPath: path) {
            try? file.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
        }
        

        let dataForKey = dataDict.map { (subItem) -> String in
            subItem.key
        }
        
        let rootPath = path + "key";
        let json = JSONEncoder();
        let keyData = try? json.encode(dataForKey);
        try? keyData?.write(to: URL(fileURLWithPath: rootPath))
        
        for item in dataDict {
            let dataPath = path + item.key;
            let data = try? json.encode(item.value)
            try? data?.write(to: URL(fileURLWithPath: dataPath))
        }
        
        changeKeyId.removeAll()

    }
}



extension Date {
    func forrmaterDate() -> String {
        let formater = DateFormatter()
        formater.dateFormat = "yyyy年MM月dd日\nEEEE";
        formater.locale = Locale(identifier: "zh-Hans_US")
        formater.calendar = .init(identifier: .gregorian);
        return formater.string(from: self)
    } 
    func yyyyMMddHHmmss() -> String {
        let formater = DateFormatter()
        formater.dateFormat = "yyyyMMddHHmmss";
        formater.locale = Locale(identifier: "zh-Hans_US")
        formater.calendar = .init(identifier: .gregorian);
        return formater.string(from: self)
    } 
}

extension String {
    
    func converNumberSpellOut() -> String? {
        if let v = convertPerWan() {
            return v
        }
        let numberF = NumberFormatter()
        numberF.locale = Locale(identifier: "zh")
        numberF.numberStyle = .spellOut
        if let mony = Int(self),mony > 0 {
            return  numberF.string(from: NSNumber(value: mony))!
        }
        return nil
        
    }
    func convertPerWan() -> String? {
        let valueInt = Double(self) ?? 0
        if valueInt >= 10000 {
            let moneyStrl = String(format: "%0.2f万", (valueInt / 10000));
            return moneyStrl.replacingOccurrences(of: ".00", with: "")
        }
        return nil
    }
}

extension UserDefaults {
    static private var isHuan = UserDefaults.standard.bool(forKey: "currentType")
    static var isAlreadyHuanFirst: Bool {
        set{
            isHuan = newValue
            UserDefaults.standard.set(newValue, forKey: "currentType")
        }
        get{
            isHuan
        }
    }
    
}

import SwiftUI

func rgbColor(_ rgb : Double) -> Color{
    return rgbColor(rgb, g: rgb, b: rgb);
}
func rgbColor(_ r:Double,g:Double,b:Double) -> Color{
    let color = Color(.sRGB, red: r / 255.0, green: g / 255.0, blue: b / 255.0, opacity: 1)
    return color;
}

extension Color {
    static var selectedColor = [rgbColor(255, g: 157, b: 2),rgbColor(255, g: 186, b: 76)]
    static var normalColor = [rgbColor(135, g: 136, b: 137),rgbColor(80, g: 90, b: 100)]
}


