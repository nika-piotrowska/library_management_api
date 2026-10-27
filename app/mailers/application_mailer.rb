# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base
  default from: 'library@example.com'
  layout 'mailer'
end
