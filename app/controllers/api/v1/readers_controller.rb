# frozen_string_literal: true

module Api
  module V1
    class ReadersController < BaseController
      def show
        reader = Reader.find(params.expect(:id))

        render_resource reader, serializer: ReaderSerializer
      end

      def create
        reader = Reader.new(reader_params)

        if reader.save
          render_resource reader,
                          serializer: ReaderSerializer,
                          status: :created
        else
          render_errors reader.errors.full_messages
        end
      end

      private

      def reader_params
        resource_attributes('readers').permit(
          :full_name,
          :email
        )
      end
    end
  end
end
