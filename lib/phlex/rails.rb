# frozen_string_literal: true

require "phlex"

module Phlex
	module Rails
		class HelpersCalledBeforeRenderError < StandardError; end

		# Pre-define Streaming with ActionController::Live included BEFORE Zeitwerk eager loads.
		# ActionController::Live uses class_attribute which can fail during eager loading
		# if ActiveSupport isn't fully initialized yet.
		# See: https://github.com/phlex-ruby/phlex-rails/issues/323
		module Streaming
			extend ActiveSupport::Concern
			include ActionController::Live
		end

		Loader = Zeitwerk::Loader.for_gem_extension(Phlex).tap do |loader|
			loader.ignore("#{__dir__}/ruby_lsp")

			loader.inflector.inflect(
				"asset_url" => "AssetURL",
				"audio_url" => "AudioURL",
				"csp_meta_tag" => "CSPMetaTag",
				"csrf_meta_tags" => "CSRFMetaTags",
				"csv" => "CSV",
				"default_url_options" => "DefaultURLOptions",
				"dom_class" => "DOMClass",
				"dom_id" => "DOMID",
				"field_id" => "FieldID",
				"font_url" => "FontURL",
				"image_url" => "ImageURL",
				"javascript_import_module_tag" => "JavaScriptImportModuleTag",
				"javascript_importmap_tags" => "JavaScriptImportmapTags",
				"javascript_include_tag" => "JavaScriptIncludeTag",
				"javascript_path" => "JavaScriptPath",
				"javascript_tag" => "JavaScriptTag",
				"javascript_url" => "JavaScriptURL",
				"path_to_javascript" => "PathToJavaScript",
				"path_to_stylesheet" => "PathToStyleSheet",
				"rich_textarea" => "RichTextArea",
				"sanitize_css" => "SanitizeCSS",
				"sgml" => "SGML",
				"sms_to" => "SMSTo",
				"stylesheet_link_tag" => "StyleSheetLinkTag",
				"stylesheet_path" => "StyleSheetPath",
				"stylesheet_url" => "StyleSheetURL",
				"textarea" => "TextArea",
				"textarea_tag" => "TextAreaTag",
				"url_field" => "URLField",
				"url_field_tag" => "URLFieldTag",
				"url_for" => "URLFor",
				"url_options" => "URLOptions",
				"url_to_asset" => "URLToAsset",
				"url_to_audio" => "URLToAudio",
				"url_to_font" => "URLToFont",
				"url_to_image" => "URLToImage",
				"url_to_javascript" => "URLToJavaScript",
				"url_to_stylesheet" => "URLToStyleSheet",
				"url_to_video" => "URLToVideo",
				"utf8_enforcer_tag" => "UTF8EnforcerTag",
				"video_url" => "VideoURL",
			)

			loader.collapse("#{__dir__}/phlex/errors")
			loader.setup
		end

		extend Phlex::Rails::Types
	end

	CSV.prepend(Phlex::Rails::CSV)
	CSV.extend(Phlex::Rails::HelperMacros)
	SGML::State.prepend(Phlex::Rails::SGML::State)

	class HTML
		extend Phlex::Rails::SGML::ClassMethods
		extend Phlex::Rails::HelperMacros

		include Phlex::Rails::SGML

		def self.format
			:html
		end

		def format
			:html
		end
	end

	class SVG
		extend Phlex::Rails::SGML::ClassMethods
		extend Phlex::Rails::HelperMacros

		include Phlex::Rails::SGML

		def self.format
			:svg
		end

		def format
			:svg
		end
	end

	ActiveSupport::SafeBuffer.include(Phlex::SGML::SafeObject)
end
