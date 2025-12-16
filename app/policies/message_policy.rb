class MessagePolicy < ApplicationPolicy
  def create?
    return false unless user && record.conversation

    record.conversation.participant?(user)
  end
end
