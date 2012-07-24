# unicorn_rails -c config/unicorn.rb -E production -D

worker_processes 2
working_directory "."

preload_app true
timeout 180

listen '/srv/csv2onxi.rainbowbooks.com.au/current/tmp/sockets/unicorn.sock', :backlog => 128
pid '/srv/csv2onix.rainbowbooks.com.au/current/tmp/pids/unicorn.pid'
stderr_path "/srv/csv2onix.rainbowbooks.com.au/current/log/unicorn.stderr.log"
stdout_path "/srv/csv2onix.rainbowbooks.com.au/current/log/unicorn.stdout.log"

before_fork do |server, worker|
  begin
    old_pid = File.read("#{server.pid}.oldbin").to_i
    STDERR.puts "[worker #{worker.nr}] sending SIGQUIT to #{old_pid}"
    Process.kill("QUIT", old_pid)
  rescue Errno::ENOENT
    STDERR.puts "[worker #{worker.nr}] no old master running."
  rescue Errno::ESRCH
    STDERR.puts "[worker #{worker.nr}] #{old_pid} was already gone."
  end
end

# save the worker pids to disk so we can monitor them
after_fork do |server, worker|
  worker_pid = "/srv/csv2onix.rainbowbooks.com.au/current/tmp/pids/unicorn.#{worker.nr}.pid"
  system("echo #{Process.pid} > #{worker_pid}")

  ActiveRecord::Base.establish_connection
end
