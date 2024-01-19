#
=begin
#   EneoBwAll_main
#   ++++++++++++++
#   Build : 1-1-1 <240102-1800>
#       start all triggers function
#       Parameters:
#           P1: loop max
#           P2: timeout between scripts
#           P3: 
#           P4: 
# 
#   Graph:
#       EnenBwExc_Main
#           EneoBwExc_Triggers
#               MdExc_Triggers
#                   MdExc_Triggers_excFILE
=end
#
require 'rubygems'
require 'timeout'
require 'net/http'
require 'net/smtp'
require 'uri'
require 'json'
require 'csv'
require 'pp'
#
comm_dir    = '~/pCloudSync/Prod/PartCommon/'
prod_dir    = '~/pCloudSync/Prod/PartB/'
parta_dir   = '~/pCloudSync/Dvlps/StandardsV2/'
partb_dir   = '~/pCloudSync/Dvlps/MembersV2-1/'
#
require "#{comm_dir}ClCommon.rb"
    _com    = Common.new(true)
    current_dir = _com.currentDir()
    exec_dir    = current_dir
#
#   Internal functions
#   ******************
#
#
#   External modules
#   ****************
#   ClCommon
#
#   Initialize
#   **********
#   get input parameters
    begin
        _loop   = ARGV[0]
        _loop   = _loop.to_i
        _tmo    = ARGV[1]
        _tmo    = _tmo.to_i
    rescue
        _loop   = 1
        _tmo    = 5
    end
    _loop   = 1     if _loop.nil?
    _tmo    = 10    if _tmo.nil? or _tmo < 10
#
#   Variables
#   *********
#
    program     = 'EneoBwALL_main'

    mainloop    = 1
    timeout     = _tmo * 12
    
    arrprogs    = ['*',
            'EneoBwTrg_Triggers',
            'MyTrg_Triggers',
            'EneoBwExc_Triggers'
        ]

#
#   Main code
#   *********
#
    #Init
    _com.start(program," Timeout:#{_tmo} - Loops:#{_loop}")
    
    #main loop
    repeat      = 'Y'
    while repeat == 'Y' #<L1>
        #EneoBwTrg_Triggers     => DEM, CNV
        progx   = "ruby #{parta_dir}/#{arrprogs[1]}.rb A 5 N 5"
        _com.execProg("#{progx}")
        #
        #EneoBwExc_Triggers     => INF, DOC, EVT
        progx   = "ruby #{partb_dir}/#{arrprogs[3]}.rb A 5 N 5"
        _com.execProg("#{progx}")
        #
        #MyTrg_Triggers         => CAL
        progx   = "ruby #{parta_dir}/#{arrprogs[2]}.rb A 5 N 5"
        _com.execProg("#{progx}")
        #
        mainloop    += 1
        #check current time
        t           = Time.now
        month       = t.month
        day         = t.day
        hour        = t.hour.to_i
        if hour < 8                     #too early
            diff    = (8 - hour) * 360  #diff secs
            _com.step("I am sleeping for #{diff} secs")
            sleep(diff)                 #wait
        end
        if hour > 19                    #to late
            repeat  = 'N'
            break                       #exit loop
        end
        #
        #sleep or exit ?
        if mainloop > _loop #<IF2>
            print ">>>Do you want to close the script or sleep for #{timeout} secs : "
            begin
                status = Timeout::timeout(timeout) { answer = $stdin.gets.chomp.downcase until answer == 'y' }
                repeat  = "N"
            rescue Timeout::Error
                _com.step(">>>One more time again")
            end
        else
            sleep(_tmo)
            mainloop    = 1
        end #<IF2>
    end #<L1>
    _time2  = Time.new.inspect
    _com.stop("End of #{program}")
#<>
