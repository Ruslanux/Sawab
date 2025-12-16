import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="dark-mode"
export default class extends Controller {
  static targets = ["icon"]

  connect() {
    // Check for saved theme preference or default to system preference
    const savedTheme = localStorage.getItem("theme")
    const systemPrefersDark = window.matchMedia("(prefers-color-scheme: dark)").matches

    if (savedTheme === "dark" || (!savedTheme && systemPrefersDark)) {
      this.enableDarkMode()
    } else {
      this.disableDarkMode()
    }

    // Listen for system theme changes
    window.matchMedia("(prefers-color-scheme: dark)").addEventListener("change", (e) => {
      if (!localStorage.getItem("theme")) {
        if (e.matches) {
          this.enableDarkMode()
        } else {
          this.disableDarkMode()
        }
      }
    })
  }

  toggle() {
    if (document.documentElement.classList.contains("dark")) {
      this.disableDarkMode()
      localStorage.setItem("theme", "light")
    } else {
      this.enableDarkMode()
      localStorage.setItem("theme", "dark")
    }
  }

  enableDarkMode() {
    document.documentElement.classList.add("dark")
    this.updateIcon()
  }

  disableDarkMode() {
    document.documentElement.classList.remove("dark")
    this.updateIcon()
  }

  updateIcon() {
    if (!this.hasIconTarget) return

    const isDark = document.documentElement.classList.contains("dark")
    const moonIcon = this.iconTarget.querySelector("[data-icon='moon']")
    const sunIcon = this.iconTarget.querySelector("[data-icon='sun']")

    if (moonIcon && sunIcon) {
      if (isDark) {
        // Dark mode active - show sun icon (to toggle to light)
        moonIcon.style.display = "none"
        sunIcon.style.display = "block"
      } else {
        // Light mode active - show moon icon (to toggle to dark)
        moonIcon.style.display = "block"
        sunIcon.style.display = "none"
      }
    }
  }
}
