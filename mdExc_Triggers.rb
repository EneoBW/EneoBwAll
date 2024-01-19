#
=begin
    #   All informations for CRV db environment to trigger it
    #   VRP: 1-1-1 <> < 
    #       For each file :
    #       if check file   => store True on auths
    #       if !check file  => store false on auths
    #   Databases :
    #       excInformations     excBugs
=end

module Exc_Triggers
#==================
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
require "#{comm_dir}ClCommon.rb"
    _com            = Common.new(true)
    current_dir     = _com.currentDir()
    exec_dir        = current_dir
    #
require "#{exec_dir}/mdExc_Triggers_excInformations.rb"
require "#{exec_dir}/mdExc_Triggers_excBugs.rb"
require "#{exec_dir}/mdExc_Triggers_excMails.rb"
#
#   Variables
#   +++++++++
    @meonly     = 'N'
    @_debug     = 'x'
    @count      = 0                                                         #count of db

    @arrtables  = []                                                        #dbs name
    @arrids     = []                                                        #dbs ID
    @arrhdrs    = []                                                        #header fields
    @arrflds    = []                                                        #item fields
    @arridpref  = []                                                        #ID prefix
    @arrjobj    = []                                                        #jobjs
    @arrpages   = []                                                        #main page id

    @integr     = 'secret_2XXOYzX5JThHqZviHGZpPna5ihVU2o3knCvrCu76RjS'      #EneoBw : secret_2XXOYzX5JThHqZviHGZpPna5ihVU2o3knCvrCu76RjS

    @arrto      = Hash.new                                                  #recipients
    @arrauths   = Hash.new

    @arrinits   = [
        'INF',      #excInformations
    #    'EVT',      #excEvenements
    #    'DOC',      #Documents
        'MAI',      #excMails
        'BUG'       #excBugs
    ]
