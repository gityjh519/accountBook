//
//  ContentView.swift
//  AccountBook
//
//  Created by yaojinhai on 2020/12/15.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var model = PersonManager.readMyPersonManager()
    @State var isAdd = false
    
    @State var editJson: PersonJson?
    
    
    var body: some View {
        NavigationView(content: {
            VStack(alignment: .leading) {
                tableList.navigationBarTitle("我的小账本", displayMode: .inline).navigationBarItems(trailing: Button(action: {
                    editJson = nil
                    isAdd.toggle()
                }, label: {
                    Text("添加")
                }))
            }
            
        }).sheet(isPresented: $isAdd, content: {
            AddPersonManger(editJson: $editJson, finishedBlock: .constant({ (value) in
                isAdd.toggle()
                model.addPersonToList(json: value)
            }))

        })
    }
    
    var tableList: some View {
        List {
            SummaryAccountView().environmentObject(model).padding(EdgeInsets(top: 30, leading: 0, bottom: 0, trailing: 0))

            ForEach(model.persons) { (item)  in
                NavigationLink(
                    destination: PersonDetialList(tempJson: item, isAlreadyHuan:  UserDefaults.isAlreadyHuanFirst).environmentObject(model),
                    label: {
                        getPersonRowItem(json: item)
                        
                    })
            }.onDelete(perform: { indexSet in
                if let idx = indexSet.first {
                    let item = model.persons[idx];
                    model.persons.remove(atOffsets: indexSet)
                    DataBaseManger.removeDataItem(id: item.id)
                    DataBaseManger.saveToFileData()

                }
            })
        }.listStyle(PlainListStyle())
    }
    
    

    func getPersonRowItem(json: PersonJson) -> some View {
        HStack(alignment: .center, content: {
            VStack(alignment:.leading) {
                HStack(alignment: .firstTextBaseline) {
                    Text(json.name).font(.body).foregroundColor(rgbColor(255, g: 107, b: 51))
                    Text(json.myCountMoneyString.converNumberSpellOut() ?? json.myCountMoneyString).font(Font.system(size: 12)).padding(.leading, 12)
                }
                Text(json.date).font(.footnote)
            }.onTapGesture {
                editJson = json
                isAdd.toggle()
            }
            Spacer()
            Text(json.leftMoney).font(.footnote)
        })
    }
    
}

struct PersonDetialList: View {
    
    @State var tempJson: PersonJson?
    @State var isAlreadyHuan = UserDefaults.isAlreadyHuanFirst // // 是不是已还

    
    @EnvironmentObject var itemJson: PersonManager
    
    @State private var isShowAddView = false
    
    
    @State private var cellJson: AccountJson?
    
    @State private var isHuanFirst: Bool?;
    
    
    @State private var isDeleteAlert = false
    
    @State private var deleteItemIndexSet: IndexSet?
    
    var body: some View {
        VStack(alignment: .leading, content: {
            segmentItem.padding(8).alert(isPresented: $isDeleteAlert) { () -> Alert in
                let model = getWillDeleteIndexItem()?.moneyString
                let value = model == nil ? "当前记录" : "(\(model ?? ""))";
                return .init(title: Text("是否删除\(value)"), primaryButton: Alert.Button.cancel(), secondaryButton: .default(Text("确定"), action: { 
                    if let indexSet = deleteItemIndexSet {
                        deleteItem(set: indexSet)
                    }
                    deleteItemIndexSet = nil
                }))
            }
            List{ 
                ForEach(getCurrentAcountList()) { (item)  in
                    cellRow(item: item)
                }.onDelete(perform: { indexSet in
                    deleteItemIndexSet = indexSet
                    isDeleteAlert.toggle()
//                    deleteItem(set: indexSet)
                })
            }
        }).navigationBarTitle(Text(tempJson?.name ?? ""), displayMode: .inline).sheet(isPresented: $isShowAddView, content: {
            showDetialItem()
        }).navigationBarItems(trailing: trailingView).onAppear { 
            
            isAlreadyHuan = UserDefaults.isAlreadyHuanFirst
        }
    }
    
    var trailingView: some View {
        HStack(content: {
            Button("添加") { 
                cellJson = nil
                isShowAddView.toggle()
            }
        })
    }
    
    
    func showDetialItem() -> some View {
        
        AddAccountToPerson(isAlreadyHuan: $isAlreadyHuan, editJson: $cellJson) { (addItem) in
            addItemToPerson(item: addItem)
        }
    }
    
    private func getCurrentAcountList() -> [AccountJson] {
        if let list = tempJson?.getCurrentList(myCount: isAlreadyHuan) {
            return list
        }
        return []
    }
    
