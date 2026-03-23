class OrganizationMembership < ApplicationRecord
  belongs_to :user
  belongs_to :organization

  enum :role, { org_admin: 0, instructor: 1 }

  validates :user_id, uniqueness: { scope: :organization_id, message: "is already a member of this organization" }
end