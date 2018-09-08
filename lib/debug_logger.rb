
require 'logger'
require 'colorize'

module DebugLogger
    @@logger = Logger.new(STDERR)
    @@logger.level = Logger::DEBUG
end