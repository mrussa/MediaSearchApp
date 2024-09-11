import UIKit

// MARK: - PhotoCollectionViewCell

class PhotoCollectionViewCell: UICollectionViewCell {
    var imageView: UIImageView!
    var descriptionLabel: UILabel!
    
    // MARK: - Initial Setup
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        // MARK: - UIImageView Setup
        imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(imageView)
        
        // MARK: - UILabel Setup
        descriptionLabel = UILabel()
        descriptionLabel.numberOfLines = 2
        descriptionLabel.font = UIFont.systemFont(ofSize: 14)
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(descriptionLabel)
        
        // MARK: - Constraints Setup
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.heightAnchor.constraint(equalTo: contentView.heightAnchor, multiplier: 0.8),
            
            descriptionLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 5),
            descriptionLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 5),
            descriptionLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -5),
            descriptionLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -5),
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Configure Cell with Photo Data
    func configure(with photo: Photo) {
        descriptionLabel.text = photo.description ?? "Нет описания"
        
        // MARK: - Image Loading
        if let url = URL(string: photo.urls.small) {
            URLSession.shared.dataTask(with: url) { data, response, error in
                if let error = error {
                    print("Ошибка загрузки изображения: \(error)")
                    return
                }
                guard let data = data else {
                    print("Нет данных для изображения")
                    return
                }
                DispatchQueue.main.async {
                    self.imageView.image = UIImage(data: data)
                }
            }.resume()
        } else {
            print("Неправильный URL изображения: \(photo.urls.small)")
        }
    }
}
