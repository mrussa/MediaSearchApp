import XCTest
@testable import MediaSearchApp

// MARK: - PhotoCollectionViewCellTests
class PhotoCollectionViewCellTests: XCTestCase {

    // MARK: - Test Cell Configuration
    func testPhotoCellConfiguresCorrectly() {
        let cell = PhotoCollectionViewCell()
        
        let photo = Photo(id: "1",
                          description: "Test Description",
                          urls: PhotoURLs(
                              small: "https://via.placeholder.com/150",
                              regular: "https://via.placeholder.com/600"
                          ),
                          user: User(name: "Test User"))

        cell.configure(with: photo)

        // MARK: - Check Description
        XCTAssertEqual(cell.descriptionLabel.text, "Test Description")
        
        // MARK: - Check Image Loading
        let expectation = self.expectation(description: "Image Loaded")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            XCTAssertNotNil(cell.imageView.image)
            expectation.fulfill()
        }

        waitForExpectations(timeout: 5.0, handler: nil)
    }
}

// MARK: - UnsplashAPIClientTests
class UnsplashAPIClientTests: XCTestCase {

    // MARK: - Test API Success
    func testSearchPhotosSuccess() {
        let client = MockAPIClient() // Используйте мок-версию API клиента
        let expectation = self.expectation(description: "Photos fetched")
        
        client.searchPhotos(query: "cats", page: 1) { result in
            switch result {
            case .success(let photos):
                XCTAssertNotNil(photos)
                XCTAssertTrue(photos.count > 0)
                XCTAssertEqual(photos.first?.description, "Test Photo")
            case .failure(let error):
                XCTFail("Failed to fetch photos: \(error)")
            }
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 5, handler: nil)
    }
}

// MARK: - PhotoDetailViewControllerTests
class PhotoDetailViewControllerTests: XCTestCase {

    // MARK: - Test Detail View Controller Data Display
    func testPhotoDetailViewControllerDisplaysCorrectData() {
        let photo = Photo(id: "1", description: "Test", urls: PhotoURLs(small: "", regular: ""), user: User(name: "Author"))
        let detailVC = PhotoDetailViewController()
        detailVC.photo = photo
        detailVC.loadViewIfNeeded()

        XCTAssertEqual(detailVC.descriptionLabel.text, "Test")
        XCTAssertEqual(detailVC.authorLabel.text, "Автор: Author")
    }
}

// MARK: - SearchViewControllerTests

class SearchViewControllerTests: XCTestCase {

    var searchVC: SearchViewController!

    override func setUp() {
        super.setUp()
        searchVC = SearchViewController()
        searchVC.loadViewIfNeeded() // Загружаем view для тестов UI
    }

    func testLoadSearchHistory() {
        UserDefaults.standard.set(["cat", "dog", "bird"], forKey: "searchHistory")
        searchVC.loadSearchHistory()
        XCTAssertEqual(searchVC.searchHistory, ["cat", "dog", "bird"], "История поиска должна загружаться правильно")
    }

    func testSaveSearchHistory() {
        searchVC.searchHistory = ["cat", "dog", "bird"]
        searchVC.saveSearchHistory()
        let savedHistory = UserDefaults.standard.array(forKey: "searchHistory") as? [String]
        XCTAssertEqual(savedHistory, ["cat", "dog", "bird"], "История поиска должна сохраняться правильно")
    }

}


class MockAPIClient: UnsplashAPIClient {
    override func searchPhotos(query: String, page: Int = 1, sort: String = "relevant", width: Int = 400, height: Int = 300, completion: @escaping (Result<[Photo], Error>) -> Void) {
        let photos = [Photo(id: "1", description: "Test Photo", urls: PhotoURLs(small: "", regular: ""), user: User(name: "Test User"))]
        completion(.success(photos))
    }
}


