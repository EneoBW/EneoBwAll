#
=begin
    # =>    EneoBwExc_Triggers
    # =>    VRP: 2-3-5 <
    # =>    Function : check all EXC dbs to trigger if new item
    # =>        & send email if new
    # =>    Parameters :
    #           P1: x -> no debug, X -> debug
    #           P2: timeout or date to check
    #           P3: Me only or All
    #           P4: how many days ago 
    # =>    Flow :
=end
require 'rubygems'
require 'timeout'
require 'net/http'
require 'net/smtp'
require 'uri'
require 'json'
require 'csv'
require 'pp'
#
require 'notion-ruby-client'
#
comm_dir    = '~/pCloudSync/Prod/PartCommon/'
require "#{comm_dir}ClCommon.rb"
_com = Common.new(false)
        current_dir     = _com.currentDir()
        exec_dir        = current_dir
require "#{exec_dir}/mdExc_Triggers.rb"
#
#   Common Init
#   ===========
    _dbgmsg = "DBG>>"
    _com.debug("**********************************************************")
    _com.debug("Start of Script -> Check of new/upd items & send a trigger")
    _com.debug("Parameters: 120 < timeout < 120 - yyyy-mm-ddThh:mm:ss")
    _com.debug("Parameters: Q=questions about flags, X=debug ON")
    rc  = _com.start('EneoBwExc_Triggers','#')
    if rc
    else
        _com.stop()
    end
#
#   Parameters
#   ==========
    begin
        _debug  = ARGV[0]
        _date   = ARGV[1]
        _meonly = ARGV[2]
        _days   = ARGV[3]
    rescue
        _debug   = 'X'
        _date   = ""
        _meonly = 'N'
        _days   = 10
    end
#
#   commands to test
#   ================
#   end of test
    exit 101    if _debug == 'Z'
    if _debug == "Q" or _debug == 'X'    #<IF1>
        print ">>>Do you want to send event to iCal ? "
        _ical   = $stdin.gets.chomp
        _ical   = _ical.upcase
        print ">>>Do you want to send email to members ? "
        _email  = $stdin.gets.chomp
        _email  = _email.upcase
        print ">>>Do you want to update the Trigger field ? "
        _update = $stdin.gets.chomp
        _update = _update.upcase
        print ">>>Do you want to send emails only to Me ? "
        _meonly = $stdin.gets.chomp
        _meonly = _meonly.upcase
    elsif _debug == 'A'     #one time in auto mode
        _ical   = "Y"
        _email  = "Y"
        _update = "Y"
        _meonly = 'N'
    else
        _ical   = "N"
        _email  = "N"
        _update = "N"
        _meonly = 'Y'
    end #<IF1>
#
#   Variables
#   =========
    arrhdrs     = ['id','last_edited_time','created_time']                  #header fields to extract
    arrflds     = []                                                        #fields to extract by default

    arrtables   = []                                                        #names of DB
    arrids      = []                                                        #ID of DB
    arridpref   = []                                                        #prefix of ID field
    arrjobj     = []                                                        #json obj to filter
    arrnot      = []                                                        #Notion instances
    arrauths    = Hash.new                                                  #authorizations

    deftimeout  = 120                                                       #120secs or 2mins
    program     = 'EneoBwExc_Triggers'

    #
    #Init
    #====
    # => make json body
    if _date.size < 9  #<IF1>
        ago     = _days.to_i * 86400
        t       = Time.new - ago                                            #x days ago
        ymd     = t.strftime("%Y-%m-%d")
        fdate   = "#{ymd}T00:00:00"
    else    #<IF1>
        if _date.include?('T')  #<IF2>
            fdate   = _date
        end #<IF2>
    end #<IF1>
    jobj    = {
        "and" => [
                {"property" => "Last edited time","last_edited_time" => {"on_or_after" => "#{fdate}"}}
            ]
        }
    #
    sort    = [
        {'property'=> 'Référence', 'direction'=> 'descending'}
    ]
    #
    # => make timeout
    if _date.size < 6   #<IF1>
        timeout  = _date.to_i                                               #convert to integer
        timeout  = deftimeout   if timeout > deftimeout                     #set new timeout
    else
        timeout = deftimeout                                                #default
    end #<IF1>
    newtimeout  = timeout                                                   #save for loop

    _com.debug("**************************************************")
    _com.debug("Prms::Test: #{_debug} / #{_ical} / #{_email} / #{_update}-Filter on: #{fdate} with: #{timeout} secs")
    exit 103    if _debug == 'x'
    _com.debug("1:: Make environments")
    _com.debug("**************************************************")

