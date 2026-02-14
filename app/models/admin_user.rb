# == Schema Information
#
# Table name: admin_users
#
#  id         :bigint           not null, primary key
#  email      :string           not null
#  role       :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class AdminUser < ApplicationRecord
  before_destroy :one_admin_user_should_exist

  enum :role, [:admin, :editor], prefix: true, scopes: true

  normalizes :email, with: ->(e) { e.strip.downcase }
  
  validates :email, presence: true, uniqueness: { case_sensitive: false }, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :role, presence: true

  private

  def one_admin_user_should_exist
    if AdminUser.count == 1
      errors.add(:base, I18n.t('admin_user.errors.one_admin_user_must_exist'))
      throw(:abort)
    end
  end
end
