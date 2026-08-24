import { Controller } from "@hotwired/stimulus"
import GLightbox from "glightbox"

export default class extends Controller {
  connect() {
    this.openFromClick = this.openFromClick.bind(this)
    this.element.addEventListener("click", this.openFromClick)
  }

  openFromClick(event) {
    const trigger = event.target.closest(".js-lightbox-item")
    if (!trigger || !this.element.contains(trigger)) return

    event.preventDefault()

    const links = Array.from(this.element.querySelectorAll(".js-lightbox-item"))
    const elements = links.map((link) => ({
      href: link.getAttribute("href"),
      title: link.dataset.title || "",
      type: link.dataset.type || "image"
    }))

    const startIndex = links.indexOf(trigger)
    if (startIndex < 0 || elements.length === 0) return

    if (this.lightbox) {
      this.lightbox.destroy()
      this.lightbox = null
    }

    this.lightbox = GLightbox({
      elements,
      touchNavigation: true,
      loop: true,
      autoplayVideos: true,
      closeButton: true,
      closeOnOutsideClick: true,
      openEffect: "zoom",
      closeEffect: "zoom",
      slideEffect: "slide",
      moreText: "View details",
      moreLength: 60
    })

    this.lightbox.openAt(startIndex)
  }

  disconnect() {
    this.element.removeEventListener("click", this.openFromClick)

    if (this.lightbox) {
      this.lightbox.destroy()
      this.lightbox = null
    }
  }
}