#
#   Make environment
#   ================
    Exc_Triggers.init(_meonly)

    arrprms     = Exc_Triggers.getPrms()   #get all params => [@integr,@arrauths,@arrtables,@arrids,@arrhdrs,@arrflds,@arridpref]
    _com.debug   "Environment1:: #{arrprms}"                                 if _debug == "X"
    integr      = arrprms[0]                                                #extract secret
    arrauths    = arrprms[1]                                                #extract auth of db
    arrtables   = arrprms[2]                                                #extract all tablenames
    arrids      = arrprms[3]                                                #extract all tableids
    arrflds     = arrprms[5]                                                #extract all fields
    arridpref   = arrprms[6]                                                #extract all prefix
    arrjobj     = arrprms[7]                                                #extract all objs
    arrpages    = arrprms[8]                                                #extract all main pages
    checkrec    = arrflds.last()
    _com.debug   "Environment2:: #{arrtables} - #{arrauths}"                 if _debug == "X"
#
# => ruby Notion_ckient class Init
#   ==============================
    _com.debug("**************************************************")
    _com.debug("2:: Get Notion instances-")
    index   = 0

    Notion.configure do |config|
        config.token = integr
    end

    arrtables.each do |db|  #<L1>
        table       = arrtables[index]                                      #get table name
        id          = arrids[index]                                         #get table ID
        fields      = arrflds[index]                                        #get fields to retrieve
        notprms     = [integr,table,fields,arrhdrs,id,_debug]               #make params
        _com.debug   "Inst:: #{index} - #{notprms}"                          if _debug == "X"
        notinst     = Notion::Client.new
        arrnot.push(notinst)                                                #save instance
        index       += 1                                                    #next db
    end #<L1>
    _com.debug   "Inst:: All - #{arrnot}"                                    if _debug == "X"
    #
