# frozen_string_literal: true

module Api
  module V1
    class BaseController < ApplicationController
      before_action :validate_json_api_headers
      before_action :validate_json_api_document, if: :body_request?

      rescue_from ActiveRecord::RecordNotFound,
                  with: :render_not_found

      rescue_from ActionController::ParameterMissing,
                  with: :render_bad_request

      rescue_from ActionController::BadRequest,
                  with: :render_bad_request

      rescue_from Borrowings::Error, with: :render_business_error

      private

      def render_resource(resource, serializer:, status: :ok, options: {})
        render json: serializer.new(resource, options).serializable_hash,
               status: status,
               content_type: 'application/vnd.api+json'
      end

      def render_errors(messages, status: :unprocessable_entity)
        errors = Array(messages).map do |message|
          {
            status: Rack::Utils.status_code(status).to_s,
            title: 'Request failed',
            detail: message
          }
        end

        render json: { errors: errors },
               status: status,
               content_type: 'application/vnd.api+json'
      end

      def resource_attributes(expected_type)
        data = json_api_params[:data]

        unless data[:type] == expected_type
          raise ActionController::BadRequest,
                "Expected resource type '#{expected_type}'"
        end

        attributes = data[:attributes]

        raise ActionController::BadRequest, 'Missing attributes' unless attributes.is_a?(Hash)

        ActionController::Parameters.new(attributes)
      end

      def validate_json_api_headers
        if request.get_header('CONTENT_TYPE').present? &&
           request.media_type != 'application/vnd.api+json'
          return render_errors('Unsupported Content-Type', status: :unsupported_media_type)
        end

        return if request.headers['Accept'].blank?

        accepted = request.headers['Accept'].split(',').any? do |value|
          value.strip.start_with?('application/vnd.api+json', '*/*')
        end

        render_errors('Unsupported Accept header', status: :not_acceptable) unless accepted
      end

      def validate_json_api_document
        return if json_api_params[:data].is_a?(Hash)

        render_errors('Expected a JSON:API data object', status: :bad_request)
      end

      def json_api_params
        @json_api_params ||= begin
          body = JSON.parse(request.raw_post)

          raise ActionController::BadRequest, 'Expected a JSON object' unless body.is_a?(Hash)

          body.with_indifferent_access
        end
      rescue JSON::ParserError
        raise ActionController::BadRequest, 'Invalid JSON body'
      end

      def body_request?
        request.patch? || (request.post? && action_name != 'return_book')
      end

      def render_not_found(exception)
        render_errors(exception.message, status: :not_found)
      end

      def render_bad_request(exception)
        render_errors(exception.message, status: :bad_request)
      end

      def render_business_error(exception)
        render_errors exception.message, status: :conflict
      end
    end
  end
end
