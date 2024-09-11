import Foundation

// MARK: - Search Result Model
struct SearchResult: Codable {
    let results: [Photo]
}

// MARK: - Photo Model
struct Photo: Codable {
    let id: String
    let description: String?
    let urls: PhotoURLs
    let user: User
    
    var author: String {
        return user.name
    }
}

// MARK: - Photo URLs Model
struct PhotoURLs: Codable {
    let small: String
    let regular: String
}

// MARK: - User Model
struct User: Codable {
    let name: String
}

// MARK: - UnsplashAPIClient

class UnsplashAPIClient {
    
    private let accessKey = "m9Rt6aY2G_jMImnpVYbbMD_kJBInYQ3F4LIikHdygqU"
    private let limit = 30
    
    // Создание NSCache для кэширования результатов
    private var cache = NSCache<NSString, NSArray>()
    
    // Настройка URLCache с размерами
    private let urlCache: URLCache = {
        let memoryCapacity = 50 * 1024 * 1024  // 50 MB
        let diskCapacity = 100 * 1024 * 1024  // 100 MB
        let cache = URLCache(memoryCapacity: memoryCapacity, diskCapacity: diskCapacity, diskPath: "unsplash_cache")
        return cache
    }()
    
    init() {
        // Установка кастомного URLCache для URLSession
        URLCache.shared = urlCache
    }
    
    // MARK: - Search Photos Method with Caching
    func searchPhotos(query: String, page: Int = 1, sort: String = "relevant", width: Int = 400, height: Int = 300, completion: @escaping (Result<[Photo], Error>) -> Void) {
        
        let cacheKey = NSString(string: "\(query)_\(page)_\(sort)_\(width)_\(height)")
        
        // Проверка кэша на наличие результатов
        if let cachedResults = cache.object(forKey: cacheKey) as? [Photo] {
            print("Использование кэшированных данных для запроса: \(query)")
            completion(.success(cachedResults))
            return
        }
        
        let urlString = "https://api.unsplash.com/search/photos?query=\(query)&order_by=\(sort)&per_page=\(limit)&client_id=\(accessKey)&w=\(width)&h=\(height)"
        
        guard let url = URL(string: urlString) else {
            return
        }

        let request = URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad, timeoutInterval: 10)
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                completion(.failure(NSError(domain: "", code: (response as? HTTPURLResponse)?.statusCode ?? 500, userInfo: [NSLocalizedDescriptionKey: "Ошибка сети"])))
                return
            }

            guard let data = data else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Нет данных"])))
                return
            }

            do {
                let result = try JSONDecoder().decode(SearchResult.self, from: data)
                
                // Сохранение результатов в кэш
                self.cache.setObject(result.results as NSArray, forKey: cacheKey)
                
                completion(.success(result.results))
            } catch {
                completion(.failure(error))
            }
        }
        task.resume()
    }
}
