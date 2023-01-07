//
//  plcaeNameSuggestionCell.swift
//  trackingEsri
//
//  Created by Mohamed Ali on 07/01/2023.
//

import UIKit

class placeNameSuggestionCell: UITableViewCell {
    
    @IBOutlet weak var placeNameLabel:UILabel!
    
    @IBOutlet weak var copyTextButton:UIButton!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func ConfigureCell(ob: suggestionModel) {
        placeNameLabel.text = ob.text
    }
    
}
