import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ['form']
  
  connect () {
    console.log("connect autosubmit")
  }

  clearFilters() {
    var url = window.location.pathname
    Turbo.visit(url)
  }

  submitForm() {
    console.log("here")
    Turbo.navigator.submitForm(this.formTarget)
  }
  
  search() {
    console.log("search")
    clearTimeout(this.timeout)

    this.timeout = setTimeout(() => {
      this.formTarget.requestSubmit()
    }, 200)
  }

  async check(event){
    console.log("check");
    event.preventDefault(); // Prevent default form submission
    // Gather form data
    const formData = new FormData(this.formTarget);
    try {
      // Send data using Fetch API
      const response = await fetch(this.formTarget.action, {
        method: this.formTarget.method,
        headers: {
          'Accept': 'application/json',
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').getAttribute('content')
        },
        body: formData
      });
    } 
    catch (error) {
      console.error("Error submitting form", error);
      alert("An error occurred while submitting the form.");
    }
  }
}
