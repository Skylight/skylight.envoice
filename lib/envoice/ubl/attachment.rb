# frozen_string_literal: true

module Envoice
  module Ubl
    class Attachment

      attr_reader :filename, :id, :description, :mime_type, :contents, :document_type_code

      def initialize(filename:, id:, description:, mime_type:, contents:, document_type_code: nil)
        @filename = filename
        @id = id
        @description = description
        @mime_type = mime_type
        @contents = contents
        @document_type_code = document_type_code
      end

    end
  end
end