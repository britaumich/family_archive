import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["checkbox", "button"]
  static values = { 
    selectText: String,
    unselectText: String 
  }

  toggle() {
    const allChecked = this.checkboxTargets.every(cb => cb.checked)
    
    this.checkboxTargets.forEach(cb => cb.checked = !allChecked)
    this.buttonTarget.textContent = allChecked ? this.selectTextValue : this.unselectTextValue
  }
}