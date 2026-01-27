class User < ApplicationRecord
  has_many :conversations, dependent: :destroy
  has_one :adler_schema, dependent: :destroy

  validates :email, presence: true, uniqueness: true
end
