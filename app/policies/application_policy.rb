# frozen_string_literal: true

class ApplicationPolicy
  attr_reader :user, :role, :record

  def initialize(context, record)
    @user = context[:user]
    @role = context[:role]
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
    @role == 'admin'
  end

  def editor_user?
    return false unless user
    @role == 'editor'
  end

  class Scope
    def initialize(context, scope)
      @user = context[:user]
      @role = context[:role]
      @scope = scope
    end

    def resolve
      raise NoMethodError, "You must define #resolve in #{self.class}"
    end

    private

    attr_reader :user, :scope
  end
end