    func addItemToPerson(item: AccountJson) {
        let firstIndex = tempJson?.countList?.firstIndex(where: { (subItem) -> Bool in
            subItem.id == item.id
        })
        if let idx = firstIndex {
            tempJson?.countList![idx] = item
            cellJson = item
            
        }else {
            tempJson?.countList?.insert(item, at: 0)
        }
        
        saveCurrentModel()
  
        isShowAddView.toggle()
        
    }
    
    func saveCurrentModel() {
        guard let idx = itemJson.persons.firstIndex(where: { (subItem) -> Bool in
            subItem.id == tempJson?.id
        }) else {
            return
        }
        
        let newJson = tempJson ?? .init(name: "")
        itemJson.persons[idx] = newJson
        DataBaseManger.saveDataModel(item: newJson)
        let keys = itemJson.persons.map { (subitem) -> String in
            subitem.id
        }
        DataBaseManger.saveDataForKey(keys: keys)
        DataBaseManger.saveToFileData()
    }
    
    func deleteItem(set: IndexSet)  {
        guard let idex = set.first else {
            return
        }
        let newList = getCurrentAcountList()
        let item = newList[idex];
        tempJson?.countList?.removeAll(where: { (subItem) -> Bool in
            subItem.id == item.id
        })
        guard let idx = itemJson.persons.firstIndex(where: { (subItem) -> Bool in
            subItem.id == tempJson?.id
        }) else {
            return;
        }
        itemJson.persons[idx] = tempJson!
        DataBaseManger.saveDataModel(item: tempJson!)
        DataBaseManger.saveToFileData()
        
    }
    
    func getWillDeleteIndexItem() -> AccountJson? {
        guard let idex = deleteItemIndexSet?.first else {
            return nil
        }
        let newList = getCurrentAcountList()
        let item = newList[idex];
        return item
//        tempJson?.countList?.removeAll(where: { (subItem) -> Bool in
//            subItem.id == item.id
//        })
//        guard let idx = itemJson.persons.firstIndex(where: { (subItem) -> Bool in
//            subItem.id == tempJson?.id
//        }) else {
//            return;
//        }
    }
    
    func cellRow(item: AccountJson) -> some View {
        HStack(alignment: .center, content: {
            Text(item.dateTime).lineLimit(2)
            Spacer()
            VStack(alignment: .leading) {
                Text(item.money.description.converNumberSpellOut() ?? "")
                Text(item.moneyString).font(Font.system(size: 10))
            }
            
        }).onTapGesture {
            cellJson = item
            isShowAddView.toggle()
        }
        
    }
    
    var segmentItem: some View {
        HStack(alignment: .center, content: {
            if (isHuanFirst ?? UserDefaults.isAlreadyHuanFirst) {
                huanKuanView
                changeItemView
                jieKuanView
            }else {
                jieKuanView
                changeItemView
                huanKuanView
            }
        }).frame(height: 42, alignment: .center)
    }
    
    var changeItemView: some View {
        let lineWidth: CGFloat = 48;
        let lineHeight: CGFloat = 8;
       return GeometryReader(content: { geometry in
            Path({ path in
                let aPoint = CGPoint(x: (geometry.size.width - lineWidth)/2 + 14, y: (geometry.size.height - lineHeight * 3)/2)
                path.move(to: aPoint)
                let bPoint = CGPoint(x: aPoint.x - 14, y: aPoint.y + lineHeight);
                path.addLine(to: bPoint)
                let cPoint = CGPoint(x: bPoint.x + lineWidth, y: bPoint.y)
                path.addLine(to: cPoint)
                
                let dPoint = CGPoint(x: bPoint.x, y: cPoint.y + lineHeight);
                path.move(to: dPoint)
                let ePoint = CGPoint(x: dPoint.x + lineWidth, y: dPoint.y)
                path.addLine(to: ePoint)
                let fPoint = CGPoint(x: ePoint.x - 14, y: ePoint.y + lineHeight)
                path.addLine(to: fPoint)
                
            }).stroke(Color.red, lineWidth: 1).onTapGesture(count: 2) {
                
                withAnimation(.easeInOut(duration: 0.2)) {
                    if isHuanFirst == nil {
                        isHuanFirst = false
                    }else {
                        isHuanFirst?.toggle()
                    }
                }
                
                UserDefaults.isAlreadyHuanFirst = isHuanFirst!
            }
        })
    }
    
