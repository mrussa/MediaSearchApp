import UIKit

class PhotoCollectionViewCell: UICollectionViewCell {
    var imageView: UIImageView!
    var descriptionLabel: UILabel!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        // Создание UIImageView для превью изображения
        imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: contentView.frame.size.width, height: contentView.frame.size.height - 40))
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        contentView.addSubview(imageView)
        
        // Создание UILabel для описания изображения
        descriptionLabel = UILabel(frame: CGRect(x: 5, y: contentView.frame.size.height - 40, width: contentView.frame.size.width - 10, height: 40))
        descriptionLabel.numberOfLines = 2
        descriptionLabel.font = UIFont.systemFont(ofSize: 14)
        contentView.addSubview(descriptionLabel)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // Настройка ячейки с данными изображения
    func configure(with photo: Photo) {
        descriptionLabel.text = photo.description ?? "Нет описания"
        
        // Загрузка изображения по URL
        if let url = URL(string: photo.urls.small) {
            URLSession.shared.dataTask(with: url) { data, response, error in
                if let data = data {
                    DispatchQueue.main.async {
                        self.imageView.image = UIImage(data: data)
                    }
                }
            }.resume()
        }
    }
}
