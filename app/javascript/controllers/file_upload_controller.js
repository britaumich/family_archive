import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["itemType", "fileInput"]
  
  static fileExtensions = {
    photo: '.jpg,.jpeg,.png,.gif,.bmp,.webp',
    video: '.mp4,.mov,.webm,.m4v',
    document: '.pdf,.txt,.doc,.docx,.odt,.rtf'
  }

  connect() {
    this.updateFileAccept()
  }

  updateFileAccept() {
    const selectedType = this.itemTypeTarget.value
    
    if (selectedType && this.constructor.fileExtensions[selectedType]) {
      this.fileInputTarget.setAttribute('accept', this.constructor.fileExtensions[selectedType])
    } else {
      // Default to all types if no selection
      const allExtensions = Object.values(this.constructor.fileExtensions).join(',')
      this.fileInputTarget.setAttribute('accept', allExtensions)
    }
  }
}
