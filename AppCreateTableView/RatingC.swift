//
//  RatingC.swift
//  AppCreateTableView
//
//  Created by mac on 14.07.2021.
//

import UIKit

@IBDesignable final class RatingC: UIStackView {

    // MARK: - Propirties
    
    var rating = 0
    
    private var ratingButtons = [UIButton]()
    
    //отвечает за кол во звезд в стеквью и их размер
    @IBInspectable var starSize: CGSize = CGSize(width: 44.0, height: 44.0) {   //размер звезд
        didSet {
            updateButtonSelectionState()
        }
        
    }
    @IBInspectable var starCount: Int = 5 {     //кол во звезд
        didSet {
            setupButtons()
        }
        
    }
    
    
    // MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupButtons()
    }
    
    required init(coder: NSCoder) {
        super.init(coder: coder)
        setupButtons()
    }

    //MARK: - Button actions
    
    @objc func ratingButtonTapped(button: UIButton) {
        
        guard let index = ratingButtons.firstIndex(of: button) else { return }      //определяем индекс кнопки которой касаемся
        
        //calculate the rating of the selevted button
        let selectedRating = index + 1
        
        if selectedRating == rating {
            rating = 0
        } else {
            rating = selectedRating
        }
        
    }
    
    // MARK: - Private Methods

    private func setupButtons() {
        
        for button in ratingButtons {
            removeArrangedSubview(button)
            button.removeFromSuperview()
        }
        
        ratingButtons.removeAll()
        
        //load button image
        let bundle = Bundle(for:  type(of: self))
        let filledStar = UIImage(named: "filledStar",
                                 in: bundle,
                                 compatibleWith: self.traitCollection)
        
        let emptyStar = UIImage(named: "emptyStar",
                                in: bundle,
                                compatibleWith: self.traitCollection)
        
        let highlightedStar = UIImage(named: "highligtedStar",
                                      in: bundle,
                                      compatibleWith: self.traitCollection)
        
        
        
        for _ in 0 ..< starCount {
            //create button
            let button = UIButton()
            
            //присваиваем изображение кнопке
            button.setImage(emptyStar, for: .normal)
            button.setImage(filledStar, for: .selected)
            button.setImage(highlightedStar, for: .highlighted)
            button.setImage(highlightedStar, for: [.highlighted, .selected])
            
            
            //add constraints
            button.translatesAutoresizingMaskIntoConstraints = false        //отключаем авто генерируемые констреинты которые задаются при задании кнопки через код, но в стеквью по дефолту отключено
            button.heightAnchor.constraint(equalToConstant: starSize.height).isActive = true   //теперь устанавливаем констреинты самостоятельно
            button.widthAnchor.constraint(equalToConstant: starSize.width).isActive = true
            
            //setup the button action
            button.addTarget(self, action: #selector(ratingButtonTapped(button:)), for: .touchUpInside)
            
            //add the button to the stack
            addArrangedSubview(button)  //добавляет кнопку в список представлений как сабвью рейтинг контрол
            
            //add the new button on the button array
            ratingButtons.append(button)
        }
        updateButtonSelectionState()
    }
    
    //обновление рейтинга звезд в соответствии с выбранной звездой
    private func updateButtonSelectionState() {
        for (index, button) in ratingButtons.enumerated() {
            button.isSelected = index < rating
        }
    }
    
}
