require "thread"
# @api private
class OpenEndedQueue < Queue
  def unshift(obj)
    t = nil
    @mutex.synchronize{
      @que.unshift obj
      begin
        t = @waiting.shift
        t.wakeup if t
      rescue ThreadError
        retry
      end
    }
    begin
      t.run if t
    rescue ThreadError
    end
  end
end
