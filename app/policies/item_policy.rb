# frozen_string_literal: true

class ItemPolicy  < ApplicationPolicy
  attr_reader :user, :record

  def index?
    authenticated?
  end

  def show?
    authenticated?
  end

  def create?
    admin_user?
  end

  def new?
    create?
  end

  def update?
    admin_user?
  end

  def edit?
    update?
  end

  def destroy?
    admin_user?
  end

  def upload_files_page?
    admin_user?
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
