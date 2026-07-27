import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["source", "preview", "button"]
  static values = { url: String }

  async preview(event) {
    event.preventDefault()

    const markdown = this.sourceTarget.value.trim()
    if (markdown === "") {
      this.showEmptyState()
      return
    }

    this.startLoading()

    try {
      const response = await fetch(this.urlValue, {
        method: "POST",
        credentials: "same-origin",
        headers: this.buildHeaders(),
        body: JSON.stringify({ markdown: markdown })
      })

      const data = await response.json()

      if (!response.ok) {
        this.showErrorState(data.error)
        return
      }

      this.showSuccessState(data.html)
    } catch {
      this.showErrorState()
    } finally {
      this.stopLoading()
    }
  }

  buildHeaders() {
    const headers = {
      "Content-Type": "application/json",
      "Accept": "application/json"
    }

    const csrfMeta = document.querySelector("meta[name='csrf-token']")
    if (csrfMeta) {
      headers["X-CSRF-Token"] = csrfMeta.content
    }

    return headers
  }

  showEmptyState() {
    this.previewTarget.innerHTML = `<div class="preview-empty">本文が入力されていません。Markdownを入力してからプレビューを実行してください。</div>`
  }

  startLoading() {
    this.buttonTarget.disabled = true
    this.buttonTarget.setAttribute("aria-busy", "true")
    this.originalButtonText = this.buttonTarget.textContent
    this.buttonTarget.textContent = "読込中..."
    this.previewTarget.innerHTML = `<div class="preview-loading">プレビューを読み込んでいます...</div>`
  }

  showSuccessState(html) {
    this.previewTarget.innerHTML = `<div class="markdown-preview-content markdown-body">${html}</div>`
  }

  showErrorState(message = "通信に失敗しました。時間をおいて再度お試しください。") {
    this.previewTarget.innerHTML = `<div class="preview-error"></div>`
    this.previewTarget.querySelector(".preview-error").textContent = message
  }

  stopLoading() {
    this.buttonTarget.disabled = false
    this.buttonTarget.removeAttribute("aria-busy")
    this.buttonTarget.textContent = this.originalButtonText
  }
}
