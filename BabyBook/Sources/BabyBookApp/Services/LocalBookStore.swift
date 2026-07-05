import Foundation

// MARK: - 本地绘本元数据模型
struct LocalBookMetadata: Codable, Identifiable {
    let id: String          // orderId
    let orderId: String
    let bookId: String
    let bookName: String
    let filePath: String    // 图片文件路径
    let pdfFilePath: String? // PDF 文件路径（可选，兼容旧数据）
    let createTime: Date
}

// MARK: - 本地绘本存储服务
class LocalBookStore {
    static let shared = LocalBookStore()

    private let metadataFileName = "books_metadata.json"

    private var metadataURL: URL? {
        guard let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        return documentsPath.appendingPathComponent(metadataFileName)
    }

    // MARK: - 保存绘本元数据
    /// - Parameter createTime: 绘本生成时间，默认当前时间；更新已存在记录时保留原生成时间
    /// - Parameter pdfFilePath: 生成的 PDF 文件路径，可选
    func save(orderId: String, bookId: String, bookName: String, filePath: String, pdfFilePath: String? = nil, createTime: Date? = nil) {
        guard let url = metadataURL else { return }

        var books = loadAll()

        // 如果已存在则更新，否则新增
        let finalCreateTime: Date
        if let index = books.firstIndex(where: { $0.orderId == orderId }) {
            finalCreateTime = createTime ?? books[index].createTime
        } else {
            finalCreateTime = createTime ?? Date()
        }

        let metadata = LocalBookMetadata(
            id: orderId,
            orderId: orderId,
            bookId: bookId,
            bookName: bookName,
            filePath: filePath,
            pdfFilePath: pdfFilePath,
            createTime: finalCreateTime
        )

        if let index = books.firstIndex(where: { $0.orderId == orderId }) {
            books[index] = metadata
        } else {
            books.append(metadata)
        }

        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(books)
            try data.write(to: url)
        } catch {
            print("保存绘本元数据失败: \(error)")
        }
    }

    // MARK: - 加载所有绘本元数据
    func loadAll() -> [LocalBookMetadata] {
        guard let url = metadataURL,
              FileManager.default.fileExists(atPath: url.path) else {
            return []
        }

        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode([LocalBookMetadata].self, from: data)
        } catch {
            print("加载绘本元数据失败: \(error)")
            return []
        }
    }

    // MARK: - 删除绘本元数据
    func delete(orderId: String) {
        guard let url = metadataURL else { return }

        var books = loadAll()
        books.removeAll { $0.orderId == orderId }

        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(books)
            try data.write(to: url)
        } catch {
            print("删除绘本元数据失败: \(error)")
        }
    }

    // MARK: - 检查绘本是否存在
    func exists(orderId: String) -> Bool {
        loadAll().contains { $0.orderId == orderId }
    }

    // MARK: - 根据订单 ID 查询绘本
    func get(orderId: String) -> LocalBookMetadata? {
        loadAll().first { $0.orderId == orderId }
    }
}
