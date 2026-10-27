# frozen_string_literal: true

class BorrowingRemindersJob < ApplicationJob
  queue_as :default

  def perform
    send_before_due_reminders
    send_due_reminders
  end

  private

  def send_before_due_reminders
    send_reminders(
      Date.current + 3.days,
      :before_due_reminder_sent_at,
      :before_due_reminder
    )
  end

  def send_due_reminders
    send_reminders(
      Date.current,
      :due_reminder_sent_at,
      :due_reminder
    )
  end

  def send_reminders(date, timestamp_attribute, mailer_action)
    Borrowing.active
             .where(due_at: date.all_day)
             .where(timestamp_attribute => nil)
             .find_each do |borrowing|
      deliver_reminder(borrowing, timestamp_attribute, mailer_action)
    end
  end

  def deliver_reminder(borrowing, timestamp_attribute, mailer_action)
    borrowing.with_lock do
      next unless borrowing.active?
      next if borrowing.public_send(timestamp_attribute).present?

      BorrowingMailer.public_send(
        mailer_action,
        borrowing
      ).deliver_now

      borrowing.update!(timestamp_attribute => Time.current)
    end
  end
end
