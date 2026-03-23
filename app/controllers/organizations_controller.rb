class OrganizationsController < ApplicationController
  before_action :set_organization, only: [:show, :add_instructor]

  def create
    org = Organization.new(name: params[:name], creator_id: @current_user.id)

    if org.save
      org.organization_memberships.create!(user: @current_user, role: :org_admin)
      render json: org_response(org), status: :created
    else
      render json: { errors: org.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def show
    unless member_of?(@organization)
      return render json: { error: "You are not a member of this organization" }, status: :forbidden
    end

    render json: org_response(@organization)
  end

  def add_instructor
    unless admin_of?(@organization)
      return render json: { error: "Only org admins can add instructors" }, status: :forbidden
    end

    user = User.find_by(id: params[:user_id])
    return render json: { error: "User not found" }, status: :not_found unless user

    membership = @organization.organization_memberships.new(user: user, role: :instructor)

    if membership.save
      render json: {
        message: "#{user.name} added as instructor",
        membership: membership_response(membership)
      }, status: :created
    else
      render json: { errors: membership.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def set_organization
    @organization = Organization.find_by(id: params[:id])
    render json: { error: "Organization not found" }, status: :not_found unless @organization
  end

  def member_of?(org)
    org.organization_memberships.exists?(user: @current_user)
  end

  def admin_of?(org)
    org.organization_memberships.org_admin.exists?(user: @current_user)
  end

  def org_response(org)
    {
      id: org.id,
      name: org.name,
      created_by: org.creator.name,
      members: org.organization_memberships.includes(:user).map { |m| membership_response(m) }
    }
  end

  def membership_response(membership)
    {
      user_id: membership.user_id,
      name: membership.user.name,
      role: membership.role
    }
  end
end
