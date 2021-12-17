module Imap; end

module Imap::Backup
  MAJOR    = 4
  MINOR    = 0
  REVISION = 3
  PRE      = nil
  VERSION  = [MAJOR, MINOR, REVISION, PRE].compact.map(&:to_s).join(".")
end
