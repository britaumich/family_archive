import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["checkbox", "button", "error"]
  static values = { 
    selectText: String,
    unselectText: String 
  }

  connect() {
    // Add form submission validation
    this.form = this.element.closest('form')
    if (this.form) {
      this.form.addEventListener('submit', this.validateSubmission.bind(this))
    }
  }

  disconnect() {
    // Clean up event listener
    if (this.form) {
      this.form.removeEventListener('submit', this.validateSubmission.bind(this))
    }
  }

  toggle() {
    const allChecked = this.checkboxTargets.every(cb => cb.checked)
    
    this.checkboxTargets.forEach(cb => cb.checked = !allChecked)
    this.buttonTarget.textContent = allChecked ? this.selectTextValue : this.unselectTextValue
    
    // Clear any error messages when toggling
    this.clearError()
  }

  validateSubmission(event) {
    const selectedItems = this.checkboxTargets.filter(cb => cb.checked)
    
    if (selectedItems.length === 0) {
      event.preventDefault()
      event.stopImmediatePropagation()
      this.showError("Please select at least one item before proceeding.")
      return false
    }
    
    // Also check if any tags are selected
    const tagCheckboxes = this.form.querySelectorAll('input[type="checkbox"][name="tag_ids[]"]')
    const hasSelectedTags = Array.from(tagCheckboxes).some(checkbox => {
      return checkbox.checked && checkbox.value !== ""
    })
    
    if (!hasSelectedTags) {
      event.preventDefault()
      event.stopImmediatePropagation()
      this.showError("Please select at least one tag before proceeding.")
      return false
    }
    
    this.clearError()
    return true
  }

  showError(message) {
    if (this.hasErrorTarget) {
      this.errorTarget.textContent = message
      this.errorTarget.style.display = 'block'
      this.errorTarget.scrollIntoView({ behavior: 'smooth', block: 'nearest' })
    }
  }

  clearError() {
    if (this.hasErrorTarget) {
      this.errorTarget.style.display = 'none'
      this.errorTarget.textContent = ''
    }
  }
}