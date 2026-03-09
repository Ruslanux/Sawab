import { Controller } from "@hotwired/stimulus"

// Validates that password and confirmation fields match in real-time.
// Usage:
//   <div data-controller="password-match"
//        data-password-match-match-text="Passwords match"
//        data-password-match-mismatch-text="Passwords do not match">
//     <input data-password-match-target="password" data-action="input->password-match#check">
//     <input data-password-match-target="confirmation" data-action="input->password-match#check">
//     <p data-password-match-target="hint"></p>
//   </div>
export default class extends Controller {
  static targets = ["password", "confirmation", "hint"]

  check() {
    const password = this.passwordTarget.value
    const confirmation = this.confirmationTarget.value

    if (confirmation.length === 0) {
      this.hintTarget.textContent = ""
      this.confirmationTarget.classList.remove("border-green-500", "dark:border-green-500", "border-red-500", "dark:border-red-500")
      return
    }

    if (password === confirmation) {
      this.hintTarget.textContent = this.data.get("matchText") || "✓"
      this.hintTarget.className = "mt-1 text-xs text-green-600 dark:text-green-400"
      this.confirmationTarget.classList.remove("border-red-500")
      this.confirmationTarget.classList.add("border-green-500")
    } else {
      this.hintTarget.textContent = this.data.get("mismatchText") || "✗"
      this.hintTarget.className = "mt-1 text-xs text-red-600 dark:text-red-400"
      this.confirmationTarget.classList.remove("border-green-500")
      this.confirmationTarget.classList.add("border-red-500")
    }
  }
}