    var huanKuanView: some View {
        Button(action: {
            if isAlreadyHuan == false {
                withAnimation(.easeInOut(duration: 1)) {
                    isAlreadyHuan.toggle()
                }
            }
        }, label: {
            VStack {
                Text("还款")
                Text(getSendOtherPerson().converNumberSpellOut() ?? "0元")
            }.foregroundColor(Color.white).offset(x: -10, y: 0)
            
        }).padding(.leading, 20).frame(width: UIScreen.main.bounds.width/3, alignment: .center).background(getButtonBackView(isSelected: isAlreadyHuan))
    }
    
    var jieKuanView: some View {
        Button(action: {
            if isAlreadyHuan == true {
                withAnimation(.easeInOut(duration: 1)) {
                    isAlreadyHuan.toggle()
                }
            }
        }, label: {
            VStack {
                Text("借款").frame(width: UIScreen.main.bounds.width/3, alignment: .center)
                Text(getMyCountPeson().converNumberSpellOut() ?? "0元").frame(width: UIScreen.main.bounds.width/3, alignment: .center)
            }.foregroundColor(.white).frame(width: UIScreen.main.bounds.width/3, alignment: .center).offset(x: 10, y: 0)
            

        }).padding(.trailing, 20).frame(width: UIScreen.main.bounds.width/3, alignment: .center).background(getButtonBackView(isSelected: !isAlreadyHuan))
    }
    
 
    
    func getButtonBackView(isSelected: Bool) -> some View {
        GeometryReader { (proxy)  in
            Path { (path) in
                path.addRoundedRect(in: proxy.frame(in: .local), cornerSize: .init(width: 4, height: 4))
            }.fill(LinearGradient(gradient: Gradient(colors: isSelected ? Color.selectedColor : Color.normalColor), startPoint: .leading, endPoint: .trailing)).scaleEffect( isSelected ? 1.1 : 1).animation(.easeInOut)
        }
    }
    
    
//    old button
//    var huanKuanView: some View {
//        Button(action: {
//            if isAlreadyHuan == false {
//                isAlreadyHuan.toggle()
//            }
//        }, label: {
//            VStack {
//                Text("还款").foregroundColor(isAlreadyHuan ? Color(.blue) : Color(.secondaryLabel))
//                Text(getSendOtherPerson().converNumberSpellOut() ?? "").foregroundColor(isAlreadyHuan ? Color(.blue) : Color(.secondaryLabel))
//            }
//            
//        }).padding(.leading, 20).frame(width: UIScreen.main.bounds.width/3, alignment: .center)
//    }
    
//    var jieKuanView: some View {
//        Button(action: {
//            if isAlreadyHuan == true {
//                isAlreadyHuan.toggle()
//            }
//        }, label: {
//            VStack {
//                Text("借款").foregroundColor(isAlreadyHuan ? Color(.secondaryLabel) : Color(.blue))
//                Text(getMyCountPeson().converNumberSpellOut() ?? "").foregroundColor(isAlreadyHuan ? Color(.secondaryLabel) : Color(.blue))
//            }
//            
//
//        }).padding(.trailing, 20).frame(width: UIScreen.main.bounds.width/3, alignment: .center)
//    }
    
    func getSendOtherPerson() -> String {
        let temp = tempJson ?? .init(name: "")
        return temp.sendOtherMonyString
    }
    func getMyCountPeson() -> String {
        let temp = tempJson ?? .init(name: "")
        return temp.myCountMoneyString
    }
}

struct AddAccountToPerson: View {
    @Binding var isAlreadyHuan: Bool
    @Binding var editJson: AccountJson?
    let finishedBlock: (_ json: AccountJson) -> Void


    @State private var moneyString = ""
    @State private var currentIndx = 0
    
    @State private var editDate = Date()
    
    
    
    private let payTypeList = ["微信","支付宝","银行"]
    
    var body: some View {
        NavigationView(content: {
            VStack(alignment: .leading, content: {
                
                List { 
                    fieldView
                    dateTimeView
                    Text("打款方式:").padding(.leading, 10)
                    ForEach(0..<3) { (idx)in
                        Button(action: {
                            currentIndx = idx
                        }, label: {
                            Text(payTypeList[idx]).foregroundColor(idx == currentIndx ? Color(.blue) : Color(.secondaryLabel))
                        })
                    }
                }
            }).navigationBarTitle(Text(isAlreadyHuan ? "添加还款详细" : "添加借款详细"), displayMode: .inline).navigationBarItems(trailing: Button(action: {
             
                var subItem = editJson ?? .init(alreadyHuan: isAlreadyHuan, money: Int(moneyString) ?? 0, type: currentIndx)
                subItem.dateTime = editDate.forrmaterDate()
                subItem.money = Int(moneyString) ?? 0
                subItem.toolType = currentIndx
                finishedBlock(subItem)
            }, label: {
                Text("确定")
            }))
        }).onAppear { 
            if let m = editJson {
                DispatchQueue.main.async {
                    self.currentIndx = m.toolType
                    self.moneyString = m.money.description
                }
                
            }
        }
    }
    var fieldView: some View {
        HStack(alignment: .center, content: {
            Text(isAlreadyHuan ? "还款金额" : "借款金额")
            Spacer()
            
            VStack(alignment: .leading) {
                TextField(isAlreadyHuan ? "还款金额" : "借款金额", text: $moneyString).frame(width: 200, height: 40, alignment: .trailing).keyboardType(.numberPad).textFieldStyle(RoundedBorderTextFieldStyle()).padding(.trailing, 10)
                Text(moneyString.converNumberSpellOut() ?? "显示结果")
            }
            
        })
    }
    