#
#   Parameters
#   ++++++++++
=begin
=end
#
#   Functions
#   +++++++++
    #set some values from caller
    def Exc_Triggers.init(p_me='N')
    #++++++++++++++++++++
    #    puts ">>>Prv_Triggers:: Init requested"
        @meonly = p_me
        #
    #    puts "DBG>For:: #{arrinits}"
        @arrinits.each do |pref|    #<L1>
            case pref   #<SW2>
            when    'INF'
                result  = Exc_Triggers_excInformations.load()               #get values for that DB
            when    'EVT'
            when    'DOC'
            when    'BUG'
                result  = Exc_Triggers_excBugs.load()                       #get values for that DB
            when    'MAI'
                result  = Exc_Triggers_excMails.load()                       #get values for that DB
            end #<SW2>

            @arrtables.push(result['table'])                                #
            @arrids.push(result['ids'])                                     #
            @arrhdrs.push(result['hdrs'])                                   #
            @arrflds.push(result['flds'])                                   #
            @arridpref.push(result['idpref'])                               #
            @arrjobj.push(result['jobj'])                                   #
            @arrto.store(result['to'][0],result['to'][1])                   #
            @arrauths.store(result['auths'][0],result['auths'][1])          #
            @arrpages.push(result['page'])                                 #
            @count  += 1                                                    #

            # pp @arrtables
            # pp @arrids
        end #<L1>
        #
        return true
    end#<def>
    #
    #get parameters for all environments
    def Exc_Triggers.getPrms()
    #+++++++++++++++++++++++
        #make array to return
        arrprms    = [@integr,@arrauths,@arrtables,@arrids,@arrhdrs,@arrflds,@arridpref,@arrjobj]
        return  arrprms                #=>[integr,arrauths,arrtables,arrids,arrhdrs,arrflds,arridpref,aeejobj]
    end #<def>
    #
    #checks
    def Exc_Triggers.checks(p_data)
    #+++++++++++++++++++++++[prefix,status]
        prefix      = p_data[0]
        check       = p_data[1]

        case prefix
        when    'INF'
            return  Exc_Triggers_excInformations.checks(check)
        when    'BUG'
            return  Exc_Triggers_excBugs.checks(check)
        when    'MAI'
            return  Exc_Triggers_excMails.checks(check)
        end
        
        return false
    end #<def>
    #
    #send event
    def Exc_Triggers.sndEvents(p_data)  #<=[prefix,[properties]]
    #+++++++++++++++++++++++++
        prefix      = p_data[0]
        recfields   = p_data[1]
        message     = "<h3>Sorry, it's a bug. Do not use it as request</h3>"
        #
    #    event       = "#{recfields[2]}"
    #    fromdate    = recfields[3]
    #    todate      = recfields[4]
    #    puts "iCAL: EVT: #{event} - From: #{fromdate} - To: #{todate}"
    #    system("osascript CreateEventCal.scpt #{fromdate} #{todate} #{event}")
        return true
    end #<def>
    #
    #send emails
    def Exc_Triggers.sndEmails(p_data)  #<=[prefix,[properties],[[type,value],[]...]]
    #+++++++++++++++++++++++++
        #    puts ">>>Prv_Triggers:: SendEmail requested"
        prefix      = p_data[0]
        properties  = p_data[1]
        blocks      = p_data[2]
    #    # pp blocks

        #extract blocks
        content = ""
        blocks.each do |block|  #<L1>
            type    = block[0]
            value   = block[1]
            case    type    #<SW2>
            when    'bulleted_list_item'
                content = content + "⚫️ #{value}</br>"
            when    'divider'
                content = content + "#{value}*****#{value}*****#{value}</br>"
            when    'embed'
                content = content + "Données->URL: #{value}</br>"
            when    'equation'
                content = content + "#{value}</br>"
            when    'file'
                content = content + "Fichier->URL: #{value}</br>"
            when    'heading_1'
                content = content + "<H1>#{value}</H1>"
            when    'heading_2'
                content = content + "<H2>#{value}</H2>"
            when    'heading_3'
                content = content + "<H3>#{value}</H3>"
            when    'image'
                content = content + "Image->URL: #{value}</br>"
            when    'pdf'
                content = content + "Pdf->URL: #{value}</br>"
            when    'quote'
                content = content + "*** #{value} *** </br>"
            when    'table'
            when    'to_do'
                content = content + "🔲 #{value}</br>"
            when    'toggle'
                content = content + "<H4>#{value}</H4>"
            end #<SW2>
        end #<L1>

        #dispatch
        case prefix #<SW1>
        when    'INF'
            #extract fields
            recfields   = [
                Exc_Triggers.extrProperty('None',properties['Last trigger time']),
                Exc_Triggers.extrProperty('None',properties['Last edited time']),
                Exc_Triggers.extrProperty('None',properties['Référence']),
                Exc_Triggers.extrProperty('None',properties['expAuteur']),
                Exc_Triggers.extrProperty('None',properties['expModificateur']),
                Exc_Triggers.extrProperty('None',properties['Texte'])
            ]
            #send mail
            rc  = Exc_Triggers_excInformations.sendEmails(@arrto[prefix],"Exchange-Information générale",recfields,content)

        when    'BUG'
            #extract fields
            recfields   = [
                Exc_Triggers.extrProperty('None',properties['Last trigger time']),
                Exc_Triggers.extrProperty('None',properties['Last edited time']),
                Exc_Triggers.extrProperty('None',properties['Référence']),
                Exc_Triggers.extrProperty('None',properties['Auteur']),
                Exc_Triggers.extrProperty('None',properties['Date limite']),
                Exc_Triggers.extrProperty('None',properties['Fonctions impactées'])
            ]

        when    'MAI'
            #extract fields
            recfields   = [
                Exc_Triggers.extrProperty('None',properties['Last trigger time']),
                Exc_Triggers.extrProperty('None',properties['Last edited time']),
                Exc_Triggers.extrProperty('None',properties['Référence']),
                Exc_Triggers.extrProperty('None',properties['Date']),
                Exc_Triggers.extrProperty('None',properties['Commentaire'])
            ]
            #send mail
            rc  = Exc_Triggers_excMails.sendEmails(@arrto[prefix],"Exchange-eMails",recfields,content)
        end #<SW1>
        
        return true
    end #<def>
    #
    #rewrite values
    def Exc_Triggers.rewValues()
        return true
    end #<def>
    #
    #extract properties
    def Exc_Triggers.extrProperty(p_type='None',p_propitems='None')
    #============================
        #INP: [Fieldname,Fieldproperty]
        #OUT: field content
        # pp p_propitems
        content = 'None'
        data    = p_propitems
        return content              if data.nil? or data.size == 0
        p_type  = data['type']      if p_type == 'None'
        string  = data[p_type]
        return content              if string.nil? or string.size == 0

        case p_type #<SW1>
        when 'checkbox'                         #"checkbox"=>true or false
            content = string

        when 'created_time'                     #"created_time"=>"2023-09-12T10:23:00.000Z"
            content = string

        when 'date'                             #"date"=>{"start"=>"2023-09-14T13:57:00.000+00:00", "end"=>nil, "time_zone"=>nil}
            tstart  = string['start']
            tend    = string['end']
            tzone   = string['time_zone']
            tend    = tstart        if tend.nil?
            tzone   = 'CET'         if tzone.nil?
            content = [tstart,tend,tzone]

        when 'email'                            #"email"=>xyz
            content = string['email']

        when 'files'                            #"files"=>[{"name"=>xyz,"external"=>{"url"=>xyz}}]
            names   = []
            string.each do |file|   #<L2>
                vname   = file['name']
                vextr   = file['external']
                vurl    = vextr['url']
                value   = [vname,vurl]
                names.push(value)
            end #<L2>
            content = names                     #[[f1],[f2],...]
        when 'formula'                          #"formula"=>{"type"=>"boolean", "boolean"=>false}
                                                #"formula"=>{"type"=>"string", "string"=>"EneoBW"}
            type    = string['type']
            content = string[type]

        when 'last_edited_by'                   #"last_edited_by"=>{"object"=>"user", "id"=>"265acec2-56f6-433f-bab3-e63cc2f6fd57"}

        when 'last_edited_time'                 #"last_edited_time"=>"2023-09-23T17:16:00.000Z"}
            content = string

        when 'multi_select'                     #"multi_select"=>{"options"=>[{"name"=>"TypeScript"},{"name"=>"JavaScript"},{"name"=>"Python"}]}
        #    # pp string
            names       = []                    #erase output
            string.each do |option| #<L2>       #loop options
                value   = option['name']        #extract option
                names.push(value)
            end #<L2>
            content = names                     #[opt1,opt2,...]

        when 'number'                           #"number"=>xyz
            content = string

        when 'people'                           #

        when 'phone_number'                     #"phone_number"=>xyz
            content = string

        when 'relation'                         #"relation"=>[{"id"=>"7943da60-2cdd-44e6-bbf0-6ce000a5bf2d"}]
            string  = string[0]
            content = string['id']

        when 'rich_text'                        #"rich_text"=>[{"type"=>"text","text"=>{"content"=>"Pour tests", 
                                                    #"link"=>nil},"annotations"=>{"bold"=>false,"italic"=>false,
                                                    #"strikethrough"=>false,"underline"=>false,"code"=>false,
                                                    #"color"=>"default"},"plain_text"=>"Pour tests","href"=>nil}]
            rich_text   = string[0]
            if rich_text.nil? or rich_text.size==0  #<IF2>
            else    #<IF2>
                type        = rich_text['type']
                text        = rich_text[type]
                content     = text['content']
            end #<IF2>

        when 'select'                           #"select"=>{"name"=>xyz}
            content = string['name']

        when 'status'                           #"status"=>{"id"=>"0071c364-9852-45df-8cc1-cc04662f7c73",
                                                    #"name"=>"Non validé","color"=>"yellow"}
            content = string['name']

        when 'title'                            #"title"=>[{"type"=>"text","text"=>{"content"=>"Ref 1", "link"=>nil},
                                                    #"annotations"=>{"bold"=>false,"italic"=>false,"strikethrough"=>false,
                                                    #"underline"=>false,"code"=>false,"color"=>"default"},
                                                    #"plain_text"=>"Ref 1","href"=>nil}]
            title   = string[0]                 #[type,'type']
            type    = title['type']             #[type,'type']
            text    = title[type]               #[arg,arg...]
            content = text['content']

        when 'unique_id'                        #"unique_id"=>{"prefix"=>"EXC-INF", "number"=>1}
            prefix  = string['prefix']
            number  = string['number']

        when 'URL'                              #"url"=>xyz
            content = string

        else    #<SW1>
        end #<SW1>
        return content
    end #<def>
