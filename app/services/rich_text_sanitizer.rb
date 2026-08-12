require "cgi"
require "nokogiri"
require "set"
require "uri"

class RichTextSanitizer
  ALLOWED_TAGS = %w[p br h2 h3 h4 strong em u a ul ol li span img pre code].freeze
  DROP_TAGS = %w[script style iframe object embed form input textarea select button svg math].freeze
  TEXT_FORMAT_TAG_REPLACEMENTS = {
    "b" => "strong",
    "i" => "em",
    "h1" => "h2",
    "h5" => "h4",
    "h6" => "h4"
  }.freeze
  LINK_ATTRIBUTES = %w[href title target rel].freeze
  IMAGE_ATTRIBUTES = %w[src alt width height].freeze
  SPAN_ATTRIBUTES = %w[style].freeze
  ALLOWED_LINK_SCHEMES = %w[http https].freeze
  ALLOWED_FONT_SIZES = %w[0.875rem 1rem 1.25rem 1.5rem].freeze
  ALLOWED_COLORS = %w[#111827 #374151 #2563EB #047857 #B45309 #B91C1C].freeze
  MAX_IMAGE_DIMENSION = 4_000

  class << self
    def sanitize(html, allowed_blob_ids: nil)
      new(html, allowed_blob_ids: allowed_blob_ids).sanitize
    end
  end

  def initialize(html, allowed_blob_ids: nil)
    @html = html.to_s
    @allowed_blob_ids = allowed_blob_ids&.to_set
  end

  def sanitize
    fragment = Nokogiri::HTML5.fragment(html)
    sanitize_children(fragment)
    fragment.to_html
  rescue ArgumentError, TypeError, Nokogiri::XML::SyntaxError
    ""
  end

  private
    attr_reader :html, :allowed_blob_ids

    def sanitize_children(parent)
      parent.children.to_a.each do |node|
        sanitize_node(node)
      end
    end

    def sanitize_node(node)
      return if node.text?
      return node.remove unless node.element?

      replacement = replacement_tag(node.name)
      node.name = replacement if replacement

      if DROP_TAGS.include?(node.name)
        node.remove
        return
      end

      unless ALLOWED_TAGS.include?(node.name)
        sanitize_children(node)
        node.replace(node.children)
        return
      end

      sanitize_children(node)
      sanitize_attributes(node)
    end

    def replacement_tag(tag_name)
      TEXT_FORMAT_TAG_REPLACEMENTS[tag_name]
    end

    def sanitize_attributes(node)
      allowed = allowed_attributes_for(node.name)

      node.attribute_nodes.each do |attribute|
        node.remove_attribute(attribute.name) unless allowed.include?(attribute.name) && !event_attribute?(attribute.name)
      end

      case node.name
      when "a"
        sanitize_link(node)
      when "img"
        sanitize_image(node)
      when "span"
        sanitize_span(node)
      end
    end

    def allowed_attributes_for(tag_name)
      case tag_name
      when "a" then LINK_ATTRIBUTES
      when "img" then IMAGE_ATTRIBUTES
      when "span" then SPAN_ATTRIBUTES
      else []
      end
    end

    def event_attribute?(name)
      name.to_s.downcase.start_with?("on")
    end

    def sanitize_link(node)
      href = node["href"].to_s.strip
      node.remove_attribute("href") unless allowed_link_href?(href)

      if node["target"] == "_blank"
        node["rel"] = "noopener noreferrer"
      else
        node.remove_attribute("target")
        node.remove_attribute("rel")
      end
    end

    def allowed_link_href?(href)
      return false if href.blank? || href.start_with?("//")
      return true if same_origin_path?(href)

      uri = URI.parse(href)
      uri.scheme.present? && ALLOWED_LINK_SCHEMES.include?(uri.scheme.downcase)
    rescue URI::InvalidURIError
      false
    end

    def sanitize_image(node)
      src = node["src"].to_s.strip
      normalized_src = normalized_active_storage_image_src(src)
      unless normalized_src
        node.remove
        return
      end

      node["src"] = normalized_src
      normalize_dimension(node, "width")
      normalize_dimension(node, "height")
    end

    def normalized_active_storage_image_src(src)
      blob = active_storage_blob_from_src(src)
      return nil unless blob
      return nil unless ArticleBodyImageUpload.valid_blob?(blob)
      return nil if allowed_blob_ids && !allowed_blob_ids.include?(blob.id)

      active_storage_path_from_src(src)
    end

    def active_storage_blob_from_src(src)
      path = active_storage_path_from_src(src)
      return nil unless path

      signed_id = signed_blob_id_from_path(path)
      return nil if signed_id.blank?

      ActiveStorage::Blob.find_signed(CGI.unescape(signed_id))
    rescue URI::InvalidURIError, ActiveSupport::MessageVerifier::InvalidSignature
      nil
    end

    def active_storage_path_from_src(src)
      return nil if src.blank? || src.start_with?("//")

      uri = URI.parse(src)
      return nil if uri.query.present? || uri.fragment.present?
      return nil if uri.scheme.present? && !%w[http https].include?(uri.scheme.downcase)

      path = uri.path.to_s
      return nil unless signed_blob_id_from_path(path)

      path
    rescue URI::InvalidURIError
      nil
    end

    def signed_blob_id_from_path(path)
      segments = path.to_s.split("/")
      return nil unless segments[1] == "rails" && segments[2] == "active_storage" && segments[3] == "blobs"

      signed_id = if %w[redirect proxy].include?(segments[4])
        segments[5]
      else
        segments[4]
      end
      signed_id.presence
    end

    def normalize_dimension(node, attribute_name)
      dimension = valid_dimension(node[attribute_name])

      if dimension
        node[attribute_name] = dimension
      else
        node.remove_attribute(attribute_name)
      end
    end

    def valid_dimension(value)
      match = value.to_s.strip.match(/\A(\d+)(px)?\z/i)
      return nil unless match

      dimension = match[1].to_i
      return nil unless dimension.positive? && dimension <= MAX_IMAGE_DIMENSION

      dimension.to_s
    end

    def sanitize_span(node)
      declarations = allowed_style_declarations(node["style"].to_s)

      if declarations.any?
        node["style"] = declarations.join("; ")
      else
        node.remove_attribute("style")
      end
    end

    def allowed_style_declarations(style)
      style.split(";").filter_map do |declaration|
        property, value = declaration.split(":", 2).map { |part| part.to_s.strip }
        next if property.blank? || value.blank?

        case property.downcase
        when "color"
          color = normalize_color(value)
          "color: #{color}" if color
        when "font-size"
          size = normalize_font_size(value)
          "font-size: #{size}" if size
        end
      end
    end

    def normalize_color(value)
      normalized = value.upcase
      ALLOWED_COLORS.find { |color| color.upcase == normalized }
    end

    def normalize_font_size(value)
      ALLOWED_FONT_SIZES.find { |size| size == value.downcase }
    end

    def same_origin_path?(value)
      value.start_with?("/") && !value.start_with?("//")
    end
end
