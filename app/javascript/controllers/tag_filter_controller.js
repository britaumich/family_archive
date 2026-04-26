import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["typeSelect", "tagGroup"]

  connect() {
    // Hide all tag groups initially
    this.tagGroupTargets.forEach(group => {
      group.style.display = "none"
    })
  }

  filterByType(event) {
    const selectedType = event.target.value
    
    this.tagGroupTargets.forEach(group => {
      const groupTypeId = group.dataset.tagTypeId
      
      if (selectedType === "") {
        // No type selected - hide all groups
        group.style.display = "none"
      } else if (selectedType === groupTypeId) {
        // Show matching type
        group.style.display = "block"
      } else {
        // Hide non-matching types
        group.style.display = "none"
      }
    })
  }
}