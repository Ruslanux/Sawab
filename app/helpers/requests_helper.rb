module RequestsHelper
  def request_status_badge_class(status)
    case status
    when "open"
      "bg-green-100 dark:bg-green-900/30 text-green-800 dark:text-green-300"
    when "in_progress"
      "bg-blue-100 dark:bg-blue-900/30 text-blue-800 dark:text-blue-300"
    when "pending_completion"
      "bg-yellow-100 dark:bg-yellow-900/30 text-yellow-800 dark:text-yellow-300"
    when "disputed"
      "bg-orange-100 dark:bg-orange-900/30 text-orange-800 dark:text-orange-300"
    when "completed"
      "bg-gray-100 dark:bg-gray-700 text-gray-800 dark:text-gray-300"
    when "cancelled"
      "bg-red-100 dark:bg-red-900/30 text-red-800 dark:text-red-300"
    else
      "bg-gray-100 dark:bg-gray-700 text-gray-800 dark:text-gray-300"
    end
  end

  def offer_status_badge_class(status)
    case status
    when "pending"
      "bg-yellow-100 dark:bg-yellow-900/30 text-yellow-800 dark:text-yellow-300"
    when "accepted"
      "bg-green-100 dark:bg-green-900/30 text-green-800 dark:text-green-300"
    when "rejected"
      "bg-red-100 dark:bg-red-900/30 text-red-800 dark:text-red-300"
    else
      "bg-gray-100 dark:bg-gray-700 text-gray-800 dark:text-gray-300"
    end
  end
end
