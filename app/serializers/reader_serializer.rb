# frozen_string_literal: true

class ReaderSerializer
  include JSONAPI::Serializer

  set_type :readers

  attributes :library_card_number, :full_name, :email
end
