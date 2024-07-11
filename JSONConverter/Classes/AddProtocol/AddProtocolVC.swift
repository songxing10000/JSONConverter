//
//  ViewController.swift
//  completeCode
//
//  Created by mac on 2023/10/23.
//

import Cocoa
import Highlightr

class AddProtocolVC: NSViewController {
    @IBOutlet weak var m_topLeftTextView: NSTextView!
    @IBOutlet weak var m_topRightTextView: NSTextView!
    private lazy var m_topLeftCodeAttributedString: CodeAttributedString = {
        let storage = CodeAttributedString()
        storage.highlightr.setTheme(to: "solarized-dark")
        storage.highlightr.theme.codeFont = NSFont(name: "Menlo", size: 14)
        storage.language = "swift"
        return storage
    }()
    private lazy var m_topRightCodeAttributedString: CodeAttributedString = {
        let storage = CodeAttributedString()
        storage.highlightr.setTheme(to: "solarized-dark")
        storage.highlightr.theme.codeFont = NSFont(name: "Menlo", size: 14)
        storage.language = "swift"
        return storage
    }()
    private lazy var m_bottomCodeAttributedString: CodeAttributedString = {
        let storage = CodeAttributedString()
        storage.highlightr.setTheme(to: "solarized-dark")
        storage.highlightr.theme.codeFont = NSFont(name: "Menlo", size: 14)
        storage.language = "swift"
        return storage
    }()
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "自动实现协议 Decodable, NSSecureCoding, NSCoding"
        config(textView: m_topLeftTextView)
        config(textView: m_topRightTextView)
        
        m_topLeftCodeAttributedString.addLayoutManager(m_topLeftTextView.layoutManager!)
        m_topRightCodeAttributedString.addLayoutManager(m_topRightTextView.layoutManager!)
        
        let attrContent = NSAttributedString(string: """
import Foundation

class LoginUser: NSObject {
    
    var user_id: String?
     
    var nick_name: String?
     
    var head_image: String?
     
    var im: String?
    
    var im_sig: String?
}

""")
        m_topLeftTextView.textStorage?.setAttributedString(attrContent)
        clipsToBoundsTrueFor(view: self.view)

    }
    private func clipsToBoundsTrueFor(view: NSView) {
        view.clipsToBounds = true
        for subView in view.subviews {
            clipsToBoundsTrueFor(view: subView)
        }
    }
    private func config(textView: NSTextView?) {
        textView?.isAutomaticQuoteSubstitutionEnabled = false
        textView?.isContinuousSpellCheckingEnabled = false
        textView?.delegate = self
        textView?.setUpLineNumberView()
    }
    @IBAction func clickCopyBtn(_ sender: NSButton) {
        let pasteboard = NSPasteboard.general
        
        let textToCopy = self.m_topRightTextView.string
        
        pasteboard.clearContents()
        pasteboard.setString(textToCopy, forType: .string)
        
        if pasteboard.string(forType: .string) != nil {
            sender.title = "复制成功"
        } else {
            sender.title = "无法复制到粘贴板"
        }
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 2, execute: {
            sender.title = "复制"
        })
    }
    private func Alert(msg: String) {
        let alert = NSAlert()
        alert.alertStyle = .critical
        alert.messageText = "出错了"
        alert.informativeText = msg
        alert.addButton(withTitle: "确定")
        alert.runModal()
    }
    @IBAction func clickRefreshBtn(_ sender: NSButton) {
        //        Alert(msg: "没有找到注释")
        let infoDict = docInfoFrom(docTextView: m_topLeftTextView)
        var CodingKeyStr = "\n"
        var initStr = ""
        /// 赋值
        var initValue = "\n"
        var aCoderStr = ""
        var dCoderStr = ""
        var decodeObjectStr = ""
        var initValueCon = ""
        for (propertyName, propertyType) in infoDict {
            let typeNoMark = propertyType.replacingOccurrences(of: "?", with: "")
            CodingKeyStr += "\n         case \(propertyName)"
            initStr += "\(propertyName): \(typeNoMark), "
            initValue += "\n        self.\(propertyName) = \(propertyName)"
            aCoderStr +=
"""

        aCoder.encode(\(propertyName), forKey: "\(propertyName)")
"""
            dCoderStr +=
"""
    
        self.\(propertyName) = try? container?.decode(\(typeNoMark).self, forKey: .\(propertyName))
"""
            decodeObjectStr +=
"""

        let \(propertyName) = aDecoder.decodeObject(forKey: "\(propertyName)") as? String ?? ""
"""
            initValueCon += "\(propertyName): \(propertyName), "
        }
        initStr.removeLast()
        initStr.removeLast()
        initValueCon.removeLast()
        initValueCon.removeLast()
        var leftStr = m_topLeftTextView.string
        leftStr.removeLast()
        leftStr.removeLast()
        let outStr =
"""
\(leftStr)

    enum CodingKeys: CodingKey {\(CodingKeyStr)
    }

    init(\(initStr)) {\(initValue)
    }

    // MARK:  NSSecureCoding
    static var supportsSecureCoding: Bool {

        return true
    }


    // MARK:  NSCoding
    func encode(with aCoder: NSCoder) {
    \(aCoderStr)

    }

    required init(from decoder: Decoder) throws {

        let container = try? decoder.container(keyedBy: CodingKeys.self)
         \(dCoderStr)
    }
    required convenience init?(coder aDecoder: NSCoder) {
        
        \(decodeObjectStr)

        self.init(\(initValueCon))
    }
}
"""
        
        let attrContent2 = NSAttributedString(string: outStr)
        m_topRightTextView.textStorage?.setAttributedString(attrContent2)
    }
    private func docInfoFrom(docTextView: NSTextView) -> [String: String] {
        let pattern = #"var\s+(\w+):\s(\S+)\??\n"#
        var infoDict = [String: String]()
        
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: .dotMatchesLineSeparators)
            let matches = regex.matches(in: docTextView.string, range: NSRange(docTextView.string.startIndex..., in: docTextView.string))
            
            for match in matches {
                let commentRange = Range(match.range(at: 1), in: docTextView.string)!
                let fieldNameRange = Range(match.range(at: 2), in: docTextView.string)!
                
                let propertyName = docTextView.string[commentRange].trimmingCharacters(in: .whitespacesAndNewlines)
                let propertyType = docTextView.string[fieldNameRange]
                
                if let oldValue = infoDict[propertyName], !oldValue.isEmpty {
                    Alert(msg: "有相同的字段\(propertyName)")
                } else {
                    infoDict[propertyName] = String(propertyType)
                }
            }
        } catch {
            print("error:", error)
        }
        return infoDict
    }
}

extension AddProtocolVC: NSTextViewDelegate {
    func textView(_ textView: NSTextView, clickedOnLink link: Any, at charIndex: Int) -> Bool {
        if let value = link as? String,
           let url = URL(string: value) {
            NSWorkspace.shared.open(url)
        }
        
        return true
    }
    
    func textDidChange(_ notification: Notification) {
    }
}
