# frozen_string_literal: true

module Phlex::Rails
	module Layout
		include Helpers::CSPMetaTag
		include Helpers::CSRFMetaTags
		include Helpers::FaviconLinkTag
		include Helpers::PreloadLinkTag
		include Helpers::StylesheetLinkTag
		include Helpers::ActionCableMetaTag
		include Helpers::AutoDiscoveryLinkTag
		include Helpers::JavaScriptIncludeTag
		include Helpers::JavaScriptImportmapModulePreloadTags
		include Helpers::JavaScriptImportmapTags
		include Helpers::JavaScriptImportModuleTag
		include Helpers::JavaScriptInlineImportmapTag
		include Helpers::JavaScriptModulePreloadTag
		include Helpers::TurboRefreshMethodTag
		include Helpers::TurboRefreshScrollTag
		include Helpers::TurboRefreshesWith
		include Helpers::TurboExemptsPageFromCacheTag
		include Helpers::TurboExemptsPageFromPreviewTag
		include Helpers::TurboPageRequiresReloadTag

		module Interface
			def render(view_context, _locals, &)
				new.render(view_context, &)
			end

			def identifier
				name
			end

			def virtual_path
				return @virtual_path if defined? @virtual_path

				@virtual_path = name&.dup.tap do |n|
					n.gsub!("::", ".")
					n.gsub!(/([a-z])([A-Z])/, '\1_\2')
					n.downcase!
				end
			end
		end

		def self.included(base)
			unless base < Phlex::HTML
				raise Phlex::ArgumentError.new("👋 #{name} should only be included into Phlex::HTML classes.")
			end

			base.extend(Interface)
			super
		end

		def render(view_context = nil, *args, **kwargs, &block)
			if @_state
				super
			else
				render_in(view_context) do |yielded|
					case yielded
					when Symbol
						raw view_context.view_flow.get(yielded)
					else
						yield
					end
				end
			end
		end

		def identifier
			self.class.identifier
		end

		def virtual_path
			self.class.virtual_path
		end
	end
end
