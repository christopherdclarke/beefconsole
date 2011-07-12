require 'beef/remote'

module BeEF
module Ui
module Console
module CommandDispatcher

class Remote
  include BeEF::Ui::Console::CommandDispatcher
  
  def initialize(driver)
    super
  end
  
  def name
    "Remote Control"
  end
  
  def commands
    {
      "connect"     => "Connect to a remote BeEF instance",
      "status"      => "Check the status of the connection",
      "disconnect"  => "Disconnect from the remote BeEF instance",
      "online"      => "List online hooked browsers",
      "target"      => "Target a particular hooked browser",
      "onlinepoll"        => "Start a background job to poll for online hooked browsers",
    }
  end
  
  def cmd_connect(*args)
    if (args[0] == nil or args[0] == "-h" or args[0] == "--help")
      print_status("  Usage: connect <beef url> <username> <password>")
      print_status("Examples:")
      print_status("  connect http://127.0.0.1:3000 beef beef")
      return
    end
    
    if (driver.remotebeef.session.authenticate(args[0], args[1],args[2]).nil?)
      #For some reason, the first attempt always fails, lets sleep for a couple of secs and try again
      select(nil,nil,nil,2)
      if (driver.remotebeef.session.authenticate(args[0], args[1], args[2]).nil?)
        print_status("Connection failed..")
      else
        print_status("Connected to "+args[0])
      end
    else
      print_status("Connected to "+args[0])
    end
  end
  
  def cmd_status(*args)
    begin
      if driver.remotebeef.session.connected
        print_status("You are connected to "+driver.remotebeef.session.baseuri)
      else
        print_status("You are not connected")
      end
    rescue
      print_status("You are not connected")
    end
  end
  
  def cmd_disconnect(*args)
    begin
      driver.remotebeef.session.disconnect
      print_status("You are now disconnected")
      if (driver.dispatcher_stack.size > 1 and
  	      driver.current_dispatcher.name != 'Core' and
  	      driver.current_dispatcher.name != 'Remote Control')

  	      driver.destack_dispatcher

  	      driver.update_prompt('')
      end
    rescue
      print_status("You weren't even connected in the first place d'uh")
    end
  end
  
  def cmd_online(*args)
    if driver.remotebeef.session.connected.nil?
      print_status("You don't appear to be connected, try \"connect\" first")
      return
    end
    
    hb = driver.remotebeef.zombiepoll.hooked
    hb['hooked-browsers']['online'].each{|x|
      print_status(x[0]+": "+x[1]['browser_icon']+" on "+x[1]['os_icon']+" in the domain: "+x[1]['domain']+" with the ip: "+x[1]['ip'])
    }
  end
  
  def cmd_target(*args)
    if driver.remotebeef.session.connected.nil?
      print_status("You don't appear to be connected, try \"connect\" first")
      return
    end
    
    if (args[0] == nil)
      print_status("  Usage: target <id>")
      return
    end
    
    driver.remotebeef.settarget(args[0])
    
    if (driver.dispatcher_stack.size > 1 and
	      driver.current_dispatcher.name != 'Core' and
	      driver.current_dispatcher.name != 'Remote Control')

	      driver.destack_dispatcher

	      driver.update_prompt('')
    end
    
    driver.enstack_dispatcher(Target)
    
    driver.update_prompt("(%bld%red"+driver.remotebeef.targetip+"%clr) ["+driver.remotebeef.target.to_s+"] ")
    
  end
  
  def cmd_onlinepoll
    driver.remotebeef.jobs.start_bg_job(
      "OnlinePoller",
      driver.output,
      Proc.new { |ctx_| driver.remotebeef.zombiepoll.hookedpoll(ctx_) }
    )
    #driver.remotebeef.zombiepoll.hookedpoll
  end
  
end


end end end end