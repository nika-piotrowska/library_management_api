# frozen_string_literal: true

class AddReminderTimestampsToBorrowings < ActiveRecord::Migration[8.1]
  def change
    change_table :borrowings, bulk: true do |table|
      table.datetime :before_due_reminder_sent_at
      table.datetime :due_reminder_sent_at
    end
  end
end
