import Foundation

struct UnsplashAPIClient {
    private let accessKey = "m9Rt6aY2G_jMImnpVYbbMD_kJBInYQ3F4LIikHdygqU"
    private let limit = 30

    func searchPhotos(query: String, page: Int = 1, sort: String = "relevant", width: Int = 400, height: Int = 300, completion: @escaping (Result<[Photo], Error>) -> Void) {
        let urlString = "https://api.unsplash.com/search/photos?query=\(query)&order_by=\(sort)&per_page=\(limit)&client_id=\(accessKey)&w=\(width)&h=\(height)"
        


        
        guard let url = URL(string: urlString) else {
            return
        }

        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = data else {
                return
            }

            do {
                let result = try JSONDecoder().decode(SearchResult.self, from: data)
                completion(.success(result.results))
            } catch {
                completion(.failure(error))
            }
        }
        task.resume()
    }
}

struct SearchResult: Codable {
    let results: [Photo]
}

struct Photo: Codable {
    let id: String
    let description: String?
    let urls: PhotoURLs
    let user: User // Информация о пользователе
    
    var author: String {
        return user.name
    }
}

struct PhotoURLs: Codable {
    let small: String
    let regular: String
}

struct User: Codable {
    let name: String
}