    var dateTimeView: some View {
        DatePicker(selection: $editDate, displayedComponents: .date) {
            
        }.datePickerStyle(WheelDatePickerStyle()).labelsHidden()
    }
  
}

struct PersonRow: View {
    let json: PersonJson
    var body: some View {
        HStack(alignment: .center, content: {
            VStack(alignment:.leading) {
                Text(json.name).font(.body)
                Text(json.date).font(.footnote)
            }
            Spacer()
            Text(json.leftMoney).font(.footnote)
        })
        
    }
    
}


struct AddPersonManger: View {
    
    @Binding var editJson: PersonJson?
    @Binding var finishedBlock: (_ name: PersonJson) -> Void
    
    @State var editDate = Date()
    
    @State private var name = ""
    
    var body: some View {
        NavigationView(content: {
            VStack {
                TextField("添加姓名", text: $name).navigationBarItems(trailing: Button(action: {
                    if name.count > 0 {
                        var json = editJson ?? .init(name: name);
                        json.name = name
                        json.date = editDate.forrmaterDate()
                        finishedBlock(json)
                    }
                    
                }, label: {
                    Text("确定")
                })).frame( height: 40, alignment: .leading).border(Color.gray, width: /*@START_MENU_TOKEN@*/1/*@END_MENU_TOKEN@*/).padding()
                
                dateTimeView
                
                Spacer()
            }.navigationBarTitle(Text(editJson?.name ?? "姓名"), displayMode: .inline)
            
        })
        
    }
    
    var dateTimeView: some View {
        DatePicker(selection: $editDate, displayedComponents: .date) {
            
        }.datePickerStyle(WheelDatePickerStyle()).labelsHidden()
    
    }
}

struct SummaryAccountView: View {
    @EnvironmentObject var itemJson: PersonManager
    var body: some View {
        HStack(alignment: .center) {
            VStack{

                getContentText(text: "还款\n" + (getAlreadyHuanCount().converNumberSpellOut() ?? "0元")).offset(x: 0, y: -10)
                getContentText(text: "剩下\n" + needHuan())

            }.offset(x: 0, y: -10)
            
            VStack{
                getContentText(text: "借款\n" + (getMyReciveCount().converNumberSpellOut() ?? "0元")).offset(x: 0, y: -10)

                getContentText(text: "人数\n" + itemJson.persons.count.description + "人")
            }.offset(x: 0, y: -10)
            

        }.font(Font.system(size: 14)).lineLimit(2).foregroundColor(.white)
    }
    
    func getContentText(text: String) -> some View {
        Text(text).frame(width: (UIScreen.main.bounds.width - 60)/2, height: 40, alignment: .center).background(rgbColor(37, g: 122, b: 182).blur(radius: 0.5)).cornerRadius(6).shadow(color: Color.gray, radius: 2, x: 2, y: 2).lineLimit(2)

    }
    
    func needHuan() -> String {
        let all = itemJson.persons.reduce(0) { (result, item) -> Int in
            result + item.sendOtherMony;
        }
        let sendAll = itemJson.persons.reduce(0) { (result, item) -> Int in
            result + item.myCountMoney
        }
        return (sendAll - all).description.converNumberSpellOut() ?? "0元"
    }
    
    func getAlreadyHuanCount() -> String {
        itemJson.persons.reduce(0) { (result, item) -> Int in
            result + item.sendOtherMony
        }.description
    }
    
    func getMyReciveCount() -> String {
        itemJson.persons.reduce(0) { (result, item) -> Int in
            result + item.myCountMoney
        }.description
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        GeometryReader { (proxy)  in
            Path { (path) in
                path.addEllipse(in: proxy.frame(in: .local))
            }.fill(LinearGradient(gradient: Gradient(colors: Color.selectedColor), startPoint: .leading, endPoint: .trailing))
        }
    }
}
