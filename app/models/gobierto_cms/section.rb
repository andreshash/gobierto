# frozen_string_literal: true

require_dependency "gobierto_cms"

module GobiertoCms
  class Section < ApplicationRecord
    include GobiertoCommon::Sluggable

    belongs_to :site
    has_many :section_items, dependent: :destroy, class_name: "GobiertoCms::SectionItem"

    translates :title

    validates :site, :title, presence: true
    validates :slug, uniqueness: { scope: :site }

    def attributes_for_slug
      [title]
    end
  end
end