#
#   Extract block
    def Exc_Triggers.extrBlock(p_type='None',p_blockitems='None')
    #=========================
        #INP:
        #OUT:
        content = []
        data    = p_blockitems
        p_type  = data['type']      if p_type == 'None'
        string  = data[p_type]
        items   = data[p_type]
        case p_type #<SW1>
        when    'divider'
            content = [p_type,"----------"]
        when    'embed'
            content = [p_type,items['url']]
        when    'equation'
            content = [p_type,items['expression']]
        when    'file'
            type    = items['type']
            file    = items[type]
            content = [p_type,file['url']]
        when    'image'
            caption = items['caption']
            type    = items['type']
            image   = items[type]
            content = [p_type,image['url']]
        when    'pdf'
            pdf     = items['pdf']
            type    = pdf['type']
            pdf     = pdf[type]
            content = [p_type,pdf['url']]
        when    'table'
        when    'text'
        when    'heading_1','heading_2','heading_3','paragraph',
                'callout','quote',
                'bulleted_list_item','numbered_list_item',
                'to_do','toggle'
        #    # pp items
            if items.nil?   #<IF2>
            else    #<IF2>
                rich_text   = items['rich_text']            #[]
                if rich_text.nil?   #<IF3>
                else    #<IF3>
                    rich_text   = rich_text[0]              #[type,'type']
                    if rich_text.nil?   #<IF4>
                    else    #<IF4>
                        type        = rich_text['type']     #[type]
                        if type == 'text'   #<IF5>
                            text    = rich_text['text']     #[text]
                            content = [p_type,text['content']]
                        end #<IF5>
                    end #<IF4>
                end #<IF3>
            end #<IF2>
        else    #<SW1>
            puts "Block:: Unknown: #{p_type}"
        end #<SW1
        return content
    end #<def>

end #<MOD>