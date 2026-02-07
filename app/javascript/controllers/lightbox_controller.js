import { Controller } from "@hotwired/stimulus"
import GLightbox from "glightbox"

export default class extends Controller {
  static targets = ["gallery"]
  
  connect() {
    this.initializeLightbox()
  }
  
  initializeLightbox() {
    // Initialize GLightbox for all images in the gallery
    this.lightbox = GLightbox({
      selector: '[data-lightbox]',
      touchNavigation: true,
      loop: true,
      autoplayVideos: true,
      closeButton: true,
      closeOnOutsideClick: true,
      openEffect: 'zoom',
      closeEffect: 'zoom',
      slideEffect: 'slide',
      moreText: 'View details',
      moreLength: 60,
      lightboxHTML: '<div id="glightbox-body" class="glightbox-container"><div class="gloader visible"></div><div class="goverlay"></div><div class="gcontainer"><div id="glightbox-slider" class="gslider"></div><button class="gnext gbtn" tabindex="0" aria-label="Next" data-customattribute="example">{nextSVG}</button><button class="gprev gbtn" tabindex="1" aria-label="Previous">{prevSVG}</button><button class="gclose gbtn" tabindex="2" aria-label="Close">{closeSVG}</button></div></div>'
    })
  }
  
  disconnect() {
    if (this.lightbox) {
      this.lightbox.destroy()
    }
  }
}