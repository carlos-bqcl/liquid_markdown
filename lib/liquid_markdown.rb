require 'liquid_markdown/version'
require 'kramdown'
require 'liquid'
require 'action_view'
require 'action_mailer'
require 'liquid_markdown/strip'
require 'liquid_markdown/keys'
require 'liquid_markdown/template_handler'
require 'liquid_markdown/resolver'

module LiquidMarkdown
  class Render
    #  setup your html layout layout to wrap around your LiquidMarkdown output
    # layout = "<html><head></head><body>{{yield}}</body></html>"
    attr_reader :template, :values, :default_format
    attr_writer :layout

    MARKDOWN_OPTIONS = {auto_ids: false, parse_block_html: true}
    LIQUID_OPTIONS = {strict_filters: true, strict_variables: true}

    def initialize(template, values={}, format=:html)
      @template = template
      @values = values
      @default_format = format
    end

    def render
      rendered_content = markdown(liquidize)
      insert_into_template(rendered_content)
    end

    def markdown(template_value)
      Kramdown::Document.new(template_value, MARKDOWN_OPTIONS).to_html
    end

    def liquidize
      t = Liquid::Template.parse(@template)
      val = strip_html(@values)
      val = deep_stringify_keys(val)
      t.render(val, LIQUID_OPTIONS)
    end

    def insert_into_template(rendered_content)
      return rendered_content if layout == ''
      layout.sub('{{yield}}', rendered_content)
    end

    def layout
      @layout ||= ''
    end

    private

    def deep_stringify_keys(input_hash)
      LiquidMarkdown::Keys.deep_stringify_keys(input_hash)
    end

    def strip_html(input_hash)
      LiquidMarkdown::Strip.strip_html_values(input_hash)
    end
  end
end

ActionMailer::Base.prepend_view_path(LiquidMarkdown::Resolver.new)
ActionView::Template.register_template_handler(:liqmd, LiquidMarkdown::TemplateHandler::HTML)
ActionView::Template.register_template_handler(:liqmdt, LiquidMarkdown::TemplateHandler::Text)