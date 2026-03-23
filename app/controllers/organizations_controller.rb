class OrganizationsController < ApplicationController
  before_action :set_organization, only: [:show, :add_instructor]

  def create
    org = Organization.new(name: params[:name], creator_id: @current_user.id)

    if org.save
      org.organization_memberships.create!(user: @current_user, role: :org_admin)
      render_success(org_data(org), status: :created)
    else
      render_error("Failed to create Organization", :unprocessable_entity, details: org.errors.full_messages)
    end
  end

  def show
    unless member_of?(@organization)
      return render_error("You are not a member of this Organization", :forbidden)
    end

    render_success(org_data(@organization))
  end

  def add_instructor
    unless admin_of?(@organization)
      return render_error("Only org admins can add Instructors", :forbidden)
    end

    user = User.find_by(id: params[:user_id])
    return render_error("No user found with id #{params[:user_id]}", :not_found) unless user

    if already_member?(@organization, user)
      return render_error("#{user.name} is already a member of this Organization", :unprocessable_entity)
    end

    membership = @organization.organization_memberships.create(user: user, role: :instructor)

    if membership.persisted?
      render_success({ message: "#{user.name} added as Instructor", membership: membership_data(membership) }, status: :created)
    else
      render_error("Failed to add Instructor", :unprocessable_entity, details: membership.errors.full_messages)
    end
  end

  private

  def set_organization
    @organization = Organization.find_by(id: params[:id])
    render_error("No organization found with id #{params[:id]}", :not_found) unless @organization
  end

  def member_of?(org)
    org.organization_memberships.exists?(user: @current_user)
  end

  def admin_of?(org)
    org.organization_memberships.org_admin.exists?(user: @current_user)
  end

  def already_member?(org, user)
    org.organization_memberships.exists?(user: user)
  end

  def org_data(org)
    {
      id: org.id,
      name: org.name,
      created_by: org.creator.name,
      members: org.organization_memberships.includes(:user).map { |m| membership_data(m) }
    }
  end

  def membership_data(membership)
    {
      user_id: membership.user_id,
      name: membership.user.name,
      role: membership.role
    }
  end
end
