//
//  LSFileParser.swift
//  LocalStringFileCteater
//
//  Created by 大大东 on 2023/11/25.
//

import Cocoa
import CoreXLSX

private(set) var lastErrorMsg = ""

enum KeyFromMode: String {
    case excel
    case code
}

class LSFileParser {
    private let xFile: XLSXFile
    private let sheetNamePathMap: [(name: String?, path: String)]
    private let allStrings: SharedStrings

    init?(xmlPath: String) {
        // 读文件
        guard let file = XLSXFile(filepath: xmlPath) else {
            lastErrorMsg = "Error: file not found~~~~"
            return nil
        }

        // 解析sheet索引
        guard let workBook = try? file.parseWorkbooks().first,
              let sheetNamePathMap = try? file.parseWorksheetPathsAndNames(workbook: workBook),
              let allStrings = try? file.parseSharedStrings()
        else {
            lastErrorMsg = "Error: workBook not found~~~~"
            return nil
        }

        xFile = file
        self.sheetNamePathMap = sheetNamePathMap
        self.allStrings = allStrings
    }

    //
    private var languages = [LanguageItem]()

    var allKeys: Set<String> {
        Set(languages.first!.kvs.keys)
    }

    // 解析
    func parse(headRowIdx: Int = 0,
               sheetName: String = "Sheet1")
    {
        // 获取sheet
        guard sheetName.isEmpty == false else {
            lastErrorMsg = "Error: sheet name param error ~~~~"
            return
        }
        let targetSheetInfo = sheetNamePathMap.first { $0.name == sheetName }
        guard let targetSheetInfo = targetSheetInfo else {
            lastErrorMsg = "Error: not find sheet as name: \(sheetName) "
            return
        }
        guard let workSheet = try? xFile.parseWorksheet(at: targetSheetInfo.path) else {
            lastErrorMsg = "Error: sheet parse fali ~~~~"
            return
        }

        // 获取所有行 (表头以下所有行)
        guard let rowsArr = workSheet.data?.rows, rowsArr.count > headRowIdx + 1 else {
            lastErrorMsg = "Error: rows count is error ~~~~"
            return
        }

        // 获取表头 (优先key, 其次..)
        let keyCell = rowsArr[headRowIdx].cells.first { cell in
            ___textFor(cell: cell, trimming: true) == "Key"
        }
        guard let keyCell = keyCell else {
            lastErrorMsg = "Error: not found 'Key' columen in first row"
            return
        }
        // 获取有效的表头列
        let headCells = rowsArr[headRowIdx].cells.compactMap { cell in
            let ss = ___textFor(cell: cell, trimming: true)
            let comps = ss.components(separatedBy: "/").filter { $0.isEmpty == false }
            if comps.count == 2 {
                return HeaderCellItem(desc: comps.first!, code: comps.last!, cell: cell)
            }
            return nil
        }
        guard headCells.count >= 1 else {
            lastErrorMsg = "Error:  visiable columens must > 0 in first row"
            return
        }

        var repeatKeyCout = 0

        // 第headRowIdx行做当做表头 第valueBeginColumnIdx列会当做国际化的key
        var resMap = [HeaderCellItem: LanguageItem]()

        // 遍历行
        for row in rowsArr[1 ..< rowsArr.count] {
            // 取key
            guard let rowKeycell = ___seamColumnCell(in: row, with: keyCell) else {
                printColoredLog("key cell not found at (\(row.reference):\(keyCell.reference.column))", color: .red)
                continue
            }
            let ketStr = ___textFor(cell: rowKeycell, trimming: true)
            guard ketStr.isEmpty == false else {
                printColoredLog("key cell content empty at (\(row.reference):\(keyCell.reference.column))", color: .red)
                continue
            }

            // 取列
            for (idx, hCell) in headCells.enumerated() {
                guard let cell = ___seamColumnCell(in: row, with: hCell.cell) else {
                    printColoredLog("value Cell not found at (\(row.reference):\(hCell.cell.reference.column))", color: .red)
                    continue
                }
                let valueStr = ___textFor(cell: cell, trimming: true)
                guard valueStr.isEmpty == false else {
                    printColoredLog("value Cell content empty at (\(row.reference):\(hCell.cell.reference.column))", color: .red)
                    continue
                }

                // 存储
                let language = resMap[hCell] ?? LanguageItem(header: hCell)
                /// 判断下key重复
                if idx == 0, language.kvs[ketStr] != nil {
                    printColoredLog("Duplicate key is \(ketStr)", color: .yellow)
                    repeatKeyCout += 1
                }
                language.kvs[ketStr] = KeyValueItem(key: ketStr, value: valueStr)
                resMap[hCell] = language
            }
        }

        // 解析完成
        printColoredLog("""
                        👏🏻👏🏻👏🏻解析完成!
                            共\(1 + resMap.values.first!.kvs.count + repeatKeyCout)行 (1行表头),
                            解析出\(resMap.count)种语言,
                            每种语言\(resMap.values.first!.kvs.count)个key-Value,
                            \(repeatKeyCout)个重复key \n\n
                        """,
                        color: .green)

        // 临时用 去重
//        resMap.first?.value.kvs.keys.forEach { ee in
//            if let _ = arr.firstIndex(of: ee) {
//
//            }else {
//                print(":: \(ee)")
//            }
//        }
//        return ;
        // 临时用
//        let language: LanguageKVs = resMap["简体中文"]!
//        var newmmm = [String: String]()
//        language.kvs.forEach { _, item in
//            newmmm[item.value] = item.key
//            print("\"\(item.value)\" : \"\(item.key)\","  )
//        }

        // 检查数量是否一致
        let cont = resMap.first!.value.kvs.count
        for (key, value) in resMap {
            if value.kvs.count != cont {
                print("\n⚠️⚠️⚠️\(key) 的kv数量不等于 \(cont)\n")
            }
        }

        languages = Array(resMap.values)
    }

