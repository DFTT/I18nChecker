//
//  LSConfig.swift
//  I18nChecker
//
//  Created by dadadongl on 2024/8/14.
//

import Foundation

struct LSConfig {
    /// 开始扫描的项目目录
    let rootDirectoryPath: String
    /// 需要跳过的目录名
    let excludeDirectoryNames: [String]

    /// xxx.strings文件名
    let stringsFileName: String
    /// xx.lproj文件夹的父目录, 最终生成 xx.lproj/stringsFileName.strings覆盖源文件
    let lprojParentDirPath: String

    // 翻译文档
    /// 要求
    /// 1. 第1行 是表头
    ///     表头格式必须包含为  Key | 简体中文/zh-hans |  阿拉伯语/ar |
    ///     - "Key" 这列会被优先取做xx.lproj文件夹中的key
    ///     - "简体中文/zh-hans" 以/分割, 取后半部分生成xx.lproj文件夹

    /// 翻译文档的绝对路径
    let xlsxFilePath: String
    /// 文档中的目标sheet名字
    let xlsxSheetName: String
    /// 文档单元格的内容包裹字符, 用来解决内容两端包含空格的场景,
    let xlsxCellWrapSymbol: String

    //
    static func parseFrom(path: URL) throws -> LSConfig {
        var url = path
        url.append(component: "I18nConfig.json")
        let data = try Data(contentsOf: url)
        let info = try JSONSerialization.jsonObject(with: data)
        guard let info = info as? [String: Any] else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "配置文件格式异常"])
        }

        let rootDirectoryPath: String = try __stringFrom(info, key: "rootDirectoryPath")
        let excludeDirectoryNames: [String] = try __stringArrayFrom(info, key: "excludeDirectoryNames")

        let stringsFileName: String = try __stringFrom(info, key: "stringsFileName")
        let lprojParentDirPath: String = try __stringFrom(info, key: "lprojParentDirPath")

        let xlsxFilePath: String = try __stringFrom(info, key: "xlsxFilePath")
        let xlsxSheetName: String = try __stringFrom(info, key: "xlsxSheetName")
        let xlsxCellWrapSymbol: String = try __stringFrom(info, key: "xlsxCellWrapSymbol", allowEmpty: true)

        return .init(rootDirectoryPath: rootDirectoryPath,
                     excludeDirectoryNames: excludeDirectoryNames,
                     stringsFileName: stringsFileName,
                     lprojParentDirPath: lprojParentDirPath,
                     xlsxFilePath: xlsxFilePath,
                     xlsxSheetName: xlsxSheetName,
                     xlsxCellWrapSymbol: xlsxCellWrapSymbol.count == 1 ? xlsxCellWrapSymbol : "")

        func __stringFrom(_ info: [String: Any], key: String, allowEmpty: Bool = false) throws -> String {
            let value: String? = (info[key] as? [String: Any])?["value"] as? String
            if allowEmpty == false {
                if value == nil {
                    throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "配置项缺失: \(key), 可运行 init 重新生成配置文件"])
                }
                if value!.isEmpty {
                    throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "配置 \(key) 不可为空"])
                }
            }

            return value ?? ""
        }

        func __stringArrayFrom(_ info: [String: Any], key: String) throws -> [String] {
            let value: [String]? = (info[key] as? [String: Any])?["value"] as? [String]
            if value == nil {
                throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "\(key) 不能为空"])
            }
            return value!
        }
    }

    //
    static func makeConfigFile(toPath: URL) throws {
        var url = toPath
        url.append(component: "I18nConfig.json")
        if FileManager.default.fileExists(atPath: url.path) {
            return
        }
        try configFile().write(to: url, atomically: true, encoding: .utf8)
    }

    private static func configFile() -> String {
        return
            """
            {
                "rootDirectoryPath" : {
                    "notes" : "***代码根目录, 深遍历提取代码中需翻译文本***",
                    "value" : ""
                },

                "excludeDirectoryNames" : {
                    "notes" : "***代码扫描时, 需要跳过的目录名***",
                    "value" : ["Pods"]
                },

                "stringsFileName" : {
                    "notes" : "***最终要生成的xxx.strings文件名(不带'.string')***",
                    "value" : ""
                },

                "lprojParentDirPath" : {
                    "notes" : "***xx.lproj文件夹的父目录, 最终会生成xx.lproj/[stringsFileName].strings覆盖源文件***",
                    "value" : ""
                },

                "xlsxFilePath" : {
                    "notes" : [
                        "***Excel翻译文档路径***",
                        "要求第1行是表头",
                        "表头格式必须包含为  Key | 简体中文/zh-hans |  阿拉伯语/ar |",
                        "Key: 这列会被优先取做xx.lproj文件夹中的key",
                        "简体中文/zh-hans: 会以/分割, 取后半部分生成xx.lproj文件夹"
                    ],
                    "value" : ""
                },

                "xlsxSheetName" : {
                    "notes" : "***文档中的目标sheet名字, 一般第一个sheet的默认名字是Sheet1***",
                    "value" : ""
                },

                "xlsxCellWrapSymbol" : {
                    "notes" : "***文档单元格的内容包裹字符, 用来解决内容两端包含空格的场景, 比如 ' key ' -> '$ key $', 只需要在此项配置 "$", 工具在读取单元格内容时, 会判断首尾是否是此字符, 并自动删除后匹配.  注意: 仅支持配置一个字符, 如果原内容首尾需要此字符, 请写两次避免被删除",
                    "value" : ""
                }
            }

            """
    }
}
