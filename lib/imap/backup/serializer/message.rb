require "email/mboxrd/message"

module Imap::Backup
  class Serializer::Message
    attr_accessor :uid
    attr_accessor :flags
    attr_reader :offset
    attr_reader :length
    attr_reader :mbox

    # TODO: delegate to Mboxrd::Message

    def initialize(uid:, offset:, length:, mbox:, flags: [])
      @uid = uid
      @offset = offset
      @length = length
      @mbox = mbox
      @flags = flags.map(&:to_sym)
    end

    def to_h
      {
        uid: uid,
        offset: offset,
        length: length,
        flags: flags.map(&:to_s)
      }
    end

    def message
      @message =
        begin
          raw = mbox.read(offset, length)
          Email::Mboxrd::Message.from_serialized(raw)
        end
    end

    def body
      @body ||= message.supplied_body
    end

    def imap_body
      @imap_body ||= message.imap_body
    end

    def date
      @date ||= message.date
    end

    def subject
      @subject ||= message.subject
    end
  end
end
