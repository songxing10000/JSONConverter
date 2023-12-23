//
//  ExAutoCodable.swift
//  JSONConverter
//
//  Created by mac on 2023/10/19.
//  Copyright © 2023 姚巍. All rights reserved.
//

import Foundation

class ArkTSBuilder: BuilderProtocol {
    func isMatchLang(_ lang: LangType) -> Bool {
        return  lang == .ArkTS
    }
    
    func propertyText(_ type: PropertyType, keyName: String, strategy: PropertyStrategy, maxKeyNameLength: Int, keyTypeName: String?) -> String {
        assert(!((type == .Dictionary || type == .ArrayDictionary) && keyTypeName == nil), " Dictionary type the typeName can not be nil")
        let tempKeyName = strategy.processed(keyName)
        switch type {
        case .String, .Null:
            return "\n\t\(tempKeyName)?: string\n"
        case .Int:
            return "\n\t\(tempKeyName)?: number\n"
        case .Float:
            return "\n\t\(tempKeyName)?: number\n"
        case .Double:
            return "\n\t\(tempKeyName)?: number\n"
        case .Bool:
            return "\n\t\(tempKeyName)?: boolean\n"
        case .Dictionary:
            return "\n\t\(tempKeyName): \(keyTypeName!)?\n"
        case .ArrayString, .ArrayNull:
            return "\n\t\(tempKeyName)?: Array<string>\n"
        case .ArrayInt:
            return "\n\t\(tempKeyName)?: Array<number>\n"
        case .ArrayFloat:
            return "\n\t\(tempKeyName)?: Array<number>\n"
        case .ArrayDouble:
            return "\n\t\(tempKeyName) ?: Array<number>\n"
        case .ArrayBool:
            return "\n\t\(tempKeyName)?: Array<boolean>\n"
        case .ArrayDictionary:
            return "\n\t\(tempKeyName)?: Array<\(keyTypeName!)>\n"
        }
    }
    
    func contentParentClassText(_ clsText: String?) -> String {
       return StringUtils.isEmpty(clsText) ? "" : ": \(clsText!)"
    }
    
    func contentText(_ structType: StructType, clsName: String, parentClsName: String, propertiesText: String, propertiesInitText: String?, propertiesGetterSetterText: String?) -> String {
        if structType == .class {
            return 
"""
export class \(clsName)\(parentClsName) {
\(propertiesText)
\tconstructor(\(propertiesText.replacingOccurrences(of: "\n\n\t", with: ", ").replacingOccurrences(of: "\n\t", with: "").replacingOccurrences(of: "\n", with: ""))) {
    // 不需要手动赋值，参数属性会自动将参数值赋给类的属性
  }
}

"""
        } else {
            let tempPropertiesText = StringUtils.removeLastChar(propertiesText)
            return "\nstruct \(clsName)\(parentClsName) {\n\(tempPropertiesText)\n}\n"
        }
    }
    
    func fileSuffix() -> String {
        return "ets"
    }
    
    func fileImportText(_ rootName: String, contents: [Content], strategy: PropertyStrategy, prefix: String?) -> String {
        return"\n"
    }
    
    func fileExport(_ path: String, config: File, content: String, classImplContent: String?) -> [Export] {
        let filePath = "\(path)/\(config.rootName.className(withPrefix: config.prefix))"
        return [Export(path: "\(filePath).\(fileSuffix())", content: content)]
    }
   //
}
//
