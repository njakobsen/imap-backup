require "json"

module Imap::Backup
  class Serializer::Imap
    CURRENT_VERSION = 3

    attr_reader :folder_path
    attr_reader :loaded

    def initialize(folder_path)
      @folder_path = folder_path
      @loaded = false
      @uid_validity = nil
      @messages = nil
      @version = nil
    end

    def pathname
      "#{folder_path}.imap"
    end

    def exist?
      File.exist?(pathname)
    end

    def valid?
      return false if !exist?
      return false if version != CURRENT_VERSION
      return false if !uid_validity

      true
    end

    def append(uid, length, flags = [])
      offset =
        if messages.empty?
          0
        else
          last_message = messages[-1]
          last_message.offset + last_message.length
        end

      messages << Serializer::Message.new(
        uid: uid, offset: offset, length: length, mbox: mbox, flags: flags
      )

      save
    end

    def get(uid)
      messages.find { |m| m.uid == uid }
    end

    def delete
      return if !exist?

      File.unlink(pathname)
      @loaded = false
      @messages = nil
      @uid_validity = nil
      @version = nil
    end

    def rename(new_path)
      if exist?
        old_pathname = pathname
        @folder_path = new_path
        File.rename(old_pathname, pathname)
      else
        @folder_path = new_path
      end
    end

    def uid_validity
      ensure_loaded
      @uid_validity
    end

    def uid_validity=(value)
      ensure_loaded
      @uid_validity = value
      save
    end

    # Make private
    def messages
      ensure_loaded
      @messages
    end

    # Deprecated
    def uids
      messages.map(&:uid)
    end

    def update_uid(old, new)
      index = messages.find_index { |m| m.uid == old }
      return if index.nil?

      messages[index].uid = new
      save
    end

    def version
      ensure_loaded
      @version
    end

    def save
      ensure_loaded

      raise "Cannot save metadata without a uid_validity" if !uid_validity

      data = {
        version: @version,
        uid_validity: @uid_validity,
        messages: @messages.map(&:to_h)
      }
      content = data.to_json
      File.open(pathname, "w") { |f| f.write content }
    end

    private

    def ensure_loaded
      return if loaded

      data = load
      if data
        @messages = data[:messages].map { |m| Serializer::Message.new(mbox: mbox, **m) }
        @uid_validity = data[:uid_validity]
        @version = data[:version]
      else
        @messages = []
        @uid_validity = nil
        @version = CURRENT_VERSION
      end
      @loaded = true
    end

    def load
      return nil if !exist?

      data = nil
      begin
        content = File.read(pathname)
        data = JSON.parse(content, symbolize_names: true)
      rescue JSON::ParserError
        return nil
      end

      return nil if !data.key?(:version)
      return nil if !data.key?(:uid_validity)
      return nil if !data.key?(:messages)
      return nil if !data[:messages].is_a?(Array)

      data
    end

    def mbox
      @mbox ||= Serializer::Mbox.new(folder_path)
    end
  end
end
