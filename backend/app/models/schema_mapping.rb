class SchemaMapping < ApplicationRecord
  belongs_to :adler_schema
  belongs_to :message

  validates :field, presence: true
  validates :confidence, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 1 }

  scope :confirmed, -> { where(confirmed: true) }
  scope :pending, -> { where(confirmed: false) }
end
