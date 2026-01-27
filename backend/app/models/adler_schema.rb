class AdlerSchema < ApplicationRecord
  belongs_to :user
  has_many :schema_mappings, dependent: :destroy

  # JSONB fields default to empty hash
  after_initialize :set_defaults

  private

  def set_defaults
    self.life_tasks ||= {}
    self.life_direction ||= {}
    self.private_logic ||= {}
    self.inferiorities ||= {}
    self.courage_usage ||= {}
    self.social_interest ||= {}
  end
end