# => Main loop
#   ==========
#
#   loop on time
#   ++++++++++++ 8 < T < 19
    nbrloop     = 0
    flagloop    = true
    while flagloop  #<L0>
        #   loop on dbs
        #   +++++++++++
        timeout = newtimeout                                                #restore
        nbrloop += 1        
        index   = 0
        arrnot.each do |inst|    #<L1>Loop for each Notion instance

            #check table name
            table       = arrtables[index]                              #extract table name
            database_id = arrids[index]                                 #extract db ID
            #check auth
            prefix      = arridpref[index]                              #get prefix
            auth        = arrauths[prefix]                              #get authorization
            auth        = true                  #for tests
            if auth == true     #<IF2>
                #read 1st record
                _com.debug(" ")
                _com.debug("**************************************************")
                _com.debug("3:: Main loop-#{arrtables[index]}")
                _com.step("3A:: Prefix: #{prefix} - Auth: #{auth}")

                inst.database_query(database_id: database_id, filter: jobj, sorts: sort) do |block| #<L3>
                    object  = block['object']
                    results = block['results']
            
                    results.each do |page|  #<L4>
                        _com.debug("3B:: record extracted:: #{page}")     if _debug == "X"
                        pageid      = page['id']
                        properties  = page['properties']

                        #extract data
                        #    pp properties
                        reference   = Exc_Triggers.extrProperty('None',properties['Référence'])
                        etat        = Exc_Triggers.extrProperty('None',properties['Etat'])
                        prms        = [
                                    prefix,
                                    etat
                            ]

                        if Exc_Triggers.checks(prms)   #<IF5>
                            edited_time     = Exc_Triggers.extrProperty('None',properties['Last edited time'])
                            triggered_time  = Exc_Triggers.extrProperty('None',properties['Last trigger time'])
                            trigger_time    = Exc_Triggers.extrProperty('None',properties['Trigger time'])

                            _com.debug("3C:: Old values:: REF: #{reference} - UPD: #{edited_time} - TRG: #{triggered_time}")   #if _debug == "X"
                            #
                            flagupd = false

                            #check if first time
                            if triggered_time.nil? or triggered_time.size < 5   #<IF6>
                                trigger_time    = edited_time
                                triggered_time  = edited_time
                                _com.debug("3D:: First time => New Trigger_time: #{trigger_time}")   #if _debug == "X"
                                flagupd = true
                            else    #<IF6>
                                _com.debug("3E:: First time => NO")                                   if _debug == "X"
                            end #<IF6>

                            #check with previous max - trg & upd
                            if edited_time > triggered_time || flagupd == true  #<IF6>
                                trigger_time    = edited_time
                                _com.debug("3F:: New values:: REF:#{reference} OLD:#{triggered_time} NEW:#{trigger_time}")   #if _debug == "X" || _update == 'Y'
                                flagupd = true

                                arrprms = []
                                blocks  = []
                                #process about prefix
                                case prefix  #<SW7>
                                when    'abc'  #<SW7>
                                    arrprms = [arridpref[index],properties]          #make params
                                    #send event to iCal
                                    rc      = Exc_Triggers.sndEvents(arrprms)       if _ical == 'Y'     #send event
                                    _com.step("4A:: Sent event for: REF -> #{reference}")
                                    flagupd = true
                                else    #<SW7>
                                    #get blocks
                                    inst.block_children(block_id: pageid) do |page| #<L8>
                                        results = page['results']
                                        results.each do |block| #<L9>
                                            #    pp  block
                                            value   = Exc_Triggers.extrBlock('None',block)
                                        #    puts "Block:: Type: #{value[0]} Value: #{value[1]}"
                                            blocks.push([value[0],value[1]])
                                        end #<L9>
                                    end #<L8>
                                    arrprms = [arridpref[index],properties,blocks]          #make params
                                    #send email
                                    rc      = Exc_Triggers.sndEmails(arrprms)       if _email == 'Y'     #send email
                                    _com.step("4B:: Sent email for: REF -> #{reference}")
                                    flagupd = true
                                end #<SW7>
                            else    #<IF6>
                                _com.debug("4C:: Check values:: REF:#{reference} UPD:#{edited_time} TRG:#{trigger_time}")   if _debug == "X"
                            end #<IF6>

                            #upd triggered_time
                            if flagupd && _update == 'Y'    #<IF6>
                                trigger_time    = edited_time
                                trgobj          = {"Trigger time" => {"date" => {"start" => trigger_time}}}
                                rc  = inst.update_page(page_id:pageid, properties:trgobj)
                                _com.step("5:: Update Trigger time for #{trigger_time}")
                            end #<IF6>

                        end #<IF5>
                    end #<L4>
                end #<L3>
                #
                #
            else    #<IF2>
                _com.debug("3G:: Prefix: #{prefix} - no Auth: #{auth}")
            end #<IF2>
            index   += 1                                                    #next Notion instance
        end #<L1>

        #check time to start or done
        currtime    =Time.now                                               #get current time
        currhour    =currtime.hour                                          #extract hour
        if currhour > 19    #<IF1>                                          #if too late
            flagloop    = false
            timeout     = 60    #60'' - 1'
        else    #<IF1>
            while currhour < 8  #<L2>                                       #loop if too early
                xtimeout = 600           #600'' - 10 '
                xtimemin = xtimeout/60   #10'
                _com.debug("#{currtime} -> too early, go to sleep for #{xtimeout} secs or #{xtimemin} mins")
                sleep xtimeout           #600''
                currtime    =Time.now                                       #get current time
                currhour    =currtime.hour                                  #extract hour
            end #<L2>
        end #<IF1>
        if timeout > 60  #<IF1>
            _com.debug(" ")
            _com.debug("**************************************************")
            #stop or sleep ?
            timemin = timeout/60
            _com.debug("#{currtime} -> Loop: #{nbrloop} ->go to sleep for #{timeout} secs or #{timemin} mins")
            print '>>>Do you want to stop ? '
            begin
                status = Timeout::timeout(timeout) { answer = $stdin.gets.chomp.downcase until answer == 'y' }
                flagloop    = false
                timeout     = 60    #60''
            rescue Timeout::Error
                print '>>>One more time again'
                puts ">>>"
            end
        else    #<IF1>
            flagloop    = false
        end #<IF1>
    end #<L0>
    #
    _com.stop("End of #{program}")
#