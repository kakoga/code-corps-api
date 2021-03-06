# == Schema Information
#
# Table name: user_roles
#
#  id         :integer          not null, primary key
#  user_id    :integer
#  role_id    :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class UserRolesController < ApplicationController
  before_action :doorkeeper_authorize!

  def create
    user_role = UserRole.new(create_params)

    authorize user_role

    if user_role.valid?
      user_role.save!
      render json: user_role, include: [:user, :role]
    else
      render_validation_errors user_role.errors
    end
  end

  def destroy
    user_role = UserRole.find(params[:id])

    authorize user_role

    user_role.destroy!

    render json: :nothing, status: :no_content
  end

  private

    def create_params
      params_for_user(
        parse_params(params, only: [:role])
      )
    end
end
