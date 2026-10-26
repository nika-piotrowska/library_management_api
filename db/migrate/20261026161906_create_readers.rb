# frozen_string_literal: true

class CreateReaders < ActiveRecord::Migration[8.1]
  def change
    create_table :readers do |t|
      t.string :library_card_number, null: false
      t.string :full_name, null: false
      t.string :email, null: false

      t.timestamps
    end

    add_index :readers, :library_card_number, unique: true
    add_index :readers, 'LOWER(email)',
              unique: true,
              name: 'index_readers_on_lower_email'

    add_check_constraint :readers,
                         "library_card_number ~ '^[0-9]{6}$'",
                         name: 'readers_library_card_number_format'
  end
end
