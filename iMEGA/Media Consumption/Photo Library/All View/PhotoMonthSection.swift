import Foundation

struct PhotoMonthSection {
    var photoByMonth: PhotoByMonth
    var title: String
    
    var allPhotos: [NodeEntity] {
        photoByMonth.allPhotos
    }
    
    init(photoByMonth: PhotoByMonth) {
        self.photoByMonth = photoByMonth
        
        if #available(iOS 15.0, *) {
            title = photoByMonth.categoryDate.formatted(.dateTime.year().locale(.current))
        } else {
            title = DateFormatter.monthTemplate().localisedString(from: photoByMonth.categoryDate)
        }
    }
    
    @available(iOS 15.0, *)
    var attributedTitle: AttributedString {
        var attr = photoByMonth.categoryDate.formatted(.dateTime.locale(.current).year().month(.wide).attributed)
        let month = AttributeContainer.dateField(.month)
        let semibold = AttributeContainer.font(.subheadline.weight(.semibold))
        attr.replaceAttributes(month, with: semibold)
        
        return attr
    }
}

extension PhotoMonthSection: PhotoChronologicalCategory {
    var categoryDate: Date {
        photoByMonth.categoryDate
    }
    
    var coverPhoto: NodeEntity? {
        photoByMonth.coverPhoto
    }
}

extension PhotoMonthSection: Equatable {
    static func == (lhs: PhotoMonthSection, rhs: PhotoMonthSection) -> Bool {
        lhs.photoByMonth == rhs.photoByMonth
    }
}

extension PhotoLibrary {
    var allPhotosMonthSections: [PhotoMonthSection] {
        allPhotosByMonthList.map { PhotoMonthSection(photoByMonth: $0) }
    }
}
