require "paperclip/attachment"
require "paperclip/interpolations"
require "paperclip/options"
require "paperclip/processor"
require "paperclip/storage"
require "paperclip/storage/filesystem"
require "paperclip/uploaded_file"
require "paperclip/validations"

module Paperclip
  VERSION = "3.0.0"

  class PaperclipError < StandardError; end
  class InfiniteInterpolationError < PaperclipError; end
  class InvalidOptionError < PaperclipError; end
  class StorageBackendNotFound < PaperclipError; end

  def self.included(base)
    File.send(:include, UploadedFile)
    StringIO.send(:include, UploadedFile)
  end

  def has_attached_file(name, options = {})
    include InstanceMethods
    self.class.class_eval do
      attr_accessor :paperclip_definitions
    end

    self.paperclip_definitions ||= {}
    self.paperclip_definitions[name] = Options.new(options)

    define_method(name) do
      attachment_for(name)
    end

    define_method("#{name}=") do |file|
      attachment_for(name).assign(file)
    end

    after_save     :flush_attachments
    before_destroy :clear_attachment
    after_destroy  :flush_attachments
  end

  module InstanceMethods
    def clear_attachment
      self.class.paperclip_definitions.keys.each do |name|
        attachment_for(name).clear
      end
    end

    def flush_attachments
      self.class.paperclip_definitions.keys.each do |name|
        attachment_for(name).save
      end
    end

    def attachment_for(name)
      @attachment ||= Attachment.new(name, self, attachment_options(name))
    end

    def attachment_options(name)
      self.class.paperclip_definitions[name]
    end
  end
end
