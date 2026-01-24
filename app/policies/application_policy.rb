# frozen_string_literal: true

class ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  def index?
    false
  end

  def show?
    false
  end

  def create?
    false
  end

  def new?
    create?
  end

  def update?
    false
  end

  def edit?
    update?
  end

  def destroy?
    false
  end

  private
  
  def authenticated?
    user.present?
  end

  def admin_user?
    return false unless user
    email = user.email_address
    cache_key = "admin_user_status:#{email}"
    Rails.cache.fetch(cache_key, expires_in: 1.hour) do
      Rails.logger.debug "********************************** policy: checking admin user status for #{email}"
      AdminUser.exists?(email: email)
    end
  end

  class Scope
    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      raise NoMethodError, "You must define #resolve in #{self.class}"
    end

    private

    attr_reader :user, :scope
  end
end
