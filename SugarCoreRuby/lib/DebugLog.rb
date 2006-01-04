require "logger"
module DebugLog

    @@logger = Logger.new(STDERR)
    
    def DebugLog.append_features(includingClass)
        super
        def includingClass.log_level(log_level)
            if @logger
                @logger.level = log_level
            else
                @@logger.level = log_level
            end
        end
        
        def includingClass.global_logger=(new_logger)
            @@logger = new_logger
        end
        
        def includingClass.global_logger
            @@logger
        end
        
        def includingClass.logger=(new_logger)
            @logger = new_logger
        end
        def includingClass.logger
            if ! @logger
                return @@logger
            end
            return @logger
        end
    end
        
    public
    
    def warn(message)
        self.class.logger.error(caller(1)[0] + ' ' + message)
    end
    
    def info(message)
        self.class.logger.info(self.class.name + " : " + message)
    end
    
    def logger=(newlogger)
        @logger = newlogger
    end
    
    def logger()
        @logger
    end

end