# frozen_string_literal: true

require_relative "envoice/country_code"
require_relative "envoice/ubl"
require_relative "envoice/version"

module Envoice
  class Error < StandardError; end
end
