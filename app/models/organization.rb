class Organization < ApplicationRecord
  belongs_to :creator, class_name: "User", foreign_key: :creator_id
  has_many :organization_memberships, dependent: :destroy
  has_many :members, through: :organization_memberships, source: :user

  validates :name, presence: true
end
