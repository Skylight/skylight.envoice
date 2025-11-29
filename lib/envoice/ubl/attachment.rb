# frozen_string_literal: true

module Envoice
  module Ubl
    class Attachment

      attr_reader :absolute_file_name, :id, :description, :mime_type

      def initialize(absolute_file_name:, id:, description:, mime_type:)
        raise "File does not exist: #{absolute_file_name}" unless File.exist?(absolute_file_name)

        @absolute_file_name = absolute_file_name
        @id = id
        @description = description
        @mime_type = mime_type
      end
      
    end
  end
end