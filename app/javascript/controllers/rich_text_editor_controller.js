import { Controller } from "@hotwired/stimulus"
import "jodit"

const BLOCK_OPTIONS = {
  p: "通常段落",
  h2: "見出し2",
  h3: "見出し3",
  h4: "見出し4"
}

const FONT_SIZE_OPTIONS = {
  "0.875rem": "小",
  "1rem": "標準",
  "1.25rem": "大",
  "1.5rem": "特大"
}

const COLOR_OPTIONS = [
  "#111827",
  "#374151",
  "#2563EB",
  "#047857",
  "#B45309",
  "#B91C1C"
]

export default class extends Controller {
  static targets = ["source"]

  connect() {
    this.modeChanged = this.modeChanged.bind(this)
    this.syncBeforeSubmit = this.syncBeforeSubmit.bind(this)
    this.syncToSource = this.syncToSource.bind(this)
    this.element.addEventListener("article-editor-mode:before-change", this.syncToSource)
    this.element.addEventListener("article-editor-mode:changed", this.modeChanged)
    this.form?.addEventListener("submit", this.syncBeforeSubmit)

    if (this.editorType === "rich_text") {
      this.initializeEditor()
    }
  }

  disconnect() {
    this.element.removeEventListener("article-editor-mode:before-change", this.syncToSource)
    this.element.removeEventListener("article-editor-mode:changed", this.modeChanged)
    this.form?.removeEventListener("submit", this.syncBeforeSubmit)
    this.destroyEditor()
  }

  modeChanged(event) {
    if (event.detail.editorType === "rich_text") {
      this.initializeEditor()
    } else {
      this.destroyEditor()
    }
  }

  initializeEditor() {
    if (this.editor || !this.hasSourceTarget || !this.joditConstructor) {
      return
    }

    this.configureGlobalOptions()
    this.editor = this.joditConstructor.make(this.sourceTarget, this.options)
    this.editor.events.on("change", () => this.syncToSource())
    this.editor.events.on("afterSetMode", () => this.syncToSource())
    this.sourceTarget.richTextEditor = this.editor
    this.sourceTarget.dataset.richTextEditorReady = "true"
  }

  destroyEditor() {
    if (!this.editor) {
      return
    }

    this.syncToSource()
    this.editor.destruct()
    this.editor = null
    delete this.sourceTarget.richTextEditor
    delete this.sourceTarget.dataset.richTextEditorReady
  }

  configureGlobalOptions() {
    const defaultOptions = this.joditConstructor.defaultOptions

    if (!defaultOptions?.controls) {
      return
    }

    if (defaultOptions.controls.paragraph) {
      defaultOptions.controls.paragraph.list = BLOCK_OPTIONS
    }

    if (defaultOptions.controls.fontsize) {
      defaultOptions.controls.fontsize.list = FONT_SIZE_OPTIONS
    }
  }

  syncBeforeSubmit() {
    this.syncToSource()
  }

  syncToSource() {
    if (!this.editor || !this.hasSourceTarget) {
      return
    }

    this.sourceTarget.value = this.editor.value
  }

  get form() {
    return this.element.closest("form")
  }

  get editorType() {
    const enabledEditorTypeField = this.form?.querySelector("[name='article[editor_type]']:not([disabled])")
    const fallbackEditorTypeField = this.form?.querySelector("input[name='article[editor_type]']")
    return enabledEditorTypeField?.value || fallbackEditorTypeField?.value || "markdown"
  }

  get joditConstructor() {
    return window.Jodit?.Jodit || window.Jodit
  }

  get options() {
    return {
      language: "ja",
      minHeight: 420,
      toolbarAdaptive: true,
      toolbarSticky: false,
      askBeforePasteHTML: false,
      askBeforePasteFromWord: false,
      defaultActionOnPaste: "insert_clear_html",
      showCharsCounter: false,
      showWordsCounter: false,
      showXPathInStatusbar: false,
      showBrowserColorPicker: false,
      colors: COLOR_OPTIONS,
      enter: "p",
      buttons: [
        "paragraph",
        "fontsize",
        "brush",
        "underline",
        "link",
        "undo",
        "redo",
        "eraser"
      ],
      buttonsMD: [
        "paragraph",
        "fontsize",
        "brush",
        "underline",
        "link",
        "undo",
        "redo",
        "eraser"
      ],
      buttonsSM: [
        "paragraph",
        "fontsize",
        "brush",
        "underline",
        "link",
        "undo",
        "redo",
        "eraser"
      ],
      buttonsXS: [
        "paragraph",
        "fontsize",
        "brush",
        "underline",
        "link",
        "undo",
        "redo",
        "eraser"
      ],
      controls: {
        paragraph: {
          list: BLOCK_OPTIONS
        },
        fontsize: {
          list: FONT_SIZE_OPTIONS
        }
      },
      uploader: {
        url: "",
        insertImageAsBase64URI: false
      },
      filebrowser: {
        ajax: {
          url: ""
        }
      },
      enableDragAndDropFileToEditor: false,
      disablePlugins: [
        "about",
        "ai-assistant",
        "drag-and-drop",
        "drag-and-drop-element",
        "file",
        "fullsize",
        "iframe",
        "image",
        "image-processor",
        "image-properties",
        "media",
        "powered-by-jodit",
        "preview",
        "print",
        "source",
        "speech-recognize",
        "symbols",
        "table",
        "video"
      ]
    }
  }
}
