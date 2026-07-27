import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["selector", "markdownPanel", "richTextPanel", "markdownBody", "richTextBody"]

  connect() {
    this.applyMode(this.editorType)
  }

  change() {
    this.element.dispatchEvent(new CustomEvent("article-editor-mode:before-change", { bubbles: true }))
    this.syncBodyBetweenModes()
    this.applyMode(this.editorType)
  }

  get editorType() {
    if (this.hasSelectorTarget) {
      return this.selectorTarget.value
    }

    const editorTypeField = this.element.querySelector("[name='article[editor_type]']")
    return editorTypeField?.value || "markdown"
  }

  syncBodyBetweenModes() {
    if (!this.hasMarkdownBodyTarget || !this.hasRichTextBodyTarget) {
      return
    }

    if (this.editorType === "rich_text") {
      this.richTextBodyTarget.value = this.markdownBodyTarget.value
    } else {
      this.markdownBodyTarget.value = this.richTextBodyTarget.value
    }
  }

  applyMode(editorType) {
    const richText = editorType === "rich_text"

    this.togglePanel(this.markdownPanelTargets, !richText)
    this.togglePanel(this.richTextPanelTargets, richText)
    this.toggleBody(this.markdownBodyTargets, !richText)
    this.toggleBody(this.richTextBodyTargets, richText)

    this.element.dispatchEvent(new CustomEvent("article-editor-mode:changed", {
      bubbles: true,
      detail: { editorType }
    }))
  }

  togglePanel(panels, visible) {
    panels.forEach((panel) => {
      panel.hidden = !visible
      panel.classList.toggle("editor-mode-hidden", !visible)
    })
  }

  toggleBody(fields, enabled) {
    fields.forEach((field) => {
      field.disabled = !enabled
    })
  }
}
