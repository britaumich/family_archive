# == Schema Information
#
# Table name: admin_users
#
#  id         :bigint           not null, primary key
#  email      :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class AdminUser < ApplicationRecord
  before_destroy :one_admin_user_should_exist

  normalizes :email, with: ->(e) { e.strip.downcase }
  
  validates :email, presence: true, uniqueness: { case_sensitive: false }, format: { with: URI::MailTo::EMAIL_REGEXP }

  private

  def one_admin_user_should_exist
    if AdminUser.count == 1
      errors.add(:base, "At least one admin user must exist.")
      throw(:abort)
    end
  end
end
