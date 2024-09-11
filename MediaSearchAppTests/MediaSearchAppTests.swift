import XCTest
@testable import MediaSearchApp

class PhotoCollectionViewCellTests: XCTestCase {

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

        XCTAssertEqual(cell.descriptionLabel.text, "Test Description")
        
        let expectation = self.expectation(description: "Image Loaded")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            XCTAssertNotNil(cell.imageView.image)
            expectation.fulfill()
        }

        waitForExpectations(timeout: 5.0, handler: nil)
    }
}

class UnsplashAPIClientTests: XCTestCase {

    func testSearchPhotosSuccess() {
        let client = UnsplashAPIClient()
        let expectation = self.expectation(description: "Photos fetched")
        
        client.searchPhotos(query: "cats", page: 1) { result in
            switch result {
            case .success(let photos):
                XCTAssertNotNil(photos)
                XCTAssertTrue(photos.count > 0)
            case .failure(let error):
                XCTFail("Failed to fetch photos: \(error)")
            }
            expectation.fulfill()
        }
        waitForExpectations(timeout: 5, handler: nil)
    }
}

class ViewControllerTests: XCTestCase {

    var viewController: ViewController!

    override func setUp() {
        super.setUp()
        viewController = ViewController()
        viewController.loadViewIfNeeded()
    }

    func testSegmentedControlInitialValue() {
        XCTAssertEqual(viewController.segmentedControl.selectedSegmentIndex, 0)
    }

    func testCollectionViewHasCells() {
        guard let collectionView = viewController.collectionView else {
            XCTFail("Collection view is nil")
            return
        }

        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoCell", for: IndexPath(row: 0, section: 0)) as? PhotoCollectionViewCell
        XCTAssertNotNil(cell)
    }

}

class PhotoDetailViewControllerTests: XCTestCase {

    func testPhotoDetailViewControllerDisplaysCorrectData() {
        let photo = Photo(id: "1", description: "Test", urls: PhotoURLs(small: "", regular: ""), user: User(name: "Author"))
        let detailVC = PhotoDetailViewController()
        detailVC.photo = photo
        detailVC.loadViewIfNeeded()

        XCTAssertEqual(detailVC.descriptionLabel.text, "Test")
        XCTAssertEqual(detailVC.authorLabel.text, "Автор: Author")
    }
}


