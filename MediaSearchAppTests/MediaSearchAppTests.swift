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

// MARK: - ViewControllerTests
class ViewControllerTests: XCTestCase {

    // MARK: - Properties
    var viewController: ViewController!

    // MARK: - Setup
    override func setUp() {
        super.setUp()
        viewController = ViewController()
        viewController.loadViewIfNeeded()
    }

    // MARK: - Test Segmented Control Initial Value
    func testSegmentedControlInitialValue() {
        XCTAssertEqual(viewController.segmentedControl.selectedSegmentIndex, 0)
    }

    // MARK: - Test Collection View Cells
    func testCollectionViewHasCells() {
        guard let collectionView = viewController.collectionView else {
            XCTFail("Collection view is nil")
            return
        }

        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoCell", for: IndexPath(row: 0, section: 0)) as? PhotoCollectionViewCell
        XCTAssertNotNil(cell)
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


