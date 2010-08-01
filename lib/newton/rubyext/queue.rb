require "thread"
class Queue
  def unshift(obj)
    Thread.critical = true
    @que.unshift obj
    begin
      t = @waiting.shift
      t.wakeup if t
    rescue ThreadError
      retry
    ensure
      Thread.critical = false
    end
    begin
      t.run if t
    rescue ThreadError
    end
  end
end