    // 写回去
    func backWrite(with filter: (String) -> Bool) {
        let fileManager = FileManager.default

        for language in languages {
            // 排序 拼接
            var contentString = language.kvs.values
                .filter { filter($0.key) }
                .sorted { $0.key < $1.key }
                .map { "\"\($0.key)\" = \"\($0.value)\";" }
                .joined(separator: "\n")
            contentString.append("\n")

            // 输出路径
            var url = URL(filePath: ctx.lprojParentDirPath)
            url.append(component: "/\(language.header.code).lproj/\(ctx.stringsFileName).strings")

            /// 尝试删除旧文件
            if fileManager.fileExists(atPath: url.path) {
                try? fileManager.removeItem(at: url)
            }
            /// 尝试创建文件夹
            try? fileManager.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)

            do {
                /// 尝试写入新文件
                try contentString.write(to: url, atomically: true, encoding: .utf8)
            } catch let e {
                printColoredLog("\(e)", color: .red)
                lastErrorMsg = "Error: write file fail to \(url)"
            }
        }
    }

    func ___textFor(cell: Cell?, trimming: Bool) -> String {
        guard let cell = cell else { return "" }
        var text = cell.stringValue(allStrings) ?? ""
        if trimming {
            text = text.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        }
        text = text.replacingOccurrences(of: "\n", with: "\\n")
        // 可能是富文本
        if text.isEmpty {
            let richArr: [RichText] = cell.richStringValue(allStrings)
            if richArr.isEmpty == false {
                text = (richArr.compactMap { $0.text } as [String]).joined()
                if trimming {
                    text = text.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                }
                text = text.replacingOccurrences(of: "\n", with: "\\n")
            }
        }
        //
        if ctx.xlsxCellWrapSymbol.isEmpty == false {
            if text.hasPrefix(ctx.xlsxCellWrapSymbol) {
                text.removeFirst()
            }
            if text.hasSuffix(ctx.xlsxCellWrapSymbol) {
                text.removeLast()
            }
        }
        return text
    }

    func ___seamColumnCell(in row: Row, with sCell: Cell) -> Cell? {
        // (这种找法更精准, 防止每行的cells数量不相等)
        return row.cells.first { $0.reference.column == sCell.reference.column }
    }
}

private struct KeyValueItem {
    let key: String
    let value: String
}

private class LanguageItem {
    let header: HeaderCellItem
    var kvs = [String: KeyValueItem]()

    init(header: HeaderCellItem) {
        self.header = header
    }
}

private struct HeaderCellItem: Hashable {
    let desc: String
    let code: String
    let cell: Cell

    func hash(into hasher: inout Hasher) {
        hasher.combine(desc)
        hasher.combine(code)
        hasher.combine(cell.reference.row)
        hasher.combine(cell.reference.column.value)
    }
}
