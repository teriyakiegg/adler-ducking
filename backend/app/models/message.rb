class Message < ApplicationRecord
  belongs_to :conversation
  has_many :schema_mappings, dependent: :destroy

  validates :role, presence: true, inclusion: { in: %w[user eddie system] }
  validates :content, presence: true
end
