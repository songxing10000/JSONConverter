//
//  MainViewController.swift
//  JSONConverter
//
//  Created by Yao on 2018/1/27.
//  Copyright © 2018年 Yao. All rights reserved.
//

import Cocoa

enum LangType: Int {
    case Swift = 0
    case HandyJSON
    case SwiftyJSON
    case ObjectMapper
    case ObjC
    case Flutter
    case Codable
    
    var suffix: String {
        switch self {
        case .Swift, .HandyJSON, .SwiftyJSON, .ObjectMapper, .Codable:
            return "swift"
        case .ObjC:
            return "h"
        case .Flutter:
            return "dart"
        }
    }
}

enum StructType: Int {
    case `struct` = 0
    case `class`
}

struct LangStruct {
    var langType: LangType
    var structType: StructType
    
    init(langType: LangType, structType: StructType) {
        self.langType = langType
        self.structType = structType
    }
}

let FILE_CACHE_CONFIG_KEY = "FILE_CACHE_CONFIG_KEY"

class MainViewController: NSViewController {
    
    lazy var transTypeTitleList: [String] = {
        let titleArr = ["Swift", "HandyJSON", "SwiftyJSON", "ObjectMapper", "Objective-C", "Flutter", "Codable"]
        return titleArr
    }()
    
    lazy var structTypeTitleList: [String] = {
        let titleArr = ["struct", "class"]
        return titleArr
    }()
    
    // 转换模式Box 选择 语言
    @IBOutlet weak var converTypeBox: NSComboBox!
    
    // 选择 类 或 结构体
    @IBOutlet weak var converStructBox: NSComboBox!
    
    @IBOutlet weak var jsonSrollView: NSScrollView!
    
    @IBOutlet var jsonTextView: NSTextView!
    
    @IBOutlet var classTextView: NSTextView!
        
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupCacheConfig()
        checkVerion()
        NotificationCenter.default.addObserver(self, selector: #selector(applicationWillTerminateNotiAction), name: NSNotification.Name.ApplicationWillTerminateNoti, object: nil)
    }
    
    private func checkVerion() {
        UpgradeUtils.newestVersion { (version) in
            guard let tagName = version?.tag_name,
                let bundleVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
                let newVersion = Int(tagName.replacingOccurrences(of: ".", with: "")),
                let currentVeriosn = Int(bundleVersion.replacingOccurrences(of: ".", with: "")) else {
                    return
            }
            
            if newVersion > currentVeriosn {
                let upgradeVc = UpgradeViewController()
                upgradeVc.versionInfo = version
                upgradeVc.currentVer = bundleVersion
                self.presentAsModalWindow(upgradeVc)
            }
        }
    }
        
    private func setupUI(){
        converTypeBox.addItems(withObjectValues: transTypeTitleList)
        converTypeBox.delegate = self
        
        converStructBox.addItems(withObjectValues: structTypeTitleList)
        converStructBox.delegate = self
        
        classTextView.isEditable = false
        jsonTextView.isAutomaticQuoteSubstitutionEnabled = false
        
        let lineNumberView = NoodleLineNumberView(scrollView: jsonSrollView)
        jsonSrollView.hasVerticalRuler = true
        jsonSrollView.hasHorizontalRuler = false
        jsonSrollView.verticalRulerView = lineNumberView
        jsonSrollView.rulersVisible = true
    }
    
    private func setupCacheConfig() {
        let configFile = FileConfigManager.shared.defaultConfigFile()
        converTypeBox.selectItem(at: configFile.langStruct.langType.rawValue)
        converStructBox.selectItem(at: configFile.langStruct.structType.rawValue)
    }
    
    @IBAction func settingAction(_ sender: NSButton) {
        let settingVC = SettingViewController()
        presentAsModalWindow(settingVC)
    }

    @IBAction func supportMeAction(_ sender: NSButton) {
        let rewardVC = RewardViewController()
        presentAsModalWindow(rewardVC)
    }
    
    @IBAction func converBtnAction(_ sender: NSButton) {
        if let jsonStr = jsonTextView.textStorage?.string {
            guard let jsonData = jsonStr.data(using: .utf8),
                let json = try? JSONSerialization.jsonObject(with: jsonData, options: .mutableContainers)else{
                    alert(title: "转换内容Josn出错", desc: "未知数据格式无法解析,请提供正确的Json字符串")
                    return
            }
            
            if let formatJosnData = try? JSONSerialization.data(withJSONObject: json as AnyObject, options: .prettyPrinted),
                let formatJsonStr = String(data: formatJosnData, encoding: .utf8){
                setJsonContent(content: formatJsonStr)
            }
            
            let configFile = FileConfigManager.shared.defaultConfigFile()
            let classStr = JSONParseManager.shared.handleEngine(frome: json, file:configFile)
            setClassContent(content: classStr)
        }
    }
    
    private func setJsonContent(content: String){
        if content.count > 0{
            let attrContent = NSMutableAttributedString(string: content)
            jsonTextView.textStorage?.setAttributedString(attrContent)
            jsonTextView.textStorage?.font = NSFont.systemFont(ofSize: 14)
            jsonTextView.textStorage?.foregroundColor = NSColor.labelColor
        }
    }
    
    private func setClassContent(content: String) {
        if content.count > 0{
            let attrContent = NSMutableAttributedString(string: content)
            classTextView.textStorage?.setAttributedString(attrContent)
            classTextView.textStorage?.font = NSFont.systemFont(ofSize: 14)
            classTextView.textStorage?.foregroundColor = NSColor.labelColor
        }
    }
    
    private func updateConfigFile() {
        let configFile = FileConfigManager.shared.defaultConfigFile()
        guard let langTypeType = LangType(rawValue: converTypeBox.indexOfSelectedItem),
            let structType = StructType(rawValue: converStructBox.indexOfSelectedItem) else {
                assert(false, "语言和结构类型组合出错")
                return
        }
        
        let transStruct = LangStruct(langType: langTypeType, structType: structType)
        configFile.langStruct = transStruct
    }
    
    private func alert(title: String, desc: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = desc
        alert.runModal()
    }
}

extension MainViewController {
    @objc func applicationWillTerminateNotiAction() {
        FileConfigManager.shared.updateConfigFile()
    }
}

extension MainViewController: NSComboBoxDelegate {
    func comboBoxSelectionDidChange(_ notification: Notification) {
        let comBox = notification.object as! NSComboBox
        if comBox == converTypeBox { // 选择语言
            let langType = LangType(rawValue: converTypeBox.indexOfSelectedItem)
            if langType == LangType.ObjC || langType == LangType.Flutter { // 如果是OC Flutter 就选择 class
                converStructBox.selectItem(at: 1)
            } else if langType == LangType.Codable {//如果是Codable 就选择 struct
                converStructBox.selectItem(at: 0)
            }
        }else if comBox == converStructBox { //选择类或结构体
            let langType = LangType(rawValue: converTypeBox.indexOfSelectedItem)
            if langType == LangType.ObjC  || langType == LangType.Flutter { // 如果是OC Flutter  无论怎么选 都是 类
                converStructBox.selectItem(at: 1)
            } else if langType == LangType.Codable {//如果是Codable 就选择 struct
                converStructBox.selectItem(at: 0)
            }
        }
        
        updateConfigFile()
    }
}

