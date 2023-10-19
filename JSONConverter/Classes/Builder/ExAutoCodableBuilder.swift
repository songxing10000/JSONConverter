//
//  ExAutoCodable.swift
//  JSONConverter
//
//  Created by mac on 2023/10/19.
//  Copyright © 2023 姚巍. All rights reserved.
//

import Foundation

class ExAutoCodableBuilder: BuilderProtocol {
    func isMatchLang(_ lang: LangType) -> Bool {
        return  lang == .ExAutoCodable
    }
    
    func propertyText(_ type: PropertyType, keyName: String, strategy: PropertyStrategy, maxKeyNameLength: Int, keyTypeName: String?) -> String {
        assert(!((type == .Dictionary || type == .ArrayDictionary) && keyTypeName == nil), " Dictionary type the typeName can not be nil")
        let tempKeyName = strategy.processed(keyName)
        switch type {
        case .String, .Null:
            return "\n\t@ExCodable\n\tvar \(tempKeyName): String?\n"
        case .Int:
            return "\n\t@ExCodable\n\tvar \(tempKeyName): Int = 0\n"
        case .Float:
            return "\n\t@ExCodable\n\tvar \(tempKeyName): Float = 0.0\n"
        case .Double:
            return "\n\t@ExCodable\n\tvar \(tempKeyName): Double = 0.0\n"
        case .Bool:
            return "\n\t@ExCodable\n\tvar \(tempKeyName): Bool = false\n"
        case .Dictionary:
            return "\n\t@ExCodable\n\tvar \(tempKeyName): \(keyTypeName!)?\n"
        case .ArrayString, .ArrayNull:
            return "\n\t@ExCodable\n\tvar \(tempKeyName) = [String]()\n"
        case .ArrayInt:
            return "\n\t@ExCodable\n\tvar \(tempKeyName) = [Int]()\n"
        case .ArrayFloat:
            return "\n\t@ExCodable\n\tvar \(tempKeyName) = [Float]()\n"
        case .ArrayDouble:
            return "\n\t@ExCodable\n\tvar \(tempKeyName) = [Double]()\n"
        case .ArrayBool:
            return "\n\t@ExCodable\n\tvar \(tempKeyName) = [Bool]()\n"
        case .ArrayDictionary:
            return "\n\t@ExCodable\n\tvar \(tempKeyName) = [\(keyTypeName!)]()\n"
        }
    }
    
    func contentParentClassText(_ clsText: String?) -> String {
       return StringUtils.isEmpty(clsText) ? ": ExAutoCodable" : ": \(clsText!)"
    }
    
    func contentText(_ structType: StructType, clsName: String, parentClsName: String, propertiesText: String, propertiesInitText: String?, propertiesGetterSetterText: String?) -> String {
        if structType == .class {
            return "\nclass \(clsName)\(parentClsName) {\n\(propertiesText)\n\trequired init() {}\n}\n"
        } else {
            let tempPropertiesText = StringUtils.removeLastChar(propertiesText)
            return "\nstruct \(clsName)\(parentClsName) {\n\(tempPropertiesText)\n}\n"
        }
    }
    
    func fileSuffix() -> String {
        return "swift"
    }
    
    func fileImportText(_ rootName: String, contents: [Content], strategy: PropertyStrategy, prefix: String?) -> String {
        return"\nimport Foundation\nimport ExCodable\n"
    }
    
    func fileExport(_ path: String, config: File, content: String, classImplContent: String?) -> [Export] {
        let filePath = "\(path)/\(config.rootName.className(withPrefix: config.prefix))"
        return [Export(path: "\(filePath).\(fileSuffix())", content: content)]
    }
   //
}
//
