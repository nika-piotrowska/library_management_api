# frozen_string_literal: true

class CreateBorrowings < ActiveRecord::Migration[8.1]
  def change
    create_table :borrowings do |t|
      t.references :book, null: false, foreign_key: true
      t.references :reader, null: false, foreign_key: true

      t.datetime :borrowed_at, null: false
      t.datetime :due_at, null: false
      t.datetime :returned_at

      t.timestamps
    end

    add_index :borrowings,
              :book_id,
              unique: true,
              where: 'returned_at IS NULL',
              name: 'index_unique_active_borrowing_per_book'

    add_check_constraint :borrowings,
                         'due_at > borrowed_at',
                         name: 'borrowings_due_at_after_borrowed_at'

    add_check_constraint :borrowings,
                         'returned_at IS NULL OR returned_at >= borrowed_at',
                         name: 'borrowings_returned_at_after_borrowed_at'
  end
end
