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

const BODY_IMAGE_CONTENT_TYPES = ["image/jpeg", "image/png", "image/webp"]
const BODY_IMAGE_EXTENSIONS = ["jpg", "jpeg", "png", "webp"]
const BODY_IMAGE_MAX_BYTES = 5 * 1024 * 1024

export default class extends Controller {
  static targets = ["source", "bodyImageList", "bodyImageSignedId"]
  static values = { uploadUrl: String }

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

    defaultOptions.controls.image = {
      exec: () => this.selectBodyImage(),
      tooltip: "画像をアップロード"
    }
  }

  selectBodyImage() {
    if (!this.editor) {
      return
    }

    const input = document.createElement("input")
    input.type = "file"
    input.accept = BODY_IMAGE_CONTENT_TYPES.join(",")
    input.hidden = true

    input.addEventListener("change", () => {
      if (!input.files?.length) {
        input.remove()
        return
      }

      this.uploadBodyImageFiles(input.files).catch(() => {}).finally(() => input.remove())
    }, { once: true })

    document.body.append(input)
    input.click()
  }

  uploadBodyImageFiles(files) {
    return this.editor.uploader.upload(files).then((response) => this.handleUploadSuccess(response))
  }

  handleUploadSuccess(response) {
    const payload = response?.data || response || {}
    const files = payload.files || []
    const signedIds = payload.signed_ids || []

    this.addBodyImageSignedIds(signedIds)

    files.forEach((file, index) => {
      if (payload.isImages?.[index] === false) {
        return
      }

      const url = `${payload.baseurl || ""}${file}`
      if (url.startsWith("data:") || /^https?:\/\//i.test(url)) {
        this.showUploadError("本文画像を挿入できませんでした")
        return
      }

      this.editor.selection.insertImage(url)
    })

    this.syncToSource()
  }

  addBodyImageSignedIds(signedIds) {
    if (!this.hasBodyImageListTarget) {
      return
    }

    signedIds.forEach((signedId) => {
      if (!signedId || this.bodyImageSignedIds.includes(signedId)) {
        return
      }

      const field = document.createElement("input")
      field.type = "hidden"
      field.name = "article[body_image_signed_ids][]"
      field.value = signedId
      field.dataset.richTextEditorTarget = "bodyImageSignedId"
      this.bodyImageListTarget.append(field)
    })
  }

  validateFiles(files) {
    for (const file of files) {
      const extension = file.name.split(".").pop()?.toLowerCase() || ""

      if (file.size === 0) {
        return "本文画像が空です"
      }

      if (file.size > BODY_IMAGE_MAX_BYTES) {
        return "本文画像のファイルサイズは5MB以下にしてください"
      }

      if (!BODY_IMAGE_CONTENT_TYPES.includes(file.type)) {
        return "本文画像はJPEG、PNG、WebP形式のみアップロードできます"
      }

      if (!BODY_IMAGE_EXTENSIONS.includes(extension)) {
        return "本文画像の拡張子が正しくありません"
      }
    }

    return null
  }

  showUploadError(message) {
    this.editor?.message?.error(message || "本文画像をアップロードできませんでした", 4000)
  }

  syncBeforeSubmit() {
    this.syncToSource()
  }

  syncToSource() {
    if (!this.editor || !this.hasSourceTarget) {
      return
    }

    this.sourceTarget.value = this.normalizeImageDimensions(this.editor.value)
  }

  normalizeImageDimensions(html) {
    const document = new DOMParser().parseFromString(html || "", "text/html")

    document.body.querySelectorAll("img").forEach((image) => {
      this.normalizeImageSource(image)

      const width = this.validImageDimension(image.getAttribute("width")) || this.validImageDimension(image.style.width)
      const height = this.validImageDimension(image.getAttribute("height")) || this.validImageDimension(image.style.height)

      if (width) {
        image.setAttribute("width", width)
      } else {
        image.removeAttribute("width")
      }

      if (height) {
        image.setAttribute("height", height)
      } else {
        image.removeAttribute("height")
      }

      image.removeAttribute("style")
    })

    return document.body.innerHTML
  }

  normalizeImageSource(image) {
    const src = image.getAttribute("src")?.trim() || ""

    try {
      const url = new URL(src, window.location.origin)
      if (url.origin === window.location.origin &&
          url.pathname.startsWith("/rails/active_storage/blobs/") &&
          !url.search &&
          !url.hash) {
        image.setAttribute("src", url.pathname)
      }
    } catch (_) {
      return
    }
  }

  validImageDimension(value) {
    const match = value?.toString().trim().match(/^(\d+)(px)?$/i)
    if (!match) {
      return null
    }

    const dimension = Number.parseInt(match[1], 10)
    return dimension > 0 ? dimension.toString() : null
  }

  get bodyImageSignedIds() {
    return this.bodyImageSignedIdTargets.map((field) => field.value)
  }

  get form() {
    return this.element.closest("form")
  }

  get editorType() {
    const enabledEditorTypeField = this.form?.querySelector("[name='article[editor_type]']:not([disabled])")
    const fallbackEditorTypeField = this.form?.querySelector("input[name='article[editor_type]']")
    return enabledEditorTypeField?.value || fallbackEditorTypeField?.value || "markdown"
  }

  get csrfToken() {
    return document.querySelector("meta[name=\"csrf-token\"]")?.content || ""
  }

  get joditConstructor() {
    return window.Jodit?.Jodit || window.Jodit
  }

  get toolbarButtons() {
    return [
      "paragraph",
      "fontsize",
      "brush",
      "underline",
      "link",
      "undo",
      "redo",
      "eraser",
      "image"
    ]
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
      buttons: this.toolbarButtons,
      buttonsMD: this.toolbarButtons,
      buttonsSM: this.toolbarButtons,
      buttonsXS: this.toolbarButtons,
      controls: {
        paragraph: {
          list: BLOCK_OPTIONS
        },
        fontsize: {
          list: FONT_SIZE_OPTIONS
        },
        image: {
          exec: () => this.selectBodyImage(),
          tooltip: "画像をアップロード"
        }
      },
      uploader: {
        url: this.uploadUrlValue,
        insertImageAsBase64URI: false,
        imagesExtensions: BODY_IMAGE_EXTENSIONS,
        filesVariableName: () => "image",
        headers: {
          "X-CSRF-Token": this.csrfToken,
          "Accept": "application/json"
        },
        beforeUpload: (files) => {
          const message = this.validateFiles(files)
          if (message) {
            this.showUploadError(message)
            return false
          }
        },
        defaultHandlerSuccess: (response) => this.handleUploadSuccess(response),
        defaultHandlerError: (error) => this.showUploadError(error.message),
        error: (error) => this.showUploadError(error.message)
      },
      filebrowser: {
        ajax: {
          url: ""
        }
      },
      allowResizeTags: new Set(["img"]),
      resizer: {
        showSize: true,
        forImageChangeAttributes: true,
        min_width: 20,
        min_height: 20,
        useAspectRatio: new Set(["img"])
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
