require "rails"
require "refiner/query"
require "refiner/version"

module Refiner
  module ViewHelpers
    REFINER_VALUE = {
      remove:  -> (query, scope, slug) { (query[scope].split(/,/) - [slug.to_s]).join(',')  },
      merge:   -> (query, scope, slug) { (query[scope] || "").split(/,/).push(slug.to_s).uniq.join(',') },
      replace: -> (query, scope, slug) { slug.to_s }
    }

    EMPTY_KEYWORD_FALLBACK = "_all"

    def refiner_path(scope, slug, type, search: nil, fallback: nil)
      merged_query = refiners type, scope.to_s, slug
      merged_query = add_keyword_fallback merged_query

      filter_path = merged_query.keys.map { |key| [key, merged_query[key]] }.join('/')
      merged_query.present? ? self.send(search, filter_path) : self.send(fallback)
    end

    def add_keyword_fallback(merged_query)
      unless merged_query["keyword"].present?
        merged_query["keyword"] = EMPTY_KEYWORD_FALLBACK
      end
      merged_query
    end

    def refiner_active? scope, slug
      (refiner_query[scope.to_s] || "").split(/,/).include?(slug.to_s) ? 'active' : nil
    end

    def refiner_value action, scope, slug
      REFINER_VALUE[refiner_value_selector(action, scope, slug)].call(refiner_query, scope, slug)
    end

    def refiner_value_selector action, scope, slug
      refiner_active?(scope, slug).nil? ? action : :remove
    end

    def refiners action, scope, slug
      merge_values = refiner_value action, scope, slug
      if merge_values.present?
        refiner_query.merge({ scope => merge_values })
      else
        refiner_query.delete_if { |k, v| k == scope }
      end
    end
  end

  class Engine < ::Rails::Engine
    ActionView::Base.send :include, Refiner::ViewHelpers
  end
end
